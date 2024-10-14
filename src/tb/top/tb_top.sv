`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
`include "mipi_csi_data_types.svh"
`define PPC4
module tb_top();
    logic reset_n_i;
    logic   [1:0] vc_id_reg_i [4];
    assign vc_id_reg_i[0] = 0;
    assign vc_id_reg_i[1] = 1;
    assign vc_id_reg_i[2] = 2;
    assign vc_id_reg_i[3] = 3;
    logic   [5:0] data_type_reg_i [4];
    assign data_type_reg_i [0] = `RAW8;
    assign data_type_reg_i [1] = `RAW10;
    assign data_type_reg_i [2] = `RAW10;
    assign data_type_reg_i [3] = `RAW10;
    logic [((4 * 2 * 8) - 1'd1):0]  yuv_data_o  [4];
    logic   yuv_valid_o   [4];
    integer read_file;
    integer write_yuv_file;
    if_csi_dphy_rx_model #(.MIPI_GEAR(8), .MIPI_LANES(4)) csi_dphy_rx();
    
    top_csi #(.PIXEL_PER_CLK(4)) top_csi_i(
        .reset_n_i(reset_n_i),
        .rx_byte_clk_hs_i(csi_dphy_rx.rx_byte_clk_hs_o),
        .rx_valid_hs_i(csi_dphy_rx.rx_valid_hs_o),
        .rx_data_hs_i(csi_dphy_rx.rx_data_hs_o),
        .err_sot_hs_i(1'b0),
        .err_sot_sync_hs_i(1'b0),
        .vc_id_reg_i(vc_id_reg_i),
        .data_type_reg_i(data_type_reg_i),
        .active_lanes_i(3'd4),         // Active lanes coming from conifg register can be 1 2 or 4 lanes active
        .pixel_per_clk_i(3'd4),
        .bayer_filter_type_i(`BGGR),
        .clear_frame_data_i('{1'b0,1'b0,1'b0,1'b0}),
        .clear_frame_sync_i('{1'b0,1'b0,1'b0,1'b0}),
        .err_frame_sync_o(),
        .err_frame_data_o(),
        .gsc1_o(),
        .gsc2_o(),
        .gsc3_o(),
        .gsc4_o(),
        .gsc5_o(),
        .gsc6_o(),
        .gsc7_o(),
        .gsc8_o(),
        .yuv_data_o(yuv_data_o),
        .yuv_valid_o(yuv_valid_o)
    );

    // clk generation
    initial csi_dphy_rx.clk_i = 0;
    always #10 csi_dphy_rx.clk_i = ~csi_dphy_rx.clk_i;

    always@(posedge csi_dphy_rx.clk_i) begin
        `ifdef PPC4
            if(yuv_valid_o[0])
                $fwrite(write_yuv_file, "%u", {yuv_data_o[0][7:0], yuv_data_o[0][15:8], yuv_data_o[0][23:16], yuv_data_o[0][31:24], yuv_data_o[0][39:32], yuv_data_o[0][47:40], yuv_data_o[0][55:48], yuv_data_o[0][63:56] });
        `else
            if(yuv_valid_o[0])
                $fwrite(write_yuv_file, "%u", {yuv_data_o[0][7:0], yuv_data_o[0][15:8], yuv_data_o[0][23:16], yuv_data_o[0][31:24]});
        `endif
    end

    // test
    initial begin
        read_file = $fopen("../src/tb/img_in/img_bayer_512x512_BGGR_08bits.raw","rb");
        write_yuv_file = $fopen("../src/tb/img_out/italy.bmp768x512.raw.yuv","wb");
        csi_dphy_rx.reset_outputs();
        reset_n_i=1;
        #20
        reset_n_i=0;
        #20
        reset_n_i=1;
        wait(!csi_dphy_rx.clk_i);
        wait(csi_dphy_rx.clk_i);
        csi_dphy_rx.send_frame(1,0,read_file);
        $fclose(read_file);
        $finish;
    end
endmodule