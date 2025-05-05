`include "mipi_csi_data_types.svh"
interface dphy_rx_model
    #(  parameter MIPI_GEAR = 16, 
        parameter MIPI_LANES = 4,
        parameter WIDTH = 512,
        parameter LENGTH = 512,
        parameter INPUT = "IMG", //IMG or LINE or BLANK
        parameter DATATYPE = "RAW8" // RAW8 or RAW8
    );
    logic clk_i;
    // PPI interface
    logic err_sot_hs_o;
    logic err_sot_sync_hs_o;

    logic rx_byte_clk_hs_o;
    logic rx_valid_hs_o [MIPI_LANES];
    logic [(MIPI_GEAR-1):0] rx_data_hs_o [MIPI_LANES];
    
    
    parameter SYNC_BYTE= 8'hB8;
    
    //? 1- Attach sync code to the start of each packet
    //? 2- Send frame and line short packets
    //? 3- Between line short packets send the line data long packet
    //? 4- Attach data identifier(virtual channel and data type) word count and ECC to each of the packet headers
    //? 5- Attach Checksum to each of the packet footer(checksum generator with a correct and uncorrect functionality)
    //? 6- Add a variable packet spacing
    //? 7- Order the bytes by the lanes which lane will have the first byte
    assign rx_byte_clk_hs_o = clk_i;
    // reset outputs
    task reset_outputs();
        int i;
        err_sot_hs_o=0;
        err_sot_sync_hs_o=0;
        for(i=0; i<MIPI_LANES; i++) begin
            rx_valid_hs_o[i]=0;
            rx_data_hs_o[i]=0;
        end
    endtask
    // send a frame task
    task send_frame(input logic [15:0] frame_num_i, input logic [1:0] vc_id_i, integer read_file_i);
        int i;
        // send frame start short packet
        send_short_packet({vc_id_i, `FSC}, 0);

        // send embedded
        //send_line(line_num+1, vc_id_i, read_file_i);
        // send userdefined
        for(i=0; i<10; i++)
            send_line(0,1, vc_id_i, read_file_i);

        for(int line_num=0; line_num<LENGTH; line_num++) begin
            send_line(line_num+1, 0, vc_id_i, read_file_i);
        end

        // send frame end short packet
        send_short_packet({vc_id_i, `FEC}, 0);
    endtask

    // send a line task
    task send_line(input logic[15:0] line_num_i,input logic userdefined, input logic [1:0] vc_id_i, integer read_file_i);
        logic [(WIDTH*8)-1:0] img_line8; //image line for RAW8 datatype image
        automatic logic [(WIDTH*10)-1:0] img_line10=0; // image line for RAW10 datatype image
        logic [15:0] crc_calc;
        int i;
        // send line start short packet
        //send_short_packet({vc_id_i, `LSC}, line_num_i);
        if(userdefined) begin
            for(i=0; i<(WIDTH/4); i++) begin
                if(line_num_i==2)
                    img_line8[i*32 +: 32] = 32'h00ff00ff;
                else
                    img_line8[i*32 +: 32] = 32'd0;
            end
        end
        else if(INPUT=="IMG")
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

        // send packet header which has sync byte and line valid
        if(userdefined)
            send_packet_header({vc_id_i, 6'h37}, 16'(WIDTH+(WIDTH/4)));
        else if(DATATYPE=="RAW8")
            send_packet_header({vc_id_i, `RAW8}, 16'(WIDTH));
        else if(DATATYPE=="RAW10")
            send_packet_header({vc_id_i, `RAW10}, 16'(WIDTH+(WIDTH/4)));
        

        // seed the crc
        calculate_crc(0, 1, crc_calc);

        // send data and calculate CRC
        if(DATATYPE=="RAW8") begin
            for(i=$size(img_line8)-1; signed'(i)>0; i=i-32) begin //RAW10
                rx_data_hs_o[3] = img_line8[i-7 +: 8];
                rx_data_hs_o[2] = img_line8[i-15 +: 8];
                rx_data_hs_o[1] = img_line8[i-23 +: 8];
                rx_data_hs_o[0] = img_line8[i-31 +: 8];
                calculate_crc(rx_data_hs_o[3], 0, crc_calc);
                calculate_crc(rx_data_hs_o[2], 0, crc_calc);
                calculate_crc(rx_data_hs_o[1], 0, crc_calc);
                calculate_crc(rx_data_hs_o[0], 0, crc_calc);
                clock();
            end
        end
        else if(DATATYPE=="RAW10") begin
            for(i=$size(img_line10)-1; signed'(i)>0; i=i-32) begin //RAW10
                rx_data_hs_o[3] = img_line10[i-7 +: 8];
                rx_data_hs_o[2] = img_line10[i-15 +: 8];
                rx_data_hs_o[1] = img_line10[i-23 +: 8];
                rx_data_hs_o[0] = img_line10[i-31 +: 8];
                calculate_crc(rx_data_hs_o[3], 0, crc_calc);
                calculate_crc(rx_data_hs_o[2], 0, crc_calc);
                calculate_crc(rx_data_hs_o[1], 0, crc_calc);
                calculate_crc(rx_data_hs_o[0], 0, crc_calc);
                clock();
            end
        end
        
        // send CRC
        //rx_data_hs_o[3] = crc_calc[7:0];
        //rx_data_hs_o[2] = crc_calc[15:8];
        //rx_valid_hs_o[1] = 0;
        //rx_valid_hs_o[0] = 0;
        //clock();
        //rx_valid_hs_o[3] = 0;
        //rx_valid_hs_o[2] = 0;
        //clock();
        // weird data at the end should be ignored
        for(i=0; i<20; i++) begin
            rx_data_hs_o[3] = 8'hff;
            rx_data_hs_o[2] = 8'hff;
            rx_data_hs_o[1] = 8'hff;
            rx_data_hs_o[0] = 8'hff;
            clock();
        end
        rx_valid_hs_o[3] = 0;
        rx_valid_hs_o[2] = 0;
        rx_valid_hs_o[1] = 0;
        rx_valid_hs_o[0] = 0;
        // wait for some cycles in the middle
        for(i=0; i<100; i++)
            clock();

        // send line end short packet
        //send_short_packet({vc_id_i, `LEC}, line_num_i);
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
    
    task clock();
        if(clk_i)
            wait(!clk_i);
        wait(clk_i);
    endtask

    // send short packet
    task send_short_packet(logic [7:0] data_id, logic [15:0] word_count);
        logic [7:0] ecc;
        // send SOT sequence on all lanes
        rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        //rx_data_hs_o[3] = SYNC_BYTE;
        //rx_data_hs_o[2] = SYNC_BYTE;
        //rx_data_hs_o[1] = SYNC_BYTE;
        //rx_data_hs_o[0] = SYNC_BYTE;
        //clock();

        // send short packet
        calculate_ecc(data_id, word_count, ecc);
        rx_data_hs_o[3] = data_id;
        rx_data_hs_o[2] = word_count[7:0];
        rx_data_hs_o[1] = word_count[15:8];
        rx_data_hs_o[0] = ecc;
        clock();
        calculate_ecc(8'hff, 16'hffff, ecc);
        rx_data_hs_o[3] = 8'hff;
        rx_data_hs_o[2] = 8'hff;
        rx_data_hs_o[1] = 8'hff;
        rx_data_hs_o[0] = ecc;
        clock();
        calculate_ecc(8'hff, 16'hffff, ecc);
        rx_data_hs_o[3] = 8'hff;
        rx_data_hs_o[2] = 8'hff;
        rx_data_hs_o[1] = 8'hff;
        rx_data_hs_o[0] = ecc;
        clock();
        calculate_ecc(8'hff, 16'hffff, ecc);
        rx_data_hs_o[3] = 8'hff;
        rx_data_hs_o[2] = 8'hff;
        rx_data_hs_o[1] = 8'hff;
        rx_data_hs_o[0] = ecc;
        clock();
        rx_valid_hs_o[3] = 0;
        rx_valid_hs_o[2] = 0;
        rx_valid_hs_o[1] = 0;
        rx_valid_hs_o[0] = 0;
        

        // wait for some cycles
        clock();
        clock();
        clock();
        clock();
        clock();
    endtask

    // send header
    task send_packet_header(logic [7:0] data_id, logic [15:0] word_count);
        logic [7:0] ecc;
        // send SOT sequence on all lanes
        rx_valid_hs_o[3] = 1;
        rx_valid_hs_o[2] = 1;
        rx_valid_hs_o[1] = 1;
        rx_valid_hs_o[0] = 1;
        //rx_data_hs_o[3] = SYNC_BYTE;
        //rx_data_hs_o[2] = SYNC_BYTE;
        //rx_data_hs_o[1] = SYNC_BYTE;
        //rx_data_hs_o[0] = SYNC_BYTE;
        //clock();

        // send short packet
        calculate_ecc(data_id, word_count, ecc);
        rx_data_hs_o[3] = data_id;
        rx_data_hs_o[2] = word_count[7:0];
        rx_data_hs_o[1] = word_count[15:8];
        rx_data_hs_o[0] = ecc;
        clock();
    endtask
endinterface
