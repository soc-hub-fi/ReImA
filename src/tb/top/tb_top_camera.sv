`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
`include "mipi_csi_data_types.svh"
module tb_top_camera();
    parameter IMG_WIDTH = 512;//3840;
    parameter IMG_LENGTH =512;//2160;
    logic reset_n_i;
    logic   [1:0] vc_id_reg_i [4];
    logic pixel_clk_i;
    assign vc_id_reg_i[0] = 0;
    assign vc_id_reg_i[1] = 1;
    assign vc_id_reg_i[2] = 2;
    assign vc_id_reg_i[3] = 3;
    logic   [5:0] data_type_reg_i [4];
    assign data_type_reg_i [0] = `RAW10; // configurable
    assign data_type_reg_i [1] = `RAW8;
    assign data_type_reg_i [2] = `RAW8;
    assign data_type_reg_i [3] = `RAW8;
    logic [1:0] bayer_filer_type [4];
    assign bayer_filer_type [0] = `RGGB; // configurable
    assign bayer_filer_type [1] = `BGGR;
    assign bayer_filer_type [2] = `BGGR;
    assign bayer_filer_type [3] = `BGGR;
    logic [63:0]  yuv422_data  [4];
    logic [63:0]  yuv_data_reg  [4];
    logic   [7:0] yuv422_byte_valid [4];
    integer read_file;
    integer write_yuv_file;
    logic ppc1_write;
    logic [31:0] yuv_pixels;
    if_csi_dphy_rx_model #(.MIPI_GEAR(8), .MIPI_LANES(4), .WIDTH(IMG_WIDTH), .LENGTH(IMG_LENGTH) , .DATATYPE("RAW10"), .INPUT("LINE")) csi_dphy_rx(); // change this when chaning the image

    mipi_camera_processor mipi_camera_processor_i(
                            .reset_n_i(reset_n_i),
                            .pixel_clk_i(pixel_clk_i)
                    );

    assign mipi_camera_processor_i.rx_byte_clk_hs = csi_dphy_rx.rx_byte_clk_hs_o;
    assign mipi_camera_processor_i.vc_id_reg = vc_id_reg_i;
    assign mipi_camera_processor_i.data_type_reg = data_type_reg_i;
    assign mipi_camera_processor_i.active_lanes_reg = 3'd4;
    assign mipi_camera_processor_i.clear_frame_data = '{1'b0,1'b0,1'b0,1'b0};
    assign mipi_camera_processor_i.clear_frame_sync = '{1'b0,1'b0,1'b0,1'b0};
    assign mipi_camera_processor_i.err_sot_hs =1'b0;
    assign mipi_camera_processor_i.err_sot_sync_hs =1'b0;
    assign mipi_camera_processor_i.rx_valid_hs = csi_dphy_rx.rx_valid_hs_o;
    assign mipi_camera_processor_i.rx_data_hs = csi_dphy_rx.rx_data_hs_o;
    assign mipi_camera_processor_i.pixel_per_clk_reg ='{3'd2,3'd2,3'd2,3'd2};
    assign mipi_camera_processor_i.bayer_filter_type_reg = bayer_filer_type;
    assign yuv422_data = mipi_camera_processor_i.yuv422_data;
    assign yuv422_byte_valid = mipi_camera_processor_i.yuv422_byte_valid;

    // clk generation
    initial csi_dphy_rx.clk_i = 0;
    always #20 csi_dphy_rx.clk_i = ~csi_dphy_rx.clk_i;

    initial pixel_clk_i = 0;
    always #1 pixel_clk_i = ~pixel_clk_i;

    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
		if(!reset_n_i) begin
			ppc1_write <= 0;
			yuv_data_reg[0] <= 0;
		end
		else begin
			yuv_data_reg[0] <= yuv422_data[0];
			if(yuv422_byte_valid[0])
				ppc1_write<=!ppc1_write;
		end
	end

    //write file logic
    always@(posedge pixel_clk_i) begin
        if(yuv422_byte_valid[0]==8'b1111_1111)
            $fwrite(write_yuv_file, "%u", {yuv422_data[0][7:0], yuv422_data[0][15:8], yuv422_data[0][23:16], yuv422_data[0][31:24], yuv422_data[0][39:32], yuv422_data[0][47:40], yuv422_data[0][55:48], yuv422_data[0][63:56] });
        else if(yuv422_byte_valid[0]==8'b0000_1111)
            $fwrite(write_yuv_file, "%u", {yuv422_data[0][7:0], yuv422_data[0][15:8], yuv422_data[0][23:16], yuv422_data[0][31:24]});
        else if(ppc1_write)
            $fwrite(write_yuv_file, "%u", {yuv422_data[0][7:0], yuv422_data[0][15:8], yuv_data_reg[0][7:0], yuv_data_reg[0][15:8]});
	end

    // test
    initial begin
        force mipi_camera_processor_i.isp_axi_master_i.stream_stall_o = 1'b0;
        read_file = $fopen("../src/tb/img_in/img_bayer_3840x2160_RGGB_08bits.raw","rb");
        write_yuv_file = $fopen("../src/tb/img_out/frames.yuv","wb");
        csi_dphy_rx.reset_outputs();
        reset_n_i=1;
        #20
        reset_n_i=0;
        #20
        reset_n_i=1;
        wait(!csi_dphy_rx.clk_i);
        wait(csi_dphy_rx.clk_i);
        csi_dphy_rx.send_frame(1,0,read_file);
        // wait for 3 lines
        //for(int i=0; i<3*IMG_WIDTH; i++)
        //   csi_dphy_rx.clock();
        csi_dphy_rx.send_frame(2,0,read_file);
        // wait for 3 lines
        for(int i=0; i<3*IMG_WIDTH; i++)
            csi_dphy_rx.clock();
        $fclose(read_file);
        $finish;
    end
    // counter for the number of yuv pixels
    always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
        if(!reset_n_i)
            yuv_pixels <= 0;
        else begin
                //if(|yuv422_byte_valid[0])
                    yuv_pixels <= yuv_pixels + yuv422_byte_valid[0][0] + yuv422_byte_valid[0][1] + yuv422_byte_valid[0][2] + yuv422_byte_valid[0][3]; 
                //else
                    //yuv_pixels <= 0;
            end
    end
endmodule