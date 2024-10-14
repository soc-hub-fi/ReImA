/*
    File: flow_control.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References:

    Functionality:
    
    -   Programmable module to control the number of pixels per clock sent to the ISP modules
    -   Support YUV422_8, RGB888, RGB565, RAW8, RAW10 datatypes
    -   Includes an Async FIFO to separate the byte clock domain and the pixel clock domain
    -   Can accomudate throtteling on the AXI pixel out interface using pixel_stream_stall_i signal
    -   pixel_clk_i needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
    -   byte_clk_i is usually 1/8 of the line rate coming from the DPHY

    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
`include "mipi_csi_data_types.svh"
module flow_control(
                    input                   byte_reset_n_i,             // Active low reset for the byte clock domain
                    input                   byte_clk_i,                 // Byte clock usually 1/8 of the line rate coming from the DPHY
                    input                   pixel_reset_n_i,            // Active low reset for the pixel clock domain
                    input                   pixel_clk_i,                // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
                    input           [2:0]   pixel_per_clk_i,            // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
                    input                   stream_stall_i,             // If high data is pushed to the line buffer without being read
                    input           [5:0]   data_type_i,                // Video data type such as RGB, RAW..etc
                    input                   line_valid_i,               // line valid in from short packet decoding
                    input                   frame_valid_i,              // frame valid in from short packet decoding
                    input                   line_valid_sync_fake_i,
                    input           [47:0]  byte_data_i,                // Max width is 2 RGB888 pixels 2*24 = 48
                    input           [3:0]   byte_data_valid_i,          // Pixel data valid signal for each pixel in the pixel data
                   
                    output  logic           dst_clear_pending_o,        // Clear pending signal for the CDC FIFO
                    output  logic           src_clear_pending_o,        // Clear pending signal for the CDC FIFO
                    output  logic           line_done_pulse_o,
                    output  logic           line_valid_sync_o,          // line valid signal synchronized with the output data because of buffering delay
                    output  logic           frame_valid_sync_o,         // frame valid signal synchronized with the output data because of the buffering delay
                    output  logic   [95:0]  pixel_data_o,               // Depending on the datatype some of the bits might not be used. Maximum Width(RGB888) = (8+8+8) * 4 = 96,
                    output  logic   [3:0]   pixel_data_valid_o,         // Each bit corresponds to a pixel in the pixel_data_o port
                    output  logic   [11:0]  byte_valid_o                // providing byte valid for felxibility
    );

    parameter YUV422_WIDTH = 16;
    parameter RGB888_WIDTH = 24;
    parameter RGB565_WIDTH = 16;
    parameter RAW8_WIDTH = 8;
    parameter RAW10_WIDTH = 10;

    logic pipe_extract;
    logic pipe_insert;
    logic [4:0] pixel_counter;
    logic [3:0] num_of_valids;
    logic [191:0] pixel_data;
    logic [3:0] pixel_data_valid;
    logic line_valid_negedge;
    logic line_valid_posedge;
    logic line_valid_reg;
    logic frame_valid_negedge;
    logic frame_valid_posedge;
    logic frame_valid_reg;
    logic byte_data_valid_negedge;
    logic line_valid_sync_fake_reg;
    logic line_code_operative;
    logic line_done_pulse;
    logic line_done_latch;
    logic [51:0] fifo_wrdata;
    logic fifo_wincr;
    logic throttle_ram_wincr;
    logic throttle_ram_rincr;
    logic throttle_ram_full;
    logic throttle_ram_empty;
    logic [11:0] byte_valid_yuv422;
    logic [11:0] byte_valid_rgb888;
    logic [11:0] byte_valid_rgb565;
    logic [11:0] byte_valid_raw8;
    logic [11:0] byte_valid_raw10;
    logic [4*YUV422_WIDTH-1:0] yuv422_pipe;
    logic [4*RGB888_WIDTH-1:0] rgb888_pipe;
    logic [4*RGB565_WIDTH-1:0] rgb565_pipe;
    logic [4*RAW8_WIDTH-1:0]  raw8_pipe;
    logic [4*RAW10_WIDTH-1:0] raw10_pipe;
    logic line_buff_wready;
    logic fifo_rvalid;
    logic [11:0] throttle_ram_wraddr;
    logic [11:0] throttle_ram_rdaddr;
    logic [51:0] throttle_ram_data;
    logic [51:0] fifo_data;
    logic ram_valid;
    logic line_valid_sync_r;
    logic line_done_pulse_r;
    logic line_done_pulse_r2;
    typedef enum logic [2:0] {FRAME_VALID, LINE_VALID, LINE_INVALID, FRAME_INVALID} sync_state_type;
    sync_state_type sync_state;
    logic [31:0] debug_counter;
    always_ff@(posedge byte_clk_i or negedge byte_reset_n_i) begin
        if(!byte_reset_n_i)
            debug_counter <= 0;
        else begin
            if(!frame_valid_i)
                debug_counter <= 0;
            else if(|byte_data_valid_i)
                debug_counter <= debug_counter + 1;
        end
    end

    assign pixel_data[191:48] = 0;

    // Line_valid and frame_valid signals encoding logic 
    // A line valid negedge is encoded as zero valids in the line buffer and a line valid posedge is encoded as 4 valids
    // A frame valid negedge is encoded as zero valids in the line buffer and a frame valid posedge is encoded as 4 valids
    assign line_valid_negedge = !line_valid_i & line_valid_reg;
    assign line_valid_posedge = line_valid_i & !line_valid_reg;
    assign frame_valid_negedge = !frame_valid_i & frame_valid_reg;
    assign frame_valid_posedge = frame_valid_i & !frame_valid_reg;
    assign byte_data_valid_negedge = !line_valid_sync_fake_i & line_valid_sync_fake_reg;

    always_ff@(posedge byte_clk_i or negedge byte_reset_n_i) begin
        if(!byte_reset_n_i) begin
            line_valid_reg <= 0;
            frame_valid_reg <= 0;
            line_valid_sync_fake_reg <= 0;
            line_code_operative <= 0;
        end
        else begin
            if(line_valid_posedge)
                line_code_operative <= 1;
            line_valid_sync_fake_reg <= line_valid_sync_fake_i;
            line_valid_reg <= line_valid_i;
            frame_valid_reg <= frame_valid_i;
        end
    end

    assign fifo_wrdata = (frame_valid_posedge || line_valid_posedge)? 52'h0000_0000_0000_f:(frame_valid_negedge || line_valid_negedge || byte_data_valid_negedge)? 52'h0000_0000_0000_0: {byte_data_i, byte_data_valid_i};
    assign fifo_wincr = frame_valid_posedge | frame_valid_negedge | line_valid_posedge | line_valid_negedge | byte_data_valid_negedge | (|byte_data_valid_i);
    //! We need some calculations for the fifo depth here
    (*KEEP_HIERARCHY="TRUE"*)
    (*DONT_TOUCH="TRUE"*)
    cdc_fifo_gray_clearable #(
        /// The width of the default logic type.
        .WIDTH                  (   52                  ),
        /// The FIFO's depth given as 2**LOG_DEPTH.
        .LOG_DEPTH              (   4                   ),
        .SYNC_STAGES            (   4                   ),
        .CLEAR_ON_ASYNC_RESET   (   1                   )
    )
    cdc_fifo_i
    (
        .src_rst_ni             (   byte_reset_n_i      ),
        .src_clk_i              (   byte_clk_i          ),
        .src_clear_i            (   1'b0                ),  // use reset for clear
        .src_clear_pending_o    (   src_clear_pending_o ),  //! send to status register
        .src_data_i             (   fifo_wrdata         ),
        .src_valid_i            (   fifo_wincr          ),
        .src_ready_o            (                       ),  // not throttle_ram_full

        .dst_rst_ni             (   pixel_reset_n_i     ),
        .dst_clk_i              (   pixel_clk_i         ),
        .dst_clear_i            (   1'b0                ),  // use reset for clear
        .dst_clear_pending_o    (   dst_clear_pending_o ),
        .dst_data_o             (   fifo_data           ),  // 52 bits
        .dst_valid_o            (   fifo_rvalid         ),  // not empty
        .dst_ready_i            (   !throttle_ram_full  )   // Always ready to accept data
    );

    // write logic and write address logic should be controlled by the throttle_ram_rincr signal
    always_ff@(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
        if(!pixel_reset_n_i) begin
            throttle_ram_wraddr <= 0;
            throttle_ram_rdaddr <= 0;
            throttle_ram_full <= 0; 
        end
        else begin
            throttle_ram_full <= (throttle_ram_wraddr-throttle_ram_rdaddr) >= 12'hFFE; //! Added here for timing req !Make sure it works
            if(fifo_rvalid && !throttle_ram_full) begin
                throttle_ram_wraddr <= throttle_ram_wraddr + 1;
            end
            if(throttle_ram_rincr) begin
                throttle_ram_rdaddr <= throttle_ram_rdaddr + 1;
            end
        end
    end

    assign throttle_ram_rincr = (!stream_stall_i) & (!throttle_ram_empty) & !pipe_insert; //! probably a bug here in this part (pixel_counter < pixel_per_clk_i) add !pipe_instert to wait for pixel_counter update
    assign throttle_ram_wincr = !throttle_ram_full & fifo_rvalid;
    //TRIAL Add a dual port RAM here and lower the size of the cdc fifo
    dual_port_ram_wrapper#( .ADDR_WIDTH             (   12                                      ),
                            .DATA_WIDTH             (   52                                      ),
                            .MEM_NUM                (   1                                       )  // number of memories
                        )
        throttle_ram_i
                        (
                            .reset_n_i              (   pixel_reset_n_i                         ),
                            .clk_i                  (   pixel_clk_i                             ),
                            .ram_write_enable_i     (   throttle_ram_wincr                      ),
                            .ram_read_enable_i      (   throttle_ram_rincr                      ),
                            .ram_write_address_i    (   throttle_ram_wraddr                     ),
                            .ram_data_i             (   fifo_data                               ),
                            .ram_read_address_i     (   throttle_ram_rdaddr                     ),
                            .ram_data_o             (   throttle_ram_data                       )
                    );
    assign {pixel_data[47:0], pixel_data_valid} = throttle_ram_data;
    assign throttle_ram_empty = throttle_ram_wraddr == throttle_ram_rdaddr;
    
    // To control the number of pixels per clock output there is a small pipe for each datatype to simplify this 2d problem
    // to keep track of the number of pixels and serialize the pixels

    // Pixle counter tracks the number of pixels available in the pipe
    always_ff@(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
        if(!pixel_reset_n_i) begin
            pixel_counter <= 0;
        end
        else begin
            // Pixel counter logic takes 1 cycle
            if(pipe_insert && pipe_extract)
                pixel_counter <= num_of_valids + pixel_counter - pixel_per_clk_i;
            else if(pipe_insert)
                pixel_counter <= num_of_valids + pixel_counter;
            else if(pipe_extract)
                pixel_counter <= pixel_counter - pixel_per_clk_i;
        end
    end

    assign num_of_valids = pixel_data_valid[3] + pixel_data_valid[2] + pixel_data_valid[1] + pixel_data_valid[0];
    assign pipe_extract = (!stream_stall_i) & (pixel_counter >= pixel_per_clk_i); //Add  stall here
    //assign pipe_insert = (!stream_stall_i) & ((ram_valid & (sync_state==LINE_VALID) & line_code_operative) | (~line_code_operative & ram_valid & sync_state==FRAME_VALID & pixel_data_valid!=4'h0));
    assign pipe_insert = (!stream_stall_i) & (ram_valid & sync_state==FRAME_VALID & pixel_data_valid!=4'h0);
    always_ff@(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
        if(!pixel_reset_n_i) begin
            frame_valid_sync_o <= 0;
            sync_state <= FRAME_INVALID;
            ram_valid <= 0;
            line_valid_sync_r <= 0;
            line_done_latch <= 0;
        end
        else begin
            if(throttle_ram_rincr)
                ram_valid <= 1;
            else if(!stream_stall_i)
                ram_valid <= 0;

            if(line_done_pulse)
                line_done_latch <= 1;
            else if(ram_valid && pixel_data_valid==4'hf)
                line_done_latch <= 0;
            //if(!stream_stall_i) begin
                case(sync_state)
                FRAME_INVALID: begin
                    frame_valid_sync_o <= 0;
                    if(ram_valid && (pixel_data_valid==4'hf))
                        sync_state <= FRAME_VALID;
                    
                end
                FRAME_VALID: begin
                    frame_valid_sync_o <= 1;
                    if(ram_valid && (pixel_data_valid==4'hf) && 0)
                        sync_state <= LINE_VALID;
                    else if(ram_valid && (pixel_data_valid==4'h0) && line_done_latch && !stream_stall_i)
                        sync_state <= FRAME_INVALID;
                end
                LINE_VALID: begin
                    line_valid_sync_r <= 1;
                    if(ram_valid && (pixel_data_valid==4'h0))
                        sync_state <= LINE_INVALID;
                end
                LINE_INVALID: begin
                    line_valid_sync_r <= 0;
                    if(ram_valid && (pixel_data_valid==4'hf))
                        sync_state <= LINE_VALID;
                    else if(ram_valid && (pixel_data_valid==4'h0))
                        sync_state <= FRAME_INVALID;
                end
                endcase
            //end
        end
    end
    //assign line_done_pulse = !line_done_latch & ram_valid & (pixel_data_valid==4'h0) & !line_code_operative & sync_state==FRAME_VALID;
    assign line_done_pulse = !line_done_latch & ram_valid & (pixel_data_valid==4'h0) & sync_state==FRAME_VALID &!stream_stall_i;
    // fill the pipe when inserted signal is high and empty it when extract is high
    always_ff@(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
        if(!pixel_reset_n_i) begin
            yuv422_pipe <=0;
            rgb888_pipe <=0;
            rgb565_pipe <=0;
            raw8_pipe   <=0;
            raw10_pipe  <=0;
        end
        else begin
            if(pipe_insert) begin
                for(int i=0; i<4; i++) begin
                    if(pixel_data_valid[i]) begin
                        yuv422_pipe [(i+pixel_counter)*YUV422_WIDTH  +: YUV422_WIDTH]    <= pixel_data[i*YUV422_WIDTH +: YUV422_WIDTH];
                        rgb888_pipe [(i+pixel_counter)*RGB888_WIDTH  +: RGB888_WIDTH]    <= pixel_data[i*RGB888_WIDTH +: RGB888_WIDTH];
                        rgb565_pipe [(i+pixel_counter)*RGB565_WIDTH  +: RGB565_WIDTH]    <= pixel_data[i*RGB565_WIDTH +: RGB565_WIDTH];
                        raw8_pipe   [(i+pixel_counter)*RAW8_WIDTH    +: RAW8_WIDTH]      <= pixel_data[i*RAW8_WIDTH   +: RAW8_WIDTH];
                        raw10_pipe  [(i+pixel_counter)*RAW10_WIDTH   +: RAW10_WIDTH]     <= pixel_data[i*RAW10_WIDTH  +: RAW10_WIDTH];
                    end
                end
            end
            else if(pipe_extract) begin
                yuv422_pipe <=  yuv422_pipe >>  ({6'd0, pixel_per_clk_i}*YUV422_WIDTH);
                rgb888_pipe <=  rgb888_pipe >>  ({6'd0, pixel_per_clk_i}*RGB888_WIDTH);
                rgb565_pipe <=  rgb565_pipe >>  ({6'd0, pixel_per_clk_i}*RGB565_WIDTH);
                raw8_pipe   <=  raw8_pipe   >>  ({6'd0, pixel_per_clk_i}*RAW8_WIDTH);
                raw10_pipe  <=  raw10_pipe  >>  ({6'd0, pixel_per_clk_i}*RAW10_WIDTH);
            end
        end
    end

    //assign pixel_data_valid_o = pipe_extract? ((pixel_per_clk_i==4)? 4'b1111: (pixel_per_clk_i==2)? 4'b0011: (pixel_per_clk_i==1)? 4'b0001: 4'b0000): 4'b0000;
    assign byte_valid_yuv422 = pipe_extract? ((pixel_per_clk_i==4)? 12'b0000_1111_1111: (pixel_per_clk_i==2)? 12'b0000_0000_1111: (pixel_per_clk_i==1)? 12'b0000_0000_0011: 12'b0000_0000_0000): 12'b0000_0000_0000;
    assign byte_valid_rgb888 = pipe_extract? ((pixel_per_clk_i==4)? 12'b1111_1111_1111: (pixel_per_clk_i==2)? 12'b0000_0011_1111: (pixel_per_clk_i==1)? 12'b0000_0000_0111: 12'b0000_0000_0000): 12'b0000_0000_0000;
    assign byte_valid_rgb565 = pipe_extract? ((pixel_per_clk_i==4)? 12'b0000_1111_1111: (pixel_per_clk_i==2)? 12'b0000_0000_1111: (pixel_per_clk_i==1)? 12'b0000_0000_0011: 12'b0000_0000_0000): 12'b0000_0000_0000;
    assign byte_valid_raw8 =   pipe_extract? ((pixel_per_clk_i==4)? 12'b0000_0000_1111: (pixel_per_clk_i==2)? 12'b0000_0000_0011: (pixel_per_clk_i==1)? 12'b0000_0000_0001: 12'b0000_0000_0000): 12'b0000_0000_0000;
    assign byte_valid_raw10 =  pipe_extract? ((pixel_per_clk_i==4)? 12'b0000_0000_1111: (pixel_per_clk_i==2)? 12'b0000_0000_0011: (pixel_per_clk_i==1)? 12'b0000_0000_0001: 12'b0000_0000_0000): 12'b0000_0000_0000;
    //assign byte_valid_o = (data_type_i==`YUV422_8)? byte_valid_yuv422 : (data_type_i==`RGB888)? byte_valid_rgb888 : (data_type_i==`RGB565)? byte_valid_rgb565 : (data_type_i==`RAW8)? byte_valid_raw8 : (data_type_i==`RAW10)? byte_valid_raw10: 12'd0;

    always_ff@(posedge pixel_clk_i or negedge pixel_reset_n_i) begin
        if(!pixel_reset_n_i) begin
            pixel_data_o <= 0;
            pixel_data_valid_o <= 0;
            byte_valid_o <= 0;
            line_valid_sync_o <= 0;
            line_done_pulse_o <= 0;
        end
        else begin
            if(!stream_stall_i) begin
                line_done_pulse_r <= line_done_pulse;
                line_done_pulse_o <= line_done_pulse_r;
                //line_done_pulse_o <= line_done_pulse_r2;
                line_valid_sync_o <= line_valid_sync_r;
                pixel_data_o <= 0;
                byte_valid_o <= (data_type_i==`YUV422_8)? byte_valid_yuv422 : (data_type_i==`RGB888)? byte_valid_rgb888 : (data_type_i==`RGB565)? byte_valid_rgb565 : (data_type_i==`RAW8)? byte_valid_raw8 : (data_type_i==`RAW10)? byte_valid_raw10: 12'd0;
                pixel_data_valid_o <= pipe_extract? ((pixel_per_clk_i==4)? 4'b1111: (pixel_per_clk_i==2)? 4'b0011: (pixel_per_clk_i==1)? 4'b0001: 4'b0000): 4'b0000;
                case(data_type_i)
                `YUV422_8:  pixel_data_o <= {32'd0, yuv422_pipe}; //64
                `RGB888:    pixel_data_o <= {rgb888_pipe}; //96
                `RGB565:    pixel_data_o <= {32'd0, rgb565_pipe}; //64
                `RAW8:      pixel_data_o <= {64'd0, raw8_pipe}; //32
                `RAW10:     pixel_data_o <= {56'd0, raw10_pipe}; //40
                endcase
            end
        end
    end
    // Add output register to increase performance
    
    //TODO: Make an assert statement to compare the outputs and the inputs
    //TODO: Make an assert statemnt for Timeout pixels
    `ifndef ASIC
        `ifndef FPGA
            // Define the counter
            integer valid_in_c;
            integer valid_in_r;
            logic line_valid_sync_r2;
            integer valid_o_c;
            always @(posedge byte_clk_i, negedge byte_reset_n_i) begin
                if(!byte_reset_n_i)
                    valid_in_c <= 0;
                else begin
                    if(line_valid_posedge || (!line_valid_sync_fake_i && line_valid_sync_fake_reg)) begin
                        valid_in_c <= 0;
                        valid_in_r <= valid_in_c;
                    end
                    else
                        valid_in_c <= valid_in_c + byte_data_valid_i[3] + byte_data_valid_i[2] + byte_data_valid_i[1] + byte_data_valid_i[0];
                end
            end
            // Reset the counter when transitioning between states
            always @(posedge pixel_clk_i, negedge pixel_reset_n_i) begin
                if(!pixel_reset_n_i) begin
                    valid_o_c <= 0;
                    line_valid_sync_r2 <= 0;
                end
                else begin
                    line_valid_sync_r2 <= line_valid_sync_o;
                    if((line_valid_sync_o && !line_valid_sync_r2) || line_done_pulse_o)
                        valid_o_c <= 0;
                    else
                        if(!stream_stall_i)
                            valid_o_c <= valid_o_c + pixel_data_valid_o[3] + pixel_data_valid_o[2] + pixel_data_valid_o[1] + pixel_data_valid_o[0];
                end
            end

            // Define properties for the assertions
            // disable the assertion if counter is zero
            property ineqout;
                @(posedge pixel_clk_i)
                //(posedge_line_valid) |-> ##1 ($past(ycounter) == 'd960);
                (line_done_pulse_o) |-> (valid_in_r == valid_o_c && valid_in_r == 3840);
            endproperty

            property fifofull;
                @(posedge pixel_clk_i) disable iff(!pixel_reset_n_i)
                    (!throttle_ram_full);
            endproperty

            // Assert the properties
            //assert property (ineqout) else $error("Assertion failed: output doesn't eq input output valids = %d, input valids = %d", valid_o_c, valid_in_r);
            assert property (fifofull) 
            else    $error("Assertion fifofull failed: throttle fifo in flow_control module is full. The design is not ready to handle such a condition. Reset is needed");
            // Address sent should be YYUV YYUV YYUV YYUV Assertion check that the address is sent in the correct order
            // Check that the first and the second address request on the AW channel is between frame_ptr_i and frame_ptr1_i 
            // and the third is between frame_ptr1_i and frame_ptr2_i 
            // and fourth address request is larger than frame_ptr2_i
        `endif
    `endif
endmodule