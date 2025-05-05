/*
    File: image_processing_unit.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: According to MIPI CSI RX specs v1.01

    Functionality: 
    -   The module is a top level integration for Image Signal Processing and Pixel control logic
    -   You can instantiate a variable number of ISP pipelines which corresponds to the number of
        Virtual Channels supported in the design
    Author: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
module image_processing_unit #(
                        parameter PIPELINE_WIDTH = 4 // Number of ISP pipelines
                )
                    (
                        input                   byte_reset_n_i,                             // Active low reset
                        input                   byte_clk_i,                                 // Byte clock usually 1/8 of the line rate coming from the DPHY
                        input                   pixel_reset_n_i,                            // Active low reset
                        input                   pixel_clk_i,                                // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
                        input                   isp_clk_enable_i,
                        input           [3:0]   activate_stream_i,                          // Picks which ISP pipeline does the data go to
                        input           [2:0]   pixel_per_clk_reg_i     [PIPELINE_WIDTH],   // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
                        input           [5:0]   data_type_reg_i         [PIPELINE_WIDTH],   // Programmable datatype that each pipeline should process
                        input           [1:0]   bayer_filter_type_reg_i [PIPELINE_WIDTH],   // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
                        input                   frame_valid_i           [PIPELINE_WIDTH],   // Frame receiption is in progress signal
                        input                   line_valid_i            [PIPELINE_WIDTH],   // Line receiption is in progress signal
                        output                  line_valid_pixel_sync_o [PIPELINE_WIDTH],   // Synchronized line_valid signal with the data output interface
                        output                  line_valid_yuv_sync_o   [PIPELINE_WIDTH],   // Synchronized line_valid signal with the data output interface
                        output logic            frame_done_pulse_o      [PIPELINE_WIDTH],   // frame done signal from debayer
                        input                   line_valid_sync_fake_i,
                        input           [3:0]   byte_data_valid_i,                          // Pixel data valid signal for each pixel in the pixel data in the byte clock domain
                        input           [47:0]  byte_data_i,                                // Max width is 2 RGB888 pixels 2*24 = 48 these are pixels in the byte clock domain
                        output logic 	[63:0]  yuv422_data_o           [PIPELINE_WIDTH],   // YUV data (YUYV format) if 4ppc is selected, output is YUYV,YUYV if 2pcc output is YUYV if 1ppc output alternates each cycle between YU and YV
				        output logic 	[7:0]   yuv422_byte_valid_o     [PIPELINE_WIDTH],   // YUV valid each bit corresponds to 16 bits (1 pixel) of the yuv data
                        output logic    [95:0]  pixel_data_o            [PIPELINE_WIDTH],   // Preprocessed data coming from flow control with a specified pixel per clock
                        output logic    [11:0]  pixel_byte_valid_o      [PIPELINE_WIDTH]    // Each bit in the valid corresponds to a byte in the pixel_data_o interface
                        );
    genvar i;

    // flow control signals
    logic           dst_clear_pending       [PIPELINE_WIDTH];
    logic           src_clear_pending       [PIPELINE_WIDTH];
    logic           frame_valid_sync        [PIPELINE_WIDTH];
    logic           line_valid_sync_fake    [PIPELINE_WIDTH];
    logic [3:0]     byte_data_valid         [PIPELINE_WIDTH];
    logic [3:0]     pixel_data_valid        [PIPELINE_WIDTH];
    logic           line_done_pulse         [PIPELINE_WIDTH];

    // debayer filter signals
    logic           line_valid_sync3        [PIPELINE_WIDTH];
    logic           line_valid_sync2        [PIPELINE_WIDTH];
    logic [3:0]     rgb_data_valid          [PIPELINE_WIDTH];
    logic [119:0]   rgb_data                [PIPELINE_WIDTH];

    generate
        for(i=0; i<PIPELINE_WIDTH; i++) begin: isp_gen
//------------------------------------------ instantiate flow control block ------------------------------------------//
            //* The flow control configuration registers can be dynamically changed during runtime however
            //* When reading a line you don't want to mix different virtual channels or different datatypes
            //* In the same line buffer so separate these into different flow controls for each isp pipeline

            assign byte_data_valid[i] = (activate_stream_i [i])? byte_data_valid_i:4'd0;
            assign line_valid_sync_fake[i] = (activate_stream_i [i])? line_valid_sync_fake_i:1'd0;

            ipu_flow_control
                flow_control_i(
                                // clocks and reset
                                .byte_reset_n_i         (   byte_reset_n_i              ),      // Active low reset
                                .byte_clk_i             (   byte_clk_i                  ),      // Byte clock usually 1/8 of the line rate coming from the DPHY
                                .pixel_reset_n_i        (   pixel_reset_n_i             ),      // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
                                .pixel_clk_i            (   pixel_clk_i                 ),      // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
                                
                                // configuration interface
                                .pixel_per_clk_i        (   pixel_per_clk_reg_i     [i] ),      // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
                                .data_type_i            (   data_type_reg_i         [i] ),      // Video data type such as RGB, RAW..etc
                                
                                // data interface
                                .line_valid_i           (   line_valid_i            [i] ),      // line valid in from short packet decoding
                                .frame_valid_i          (   frame_valid_i           [i] ),
                                .line_valid_sync_fake_i (   line_valid_sync_fake    [i] ),
                                .byte_data_valid_i      (   byte_data_valid         [i] ),      // Pixel data valid signal for each pixel in the pixel data
                                .byte_data_i            (   byte_data_i                 ),      // Max width is 2 RGB888 pixels 2*24 = 48
                                .dst_clear_pending_o    (   dst_clear_pending  [i]      ),
                                .src_clear_pending_o    (   src_clear_pending [i]       ),
                                .line_valid_sync_o      (   line_valid_pixel_sync_o [i] ),      // line valid signal synchronized with the output data because of buffering delay
                                .line_done_pulse_o      (   line_done_pulse         [i] ),
                                .frame_valid_sync_o     (   frame_valid_sync        [i] ),      // frame valid signal synchronized with the output data because of buffering delay
                                .pixel_data_valid_o     (   pixel_data_valid        [i] ),      // Each bit corresponds to a pixel in the pixel_data_o port
                                .pixel_data_o           (   pixel_data_o            [i] ),      // Depending on the datatype some of the bits might not be used. Maximum Width(RGB888) = (8+8+8) * 4 = 96
                                .byte_valid_o           (   pixel_byte_valid_o      [i] )
                                );

//------------------------------------------ instantiate debayer filter block -------------------------------------//

            ipu_debayer_filter
                ipu_debayer_filter_i    (
                                // clocks and reset interface
                                .reset_n_i              (   pixel_reset_n_i             ),
                                .clk_i                  (   pixel_clk_i                 ),

                                // configuration interface
                                .data_type_i            (   data_type_reg_i         [i] ),
                                .pixel_per_clk_i        (   pixel_per_clk_reg_i     [i] ),
                                .bayer_filter_type_i    (   bayer_filter_type_reg_i [i] ),

                                // data interface
                                .frame_valid_i          (   frame_valid_sync        [i] ),
                                .line_valid_i           (   line_valid_pixel_sync_o [i] ),
                                .line_done_pulse_i      (   line_done_pulse         [i] ),
                                .line_valid_sync_o      (   line_valid_sync2        [i] ),
                                .pixel_data_i           (   pixel_data_o            [i] ),
                                .pixel_data_valid_i     (   pixel_data_valid        [i] ),
                                .pixel_data_valid_o     (   rgb_data_valid          [i] ),
                                .pixel_data_o           (   rgb_data                [i] ),
                                .frame_done_pulse_o     (   frame_done_pulse_o      [i] )
                            );
//------------------------------------------ instantiate rgb2yuv block ------------------------------------------//

            ipu_color_conversion
                ipu_color_conversion_i    (   
                                // clocks and reset interface
                                .reset_n_i              (   pixel_reset_n_i             ),
                                .pixel_clk_i            (   pixel_clk_i                 ),

                                // configuration interface
                                .pixel_per_clk_reg_i    (   pixel_per_clk_reg_i     [i] ),
                                .data_type_reg_i        (   data_type_reg_i         [i] ),
                                
                                // data interface
                                .line_valid_i           (   line_valid_sync2        [i] ),
                                .line_valid_sync_o      (   line_valid_yuv_sync_o   [i] ),
                                .rgb_data_valid_i       (   rgb_data_valid          [i] ),
                                .rgb_data_i             (   rgb_data                [i] ),
                                .yuv_byte_valid_o       (   yuv422_byte_valid_o     [i] ),
                                .yuv_data_o             (   yuv422_data_o           [i] )
                        );
        end
    endgenerate
endmodule