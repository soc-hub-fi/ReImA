`include "mipi_csi_data_types.svh"
class Packet;
    rand bit [15:0] wc;

    //constraint wc_limit {wc<=16'd5; }
endclass

interface if_csi_dphy_rx_model
    #(  parameter CLOCK_PERIOD=40ns,
        parameter MIPI_GEAR = 16, 
        parameter MIPI_LANES = 4,
        parameter WIDTH = 512,
        parameter LENGTH = 512,
        parameter INPUT = "IMG", //IMG or LINE or BLANK
        parameter DATATYPE = "RAW8" // RAW8 or RAW8
    );
    // PPI interface
    logic err_sot_hs_o;
    logic err_sot_sync_hs_o;

    logic rx_byte_clk_hs_o;
    logic rx_valid_hs_o [MIPI_LANES];
    logic [(MIPI_GEAR-1):0] rx_data_hs_o [MIPI_LANES];
    
    
    parameter SYNC_BYTE= 8'hB8;
    int counter;
    int bytes;
    logic [15:0] crc_calc;
    int img_ptr;
    int read_file_i;
    //? 1- Attach sync code to the start of each packet
    //? 2- Send frame and line short packets
    //? 3- Between line short packets send the line data long packet
    //? 4- Attach data identifier(virtual channel and data type) word count and ECC to each of the packet headers
    //? 5- Attach Checksum to each of the packet footer(checksum generator with a correct and uncorrect functionality)
    //? 6- Add a variable packet spacing
    //? 7- Order the bytes by the lanes which lane will have the first byte
    task gen_clock();
        rx_byte_clk_hs_o = 0;
        #(CLOCK_PERIOD/2)
        rx_byte_clk_hs_o = 1;
        #(CLOCK_PERIOD/2)
        rx_byte_clk_hs_o = 0;
    endtask

    //assign rx_byte_clk_hs_o = clk_i;
    // reset outputs
    task reset_outputs();
        int i;
        rx_byte_clk_hs_o=0;
        err_sot_hs_o=0;
        err_sot_sync_hs_o=0;
        for(i=0; i<MIPI_LANES; i++) begin
            rx_valid_hs_o[i]=0;
            rx_data_hs_o[i]=0;
        end
    endtask

    // send a frame task
    task send_frame(input logic [15:0] frame_num_i, input logic [1:0] vc_id_i);
        Packet pkt;
        pkt = new();
        // send frame start short packet
        send_short_packet({vc_id_i, `FSC}, frame_num_i);
        //TODO: RANDOM WAIT HERE
        wait_clock(500);
        for(int line_num=0; line_num<LENGTH; line_num++) begin
            send_line(pkt, line_num+1, vc_id_i);
        end
        //TODO: RANDOM WAIT HERE
        wait_clock(500);
        // send frame end short packet
        send_short_packet({vc_id_i, `FEC}, frame_num_i);
    endtask

    task read_img_line(logic[15:0] line_num_i, output logic [(WIDTH*8)-1:0] img_line8, output logic [(WIDTH*10)-1:0] img_line10);
        int i;
        if(INPUT=="IMG")
            $fread(img_line8, read_file_i);
        else if(INPUT=="LINE") begin
            for(i=0; i<(WIDTH/4); i++) begin
                if(line_num_i==2)
                    img_line8[i*32 +: 32] = 32'h00ff00ff;
                else
                    img_line8[i*32 +: 32] = 32'd0;
            end
        end
        else if(INPUT=="BLANK") begin
            for(i=0; i<(WIDTH/4); i++) begin
                if(!(line_num_i%2))
                    img_line8[i*32 +: 32] = 32'h00ff00ff;
                else
                    img_line8[i*32 +: 32] = 32'd0;
            end
        end
        // insert image data into the RAW10 line
        for(i=0; i<(WIDTH/4); i++) begin
            if(INPUT=="IMG")
                img_line10[i*40 +: 40] = {img_line8[i*32 +: 32], 8'd0};
            else if(INPUT=="LINE") begin
                if(line_num_i==2)
                    img_line10[i*40 +: 40] = {32'h00ff00ff, 8'd0};
                else
                    img_line10[i*40 +: 40] = {32'd0, 8'd0};
            end
            else if(INPUT=="BLANK") begin
                if(!(line_num_i%2))
                    img_line10[i*40 +: 40] = {32'h00ff00ff, 8'd0};
                else
                    img_line10[i*40 +: 40] = {32'd0, 8'd0};
            end
        end
    endtask

    task line_send_data(int index, logic [15:0] word_count, logic [(WIDTH*8)-1:0] img_line8, logic [(WIDTH*10)-1:0] img_line10);
        if(counter < word_count) begin
            bytes++;
            if(DATATYPE=="RAW8")
                rx_data_hs_o[index] = img_line8[img_ptr-(31-index*8) +: 8];
            else if(DATATYPE=="RAW10")
                rx_data_hs_o[index] = img_line10[img_ptr-(31-index*8) +: 8];
            rx_valid_hs_o[index] = 1;
            calculate_crc(rx_data_hs_o[index], 0, crc_calc);
        end
        else if(counter == word_count) begin
            rx_data_hs_o[index] = crc_calc[7:0];
            rx_valid_hs_o[index] = 1;
        end
        else if(counter == word_count+1) begin
            rx_data_hs_o[index] = crc_calc[15:8];
            rx_valid_hs_o[index] = 1;
        end
        else begin
            rx_data_hs_o[index] = 0;
            rx_valid_hs_o[index] = 0;
        end
        
        counter++;
    endtask

    task send_long_packet(logic [1:0] vc_id_i, logic [15:0] word_count, logic [(WIDTH*8)-1:0] img_line8, logic [(WIDTH*10)-1:0] img_line10);
        int i;
        int numofcycles;
        counter = 0;
        // seed the crc
        calculate_crc(0, 1, crc_calc);
        // send packet header which has sync byte and line valid
        if(DATATYPE=="RAW8")
            send_packet_header({vc_id_i, `RAW8}, word_count);
        else if(DATATYPE=="RAW10")
            send_packet_header({vc_id_i, `RAW10}, word_count);
        // send data and calculate CRC
        //if(signed'(img_ptr)>0) begin //RAW8
        //$display("numberofcycles=%d", $ceil((real'(word_count)+2)/4));
        for(i=0; i<$ceil((real'(word_count)+2)/4); i++) begin
            bytes = 0;
            line_send_data(3, word_count, img_line8, img_line10);
            line_send_data(2, word_count, img_line8, img_line10);
            line_send_data(1, word_count, img_line8, img_line10);
            line_send_data(0, word_count, img_line8, img_line10);
            gen_clock();
            img_ptr=img_ptr-bytes*8;
        end
        //end
        // disable for 1 clock cycle
        rx_valid_hs_o[3] = 0;
        rx_valid_hs_o[2] = 0;
        rx_valid_hs_o[1] = 0;
        rx_valid_hs_o[0] = 0;
        wait_clock(1);
    endtask

    // send a line task
    task send_line(Packet pkt, input logic[15:0] line_num_i, input logic [1:0] vc_id_i);
        logic [(WIDTH*8)-1:0] img_line8; //image line for RAW8 datatype image
        automatic logic [(WIDTH*10)-1:0] img_line10=0; // image line for RAW10 datatype image
        int max_word_count;
        int word_count_incr;
        logic [15:0] word_count;
        word_count_incr = 0;
        //Packet pkt = new();
        // Read image line 
        read_img_line(line_num_i, img_line8, img_line10);
        if(DATATYPE=="RAW8")
            img_ptr = $size(img_line8)-1;
        else if(DATATYPE=="RAW10")
            img_ptr = $size(img_line10)-1;

        max_word_count = (img_ptr+1)/8;
        // Send line start short packet
        send_short_packet({vc_id_i, `LSC}, line_num_i);

        // Wait for some cycles in the middle
        wait_clock(6);
        while(word_count_incr < max_word_count) begin
            if(DATATYPE=="RAW8")
                pkt.randomize() with {1 <= wc && wc <= max_word_count-word_count_incr;};
            else if(DATATYPE=="RAW10")
                pkt.randomize() with {5 <= wc && wc <= max_word_count-word_count_incr; wc%5==0;};
            word_count = pkt.wc;
            send_long_packet(vc_id_i, word_count, img_line8, img_line10);
            word_count_incr += word_count;
        end

        // send line end short packet
        send_short_packet({vc_id_i, `LEC}, line_num_i);
    endtask

    // calculate CRC task
    task calculate_crc(input logic [7:0] byte_i, input logic assign_seed_i, output logic [15:0] crc_o);
        if(assign_seed_i)
            crc_o = 16'hffff;
        else begin
            for(int i=0; i<8; i++) begin //! is byte order alright?
                crc_o       = {crc_o[0], crc_o[15:1]};
                crc_o[15]   = byte_i[i] ^ crc_o[0];
                crc_o[10]   = crc_o[11] ^ byte_i[i] ^ crc_o[0];
                crc_o[3]    = crc_o[4] ^ byte_i[i] ^ crc_o[0];
            end
        end
    endtask

    // calculate ECC task
    task calculate_ecc(input logic [7:0] data_id, input logic [15:0] word_count, output logic [7:0] calculated_ecc);
        logic [23:0] D;
                    // <WCount MSB>        <WCount LSB>            <DataID>
        assign D = {word_count[15:8], word_count[7:0], data_id}; // reformat the header according to specs
        calculated_ecc[0] = D[0]^D[1]^D[2]^D[4]^D[5]^D[7]^D[10]^D[11]^D[13]^D[16]^D[20]^D[21]^D[22]^D[23];
        calculated_ecc[1] = D[0]^D[1]^D[3]^D[4]^D[6]^D[8]^D[10]^D[12]^D[14]^D[17]^D[20]^D[21]^D[22]^D[23];
        calculated_ecc[2] = D[0]^D[2]^D[3]^D[5]^D[6]^D[9]^D[11]^D[12]^D[15]^D[18]^D[20]^D[21]^D[22];
        calculated_ecc[3] = D[1]^D[2]^D[3]^D[7]^D[8]^D[9]^D[13]^D[14]^D[15]^D[19]^D[20]^D[21]^D[23];
        calculated_ecc[4] = D[4]^D[5]^D[6]^D[7]^D[8]^D[9]^D[16]^D[17]^D[18]^D[19]^D[20]^D[22]^D[23];
        calculated_ecc[5] = D[10]^D[11]^D[12]^D[13]^D[14]^D[15]^D[16]^D[17]^D[18]^D[19]^D[21]^D[22]^D[23];
        calculated_ecc[6] = 1'b0;
        calculated_ecc[7] = 1'b0;
    endtask
    
    task wait_clock(int n);
        #(CLOCK_PERIOD*n);
    endtask

    // send short packet
    task send_short_packet(logic [7:0] data_id, logic [15:0] word_count);
        logic [7:0] ecc;
        // send SOT sequence on all lanes
        /*rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        rx_data_hs_o[3] = SYNC_BYTE;
        rx_data_hs_o[2] = SYNC_BYTE;
        rx_data_hs_o[1] = SYNC_BYTE;
        rx_data_hs_o[0] = SYNC_BYTE;
        gen_clock();*/

        // send short packet
        rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        calculate_ecc(data_id, word_count, ecc);
        rx_data_hs_o[3] = data_id;
        rx_data_hs_o[2] = word_count[7:0];
        rx_data_hs_o[1] = word_count[15:8];
        rx_data_hs_o[0] = ecc;
        gen_clock();
        rx_valid_hs_o[3] = 0;
        rx_valid_hs_o[2] = 0;
        rx_valid_hs_o[1] = 0;
        rx_valid_hs_o[0] = 0;

        // wait for some cycles
        wait_clock(5);
    endtask

    // send header
    task send_packet_header(logic [7:0] data_id, logic [15:0] word_count);
        logic [7:0] ecc;
        // send SOT sequence on all lanes
        /*rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        rx_data_hs_o[3] = SYNC_BYTE;
        rx_data_hs_o[2] = SYNC_BYTE;
        rx_data_hs_o[1] = SYNC_BYTE;
        rx_data_hs_o[0] = SYNC_BYTE;
        gen_clock();*/

        // send short packet
        rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        calculate_ecc(data_id, word_count, ecc);
        rx_data_hs_o[3] = data_id;
        rx_data_hs_o[2] = word_count[7:0];
        rx_data_hs_o[1] = word_count[15:8];
        rx_data_hs_o[0] = ecc;
        gen_clock();
    endtask
endinterface