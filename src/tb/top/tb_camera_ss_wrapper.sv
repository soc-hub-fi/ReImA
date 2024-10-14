`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
//`define REG_SANITY_TEST 1
`include "mipi_csi_data_types.svh"
`include "axi/assign.svh"
`include "csi_regs.svh"
module tb_camera_ss_wrapper #(
        // AXI paramters
        parameter AXIM_ID_WIDTH      = 9,
        parameter AXIM_ADDR_WIDTH    = 32,
        parameter AXIM_DATA_WIDTH    = 32,
        parameter AXIM_USER_WIDTH    = 1,
        parameter AXIS_ID_WIDTH      = 9,
        parameter AXIS_ADDR_WIDTH    = 32,
        parameter AXIS_DATA_WIDTH    = 32,
        parameter AXIS_USER_WIDTH    = 1,
        // TB parameters
        parameter IMG_WIDTH         = 3840,
        parameter IMG_LENGTH        = 2160,
        parameter time BYTE_PERIOD  = 5.555ns, // 180MHz byte clock
        parameter time REFCLK_PERIOD = 3.333ns, // 300MHz refclk to replace pll
        parameter time SDRAM_PERIOD = 2ns // 500MHz SDRAM clock
    );
    parameter PTR0_ADDR = 32'h0000_0000;
    parameter PTR1_ADDR = 32'h0000_0000 + PTR0_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR2_ADDR = 32'h0000_0000 + PTR1_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;

    parameter PTR3_ADDR = 32'h0010_0000;
    parameter PTR4_ADDR = 32'h0000_0000 + PTR3_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR5_ADDR = 32'h0000_0000 + PTR4_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;
    logic [ 31:0] tmp_axi_data;
    logic force_cka = 0;
    logic force_ckb = 0;
    logic sel_cka = 1; // select ref clock
    logic subsys_clkena = 1;
    logic         [1:0]          axi_master_cam_ar_rd_data_ptr_dst2src;
    logic         [2:0]          axi_master_cam_ar_rd_ptr_gray_dst2src;
    logic         [1:0]          axi_master_cam_aw_rd_data_ptr_dst2src;
    logic         [2:0]          axi_master_cam_aw_rd_ptr_gray_dst2src;
    logic         [11:0]         axi_master_cam_b_data_dst2src;
    logic         [2:0]          axi_master_cam_b_wr_ptr_gray_dst2src;
    logic         [44:0]         axi_master_cam_r_data_dst2src;
    logic         [2:0]          axi_master_cam_r_wr_ptr_gray_dst2src;
    logic         [1:0]          axi_master_cam_w_rd_data_ptr_dst2src;
    logic         [2:0]          axi_master_cam_w_rd_ptr_gray_dst2src;
    logic         [70:0]         axi_master_cam_ar_data_src2dst;
    logic         [2:0]          axi_master_cam_ar_wr_ptr_gray_src2dst;
    logic         [76:0]         axi_master_cam_aw_data_src2dst;
    logic         [2:0]          axi_master_cam_aw_wr_ptr_gray_src2dst;
    logic         [1:0]          axi_master_cam_b_rd_data_ptr_src2dst;
    logic         [2:0]          axi_master_cam_b_rd_ptr_gray_src2dst;
    logic         [1:0]          axi_master_cam_r_rd_data_ptr_src2dst;
    logic         [2:0]          axi_master_cam_r_rd_ptr_gray_src2dst;
    logic         [37:0]         axi_master_cam_w_data_src2dst;
    logic         [2:0]          axi_master_cam_w_wr_ptr_gray_src2dst;

    logic         [70:0]         axi_slave_cam_ar_data_src2dst;
    logic         [2:0]          axi_slave_cam_ar_wr_ptr_gray_src2dst;
    logic         [76:0]         axi_slave_cam_aw_data_src2dst;
    logic         [2:0]          axi_slave_cam_aw_wr_ptr_gray_src2dst;
    logic         [1:0]          axi_slave_cam_b_rd_data_ptr_src2dst;
    logic         [2:0]          axi_slave_cam_b_rd_ptr_gray_src2dst;
    logic         [1:0]          axi_slave_cam_r_rd_data_ptr_src2dst;
    logic         [2:0]          axi_slave_cam_r_rd_ptr_gray_src2dst;
    logic         [37:0]         axi_slave_cam_w_data_src2dst;
    logic         [2:0]          axi_slave_cam_w_wr_ptr_gray_src2dst;
    logic         [1:0]          axi_slave_cam_ar_rd_data_ptr_dst2src;
    logic         [2:0]          axi_slave_cam_ar_rd_ptr_gray_dst2src;
    logic         [1:0]          axi_slave_cam_aw_rd_data_ptr_dst2src;
    logic         [2:0]          axi_slave_cam_aw_rd_ptr_gray_dst2src;
    logic         [11:0]         axi_slave_cam_b_data_dst2src;
    logic         [2:0]          axi_slave_cam_b_wr_ptr_gray_dst2src;
    logic         [44:0]         axi_slave_cam_r_data_dst2src;
    logic         [2:0]          axi_slave_cam_r_wr_ptr_gray_dst2src;
    logic         [1:0]          axi_slave_cam_w_rd_data_ptr_dst2src;
    logic         [2:0]          axi_slave_cam_w_rd_ptr_gray_dst2src;
    /*********************
    *  CLOCK GENERATOR  *
    *********************/
    logic reset_n_i;
    logic sdram_reset_n_i;
    logic ref_clk_i;
    clk_rst_gen #(
        .ClkPeriod      (BYTE_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_byte_gen (
        .clk_o          (csi_dphy_rx.clk_i ),
        .rst_no         (reset_n_i)
    );
    
    clk_rst_gen #(
        .ClkPeriod      (REFCLK_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_ref_gen (
        .clk_o          (ref_clk_i ),
        .rst_no         ()
    );

    clk_rst_gen #(
        .ClkPeriod      (SDRAM_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_sdram_gen (
        .clk_o          (sdram_clk_i ),
        .rst_no         (sdram_reset_n_i)
    );

    /*********
    *  AXI  *
    *********/
    // Slave port

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(AXIM_ADDR_WIDTH      ),
        .AXI_DATA_WIDTH(AXIM_DATA_WIDTH      ),
        .AXI_ID_WIDTH  (AXIM_ID_WIDTH        ),
        .AXI_USER_WIDTH(AXIM_USER_WIDTH      )
    ) slave_dv (
        .clk_i(sdram_clk_i)
    );

    AXI_BUS #(
        .AXI_ADDR_WIDTH(AXIM_ADDR_WIDTH      ),
        .AXI_DATA_WIDTH(AXIM_DATA_WIDTH      ),
        .AXI_ID_WIDTH  (AXIM_ID_WIDTH        ),
        .AXI_USER_WIDTH(AXIM_USER_WIDTH      )
    ) slave ();

    axi_test::axi_rand_slave #(
        .AW(AXIM_ADDR_WIDTH      ),
        .DW(AXIM_DATA_WIDTH      ),
        .IW(AXIM_ID_WIDTH        ),
        .UW(AXIM_USER_WIDTH      ),
        .TA(SDRAM_PERIOD         ),
        .TT(SDRAM_PERIOD         ),
        .RESP_MAX_WAIT_CYCLES(0)
    ) slave_drv = new (slave_dv);

    `AXI_ASSIGN(slave_dv, slave)

    // Master port
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AXIS_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXIS_DATA_WIDTH    ),
        .AXI_USER_WIDTH ( AXIS_USER_WIDTH    ),
        .AXI_ID_WIDTH   ( AXIS_ID_WIDTH      )
    ) axi_mst_dv ( ref_clk_i );

    AXI_BUS #(
		.AXI_ADDR_WIDTH ( AXIS_ADDR_WIDTH ),
		.AXI_DATA_WIDTH ( AXIS_DATA_WIDTH    ),
		.AXI_ID_WIDTH   ( AXIS_ID_WIDTH      ),
		.AXI_USER_WIDTH ( AXIS_USER_WIDTH    )
	) master ();

    axi_test::axi_driver #(
        .AW(AXIS_ADDR_WIDTH      ),
        .DW(AXIS_DATA_WIDTH      ),
        .IW(AXIS_ID_WIDTH        ),
        .UW(AXIS_USER_WIDTH      ),
        .TA(REFCLK_PERIOD         ),
        .TT(REFCLK_PERIOD         )
    )   master_drv = new( axi_mst_dv );

    `AXI_ASSIGN( master, axi_mst_dv)

    task axi_write_mst( input int addr, input longint data, input int strb, input logic print=0);
        automatic axi_test::axi_ax_beat #(.AW(AXIS_ADDR_WIDTH), .IW(AXIS_ID_WIDTH), .UW(AXIS_USER_WIDTH)) ax_beat = new;
        automatic axi_test::axi_w_beat  #(.DW(32), .UW(AXIS_USER_WIDTH))              w_beat  = new;
        automatic axi_test::axi_b_beat  #(.IW(AXIS_ID_WIDTH), .UW(AXIS_USER_WIDTH))              b_beat;
        master_drv.axi.aw_addr = addr;
        master_drv.axi.w_data = data;
        master_drv.axi.w_strb = '1;
        master_drv.axi.w_last =  1;
        master_drv.axi.aw_valid = 1;
        master_drv.axi.w_valid = 1;
        master_drv.cycle_start();
        fork
            while (master_drv.axi.aw_ready != 1) begin master_drv.cycle_end(); master_drv.cycle_start(); end
            while (master_drv.axi.w_ready != 1) begin master_drv.cycle_end(); master_drv.cycle_start(); end
        join
        master_drv.cycle_end();
        master_drv.axi.aw_valid = 0;
        master_drv.axi.w_valid = 0;
        if (print) $write("WRITE addr %h, WRITE data %h \n", addr, data);
        master_drv.recv_b(b_beat);
    endtask

    task axi_read_mst( input int addr, output longint data, input logic print=0 );
        automatic axi_test::axi_ax_beat #(.AW(AXIS_ADDR_WIDTH), .IW(AXIS_ID_WIDTH), .UW(AXIS_USER_WIDTH)) ax_beat = new;
        automatic axi_test::axi_r_beat  #(.DW(32), .IW(AXIS_ID_WIDTH), .UW(AXIS_USER_WIDTH)) r_beat  = new;
        ax_beat.ax_addr = addr;
        master_drv.send_ar(ax_beat);
        master_drv.recv_r(r_beat);
        if (print) $write("READ data: %h ", r_beat.r_data);
        data = r_beat.r_data;
    endtask

    // configuration registers
    logic   [1:0] vc_id_reg_i [4];
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

    // signals
    logic           eos;
    logic   [63:0]  yuv422_data  [4];
    logic   [63:0]  yuv_data_reg  [4];
    logic   [7:0]   yuv422_byte_valid [4];
    integer         read_file;
    logic           ppc1_write;
    logic   [31:0]  yuv_pixels;
    /*************
    *  DRIVERS  *
    *************/
    if_csi_dphy_rx_model_old #(
                    .MIPI_GEAR(8), 
                    .MIPI_LANES(4), 
                    .WIDTH(IMG_WIDTH), 
                    .LENGTH(IMG_LENGTH), 
                    .DATATYPE("RAW10"), 
                    .INPUT("IMG")
                ) 
        csi_dphy_rx(); // change this when chaning the image


        axi_cdc_split_intf_src 
        #(
          .AXI_ID_WIDTH     ( 9  ),
          .AXI_ADDR_WIDTH   ( 32 ),
          .AXI_DATA_WIDTH   ( 32 ),
          .AXI_USER_WIDTH   ( 1  ),
          .LOG_DEPTH        ( 2  ),
          .AW_DATA_SIZE     ( 77 ),
          .AR_DATA_SIZE     ( 71 ),
          .W_DATA_SIZE      ( 38 ),
          .R_DATA_SIZE      ( 45 ),
          .B_DATA_SIZE      ( 12  )
          ) 
      i_axi_slave_cdc_split_intf_src
        (
         .src_clk_i  ( ref_clk_i ),
         .src_rst_ni ( reset_n_i ),
         .icn_rst_ni ( reset_n_i ),
     
         .aw_id(master.aw_id), 
         .aw_addr(master.aw_addr),
         .aw_len(master.aw_len), 
         .aw_size(master.aw_size), 
         .aw_burst(master.aw_burst), 
         .aw_lock(master.aw_lock), 
         .aw_cache(master.aw_cache), 
         .aw_prot(master.aw_prot), 
         .aw_qos(master.aw_qos), 
         .aw_region(master.aw_region), 
         .aw_atop(master.aw_atop), 
         .aw_user(master.aw_user), 
         .aw_valid(master.aw_valid), 
         .aw_ready(master.aw_ready),
     
         .w_data(master.w_data), 
         .w_strb(master.w_strb), 
         .w_last(master.w_last), 
         .w_user(master.w_user), 
         .w_valid(master.w_valid), 
         .w_ready(master.w_ready),
     
         .b_id(master.b_id), 
         .b_resp(master.b_resp), 
         .b_user(master.b_user), 
         .b_valid(master.b_valid), 
         .b_ready(master.b_ready),
     
         .ar_id(master.ar_id), 
         .ar_addr(master.ar_addr), 
         .ar_len(master.ar_len), 
         .ar_size(master.ar_size), 
         .ar_burst(master.ar_burst), 
         .ar_lock(master.ar_lock), 
         .ar_cache(master.ar_cache), 
         .ar_prot(master.ar_prot), 
         .ar_qos(master.ar_qos), 
         .ar_region(master.ar_region), 
         .ar_user(master.ar_user), 
         .ar_valid(master.ar_valid), 
         .ar_ready(master.ar_ready),
     
         .r_id(master.r_id), 
         .r_data(master.r_data), 
         .r_resp(master.r_resp), 
         .r_last(master.r_last), 
         .r_user(master.r_user), 
         .r_valid(master.r_valid), 
         .r_ready(master.r_ready),
         
         .aw_data_src2dst( axi_slave_cam_aw_data_src2dst ),
         .aw_rd_data_ptr_dst2src( axi_slave_cam_aw_rd_data_ptr_dst2src ),
         .aw_rd_ptr_gray_dst2src( axi_slave_cam_aw_rd_ptr_gray_dst2src ),
         .aw_wr_ptr_gray_src2dst( axi_slave_cam_aw_wr_ptr_gray_src2dst ),
     
         .ar_data_src2dst( axi_slave_cam_ar_data_src2dst ),
         .ar_rd_data_ptr_dst2src( axi_slave_cam_ar_rd_data_ptr_dst2src ),
         .ar_rd_ptr_gray_dst2src( axi_slave_cam_ar_rd_ptr_gray_dst2src ),
         .ar_wr_ptr_gray_src2dst( axi_slave_cam_ar_wr_ptr_gray_src2dst ),
     
         .w_data_src2dst( axi_slave_cam_w_data_src2dst ),
         .w_rd_data_ptr_dst2src( axi_slave_cam_w_rd_data_ptr_dst2src ),
         .w_rd_ptr_gray_dst2src( axi_slave_cam_w_rd_ptr_gray_dst2src ),
         .w_wr_ptr_gray_src2dst( axi_slave_cam_w_wr_ptr_gray_src2dst ),
     
         .r_data_dst2src( axi_slave_cam_r_data_dst2src ),
         .r_rd_data_ptr_src2dst( axi_slave_cam_r_rd_data_ptr_src2dst ),
         .r_rd_ptr_gray_src2dst( axi_slave_cam_r_rd_ptr_gray_src2dst ),
         .r_wr_ptr_gray_dst2src( axi_slave_cam_r_wr_ptr_gray_dst2src ),
     
         .b_data_dst2src( axi_slave_cam_b_data_dst2src ),
         .b_rd_data_ptr_src2dst( axi_slave_cam_b_rd_data_ptr_src2dst ),
         .b_rd_ptr_gray_src2dst( axi_slave_cam_b_rd_ptr_gray_src2dst ),
         .b_wr_ptr_gray_dst2src( axi_slave_cam_b_wr_ptr_gray_dst2src )
         );

         axi_cdc_split_intf_dst #(
            .AXI_ID_WIDTH(9),
            .AXI_ADDR_WIDTH(32),
            .AXI_DATA_WIDTH(32),
            .AXI_USER_WIDTH(1),
            .AW_DATA_SIZE(77),
            .AR_DATA_SIZE(71),
            .W_DATA_SIZE(38),
            .R_DATA_SIZE(45),
            .B_DATA_SIZE(12),
            .LOG_DEPTH(2)
        )
        axi_cdc_split_intf_dst_i (
            // master side - clocked by `dst_clk_i`
            .dst_clk_i(sdram_clk_i),
            .dst_rst_ni(sdram_reset_n_i),
            .icn_rst_ni(sdram_reset_n_i),
            
            //AXI_BUS.Master    dst,
            .aw_id(slave.aw_id),
            .aw_addr(slave.aw_addr),
            .aw_len(slave.aw_len),
            .aw_size(slave.aw_size),
            .aw_burst(slave.aw_burst),
            .aw_lock(slave.aw_lock),
            .aw_cache(slave.aw_cache),
            .aw_prot(slave.aw_prot),
            .aw_qos(slave.aw_qos),
            .aw_region(slave.aw_region),
            .aw_atop(slave.aw_atop),
            .aw_user(slave.aw_user),
            .aw_valid(slave.aw_valid),
            .aw_ready(slave.aw_ready),

            .w_data(slave.w_data),
            .w_strb(slave.w_strb),
            .w_last(slave.w_last),
            .w_user(slave.w_user),
            .w_valid(slave.w_valid),
            .w_ready(slave.w_ready),

            .b_id(slave.b_id), 
            .b_resp(slave.b_resp),
            .b_user(slave.b_user), 
            .b_valid(slave.b_valid), 
            .b_ready(slave.b_ready),

            .ar_id(slave.ar_id), 
            .ar_addr(slave.ar_addr), 
            .ar_len(slave.ar_len), 
            .ar_size(slave.ar_size), 
            .ar_burst(slave.ar_burst), 
            .ar_lock(slave.ar_lock), 
            .ar_cache(slave.ar_cache), 
            .ar_prot(slave.ar_prot), 
            .ar_qos(slave.ar_qos), 
            .ar_region(slave.ar_region), 
            .ar_user(slave.ar_user), 
            .ar_valid(slave.ar_valid), 
            .ar_ready(slave.ar_ready),

            .r_id(slave.r_id), 
            .r_data(slave.r_data), 
            .r_resp(slave.r_resp), 
            .r_last(slave.r_last), 
            .r_user(slave.r_user), 
            .r_valid(slave.r_valid), 
            .r_ready(slave.r_ready),

            .aw_data_src2dst(axi_master_cam_aw_data_src2dst),
            .aw_rd_data_ptr_dst2src(axi_master_cam_aw_rd_data_ptr_dst2src),
            .aw_rd_ptr_gray_dst2src(axi_master_cam_aw_rd_ptr_gray_dst2src),
            .aw_wr_ptr_gray_src2dst(axi_master_cam_aw_wr_ptr_gray_src2dst),

            .ar_data_src2dst(axi_master_cam_ar_data_src2dst),
            .ar_rd_data_ptr_dst2src(axi_master_cam_ar_rd_data_ptr_dst2src),
            .ar_rd_ptr_gray_dst2src(axi_master_cam_ar_rd_ptr_gray_dst2src),
            .ar_wr_ptr_gray_src2dst(axi_master_cam_ar_wr_ptr_gray_src2dst),

            .w_data_src2dst(axi_master_cam_w_data_src2dst),
            .w_rd_data_ptr_dst2src(axi_master_cam_w_rd_data_ptr_dst2src),
            .w_rd_ptr_gray_dst2src(axi_master_cam_w_rd_ptr_gray_dst2src),
            .w_wr_ptr_gray_src2dst(axi_master_cam_w_wr_ptr_gray_src2dst),

            .r_data_dst2src(axi_master_cam_r_data_dst2src),
            .r_rd_data_ptr_src2dst(axi_master_cam_r_rd_data_ptr_src2dst),
            .r_rd_ptr_gray_src2dst(axi_master_cam_r_rd_ptr_gray_src2dst),
            .r_wr_ptr_gray_dst2src(axi_master_cam_r_wr_ptr_gray_dst2src),

            .b_data_dst2src(axi_master_cam_b_data_dst2src),
            .b_rd_data_ptr_src2dst(axi_master_cam_b_rd_data_ptr_src2dst),
            .b_rd_ptr_gray_src2dst(axi_master_cam_b_rd_ptr_gray_src2dst),
            .b_wr_ptr_gray_dst2src(axi_master_cam_b_wr_ptr_gray_dst2src)
        );

    /*********
    *  DUT  *
    *********/
    camera_ss_wrapper camera_ss_wrapper_i (
    // Interface: DPHY
    //.clk_lane_n,
    //.clk_lane_p,
    //.data_lane_0_n,
    //.data_lane_0_p,
    //.data_lane_1_n,
    //.data_lane_1_p,
    //.data_lane_2_n,
    //.data_lane_2_p,
    //.data_lane_3_n,
    //.data_lane_3_p,

    // Interface: IRQ
    .frame_wr_done_intr_o(frame_wr_done_intr_o),

    // Interface: axi_master
    .axi_master_cam_ar_rd_data_ptr_dst2src(axi_master_cam_ar_rd_data_ptr_dst2src),
    .axi_master_cam_ar_rd_ptr_gray_dst2src(axi_master_cam_ar_rd_ptr_gray_dst2src),
    .axi_master_cam_aw_rd_data_ptr_dst2src(axi_master_cam_aw_rd_data_ptr_dst2src),
    .axi_master_cam_aw_rd_ptr_gray_dst2src(axi_master_cam_aw_rd_ptr_gray_dst2src),
    .axi_master_cam_b_data_dst2src(axi_master_cam_b_data_dst2src),
    .axi_master_cam_b_wr_ptr_gray_dst2src(axi_master_cam_b_wr_ptr_gray_dst2src),
    .axi_master_cam_r_data_dst2src(axi_master_cam_r_data_dst2src),
    .axi_master_cam_r_wr_ptr_gray_dst2src(axi_master_cam_r_wr_ptr_gray_dst2src),
    .axi_master_cam_w_rd_data_ptr_dst2src(axi_master_cam_w_rd_data_ptr_dst2src),
    .axi_master_cam_w_rd_ptr_gray_dst2src(axi_master_cam_w_rd_ptr_gray_dst2src),
    .axi_master_cam_ar_data_src2dst(axi_master_cam_ar_data_src2dst),
    .axi_master_cam_ar_wr_ptr_gray_src2dst(axi_master_cam_ar_wr_ptr_gray_src2dst),
    .axi_master_cam_aw_data_src2dst(axi_master_cam_aw_data_src2dst),
    .axi_master_cam_aw_wr_ptr_gray_src2dst(axi_master_cam_aw_wr_ptr_gray_src2dst),
    .axi_master_cam_b_rd_data_ptr_src2dst(axi_master_cam_b_rd_data_ptr_src2dst),
    .axi_master_cam_b_rd_ptr_gray_src2dst(axi_master_cam_b_rd_ptr_gray_src2dst),
    .axi_master_cam_r_rd_data_ptr_src2dst(axi_master_cam_r_rd_data_ptr_src2dst),
    .axi_master_cam_r_rd_ptr_gray_src2dst(axi_master_cam_r_rd_ptr_gray_src2dst),
    .axi_master_cam_w_data_src2dst(axi_master_cam_w_data_src2dst),
    .axi_master_cam_w_wr_ptr_gray_src2dst(axi_master_cam_w_wr_ptr_gray_src2dst),

    // Interface: axi_slave
    .axi_slave_cam_ar_data_src2dst(axi_slave_cam_ar_data_src2dst),
    .axi_slave_cam_ar_wr_ptr_gray_src2dst(axi_slave_cam_ar_wr_ptr_gray_src2dst),
    .axi_slave_cam_aw_data_src2dst(axi_slave_cam_aw_data_src2dst),
    .axi_slave_cam_aw_wr_ptr_gray_src2dst(axi_slave_cam_aw_wr_ptr_gray_src2dst),
    .axi_slave_cam_b_rd_data_ptr_src2dst(axi_slave_cam_b_rd_data_ptr_src2dst),
    .axi_slave_cam_b_rd_ptr_gray_src2dst(axi_slave_cam_b_rd_ptr_gray_src2dst),
    .axi_slave_cam_r_rd_data_ptr_src2dst(axi_slave_cam_r_rd_data_ptr_src2dst),
    .axi_slave_cam_r_rd_ptr_gray_src2dst(axi_slave_cam_r_rd_ptr_gray_src2dst),
    .axi_slave_cam_w_data_src2dst(axi_slave_cam_w_data_src2dst),
    .axi_slave_cam_w_wr_ptr_gray_src2dst(axi_slave_cam_w_wr_ptr_gray_src2dst),
    .axi_slave_cam_ar_rd_data_ptr_dst2src(axi_slave_cam_ar_rd_data_ptr_dst2src),
    .axi_slave_cam_ar_rd_ptr_gray_dst2src(axi_slave_cam_ar_rd_ptr_gray_dst2src),
    .axi_slave_cam_aw_rd_data_ptr_dst2src(axi_slave_cam_aw_rd_data_ptr_dst2src),
    .axi_slave_cam_aw_rd_ptr_gray_dst2src(axi_slave_cam_aw_rd_ptr_gray_dst2src),
    .axi_slave_cam_b_data_dst2src(axi_slave_cam_b_data_dst2src),
    .axi_slave_cam_b_wr_ptr_gray_dst2src(axi_slave_cam_b_wr_ptr_gray_dst2src),
    .axi_slave_cam_r_data_dst2src(axi_slave_cam_r_data_dst2src),
    .axi_slave_cam_r_wr_ptr_gray_dst2src(axi_slave_cam_r_wr_ptr_gray_dst2src),
    .axi_slave_cam_w_rd_data_ptr_dst2src(axi_slave_cam_w_rd_data_ptr_dst2src),
    .axi_slave_cam_w_rd_ptr_gray_dst2src(axi_slave_cam_w_rd_ptr_gray_dst2src),

    // Interface: clk_ctrl
    .force_cka(force_cka),
    .force_ckb(force_ckb),
    .sel_cka(sel_cka),
    .subsys_clkena(subsys_clkena),

    // Interface: i2c_master_slave
    .scl_pad_i(),
    .sda_pad_i(),
    .scl_pad_o(),
    .scl_padoen_o(),
    .sda_pad_o(),
    .sda_padoen_o(),

    // Interface: icn_rstn
    .icn_rst_ni(reset_n_i),

    // Interface: irq_master
    .interrupt_o(i2c_intr),

    // Interface: pll_ctrl
    //.pll_ctrl_in,
    //.pll_ctrl_valid,

    // Interface: pll_status
    //.STATUS1,
    //.STATUS2,

    // Interface: ref_clk
    .refclk(ref_clk_i),

    // Interface: ref_rstn
    .refrstn(reset_n_i)
);
    assign camera_ss_wrapper_i.d_phy_top_0.rx_byte_clk_hs = csi_dphy_rx.rx_byte_clk_hs_o;
    assign camera_ss_wrapper_i.d_phy_top_0.rx_data_hs_0 = csi_dphy_rx.rx_data_hs_o[0];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_data_hs_1 = csi_dphy_rx.rx_data_hs_o[1];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_data_hs_2 = csi_dphy_rx.rx_data_hs_o[2];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_data_hs_3 = csi_dphy_rx.rx_data_hs_o[3];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_valid_hs_0 = csi_dphy_rx.rx_valid_hs_o[0];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_valid_hs_1 = csi_dphy_rx.rx_valid_hs_o[1];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_valid_hs_2 = csi_dphy_rx.rx_valid_hs_o[2];
    assign camera_ss_wrapper_i.d_phy_top_0.rx_valid_hs_3 = csi_dphy_rx.rx_valid_hs_o[3];
    assign camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.err_sot_hs =1'b0;
    assign camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.err_sot_sync_hs =1'b0;

    /*************
    *  DRIVER  *
    *************/
    initial begin
        master_drv.reset_master();
    end
    //TODO: Replace with a driver
    // Register Sanity Test
    `ifdef REG_SANITY_TEST
        initial begin
            $display("num=%b", `ASSIGN_RO_REGS);
            //$display("num=%b", `MAX_ADDR_W'b1111<<int'(`REG_ADDR("CSR")));
            @(posedge reset_n_i);
            for(int i=0; i<10; i++) begin
                if(i==6)
                    $display("RO reg");
                else begin
                    axi_write_mst(i*4, 32'hFFFF_FFFF, 8'hF, 1'b1);
                    axi_read_mst(i*4, tmp_axi_data, 1'b1);
                    wait(tmp_axi_data!=0);
                    if (tmp_axi_data ==  32'hFFFF_FFFF) begin
                        $display("[ok]");
                        tmp_axi_data = 0;
                    end
                    else $display("[not ok]");
                end
            end
            $display("active_lanes_reg = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.active_lanes_reg);
            $display("vc_id_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.vc_id_reg);
            $display("data_type_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.data_type_reg);
            $display("pixel_per_clk_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.pixel_per_clk_reg);
            $display("bayer_filter_type_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.bayer_filter_type_reg);
            $display("frame_width = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_width);
            $display("frame_height = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_height);
            $display("frame_ptr0 = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_ptr0);
            $display("frame_ptr1 = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_ptr1);
            $display("csi_enable = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_enable);
            $finish;
        end
    `elsif PIC_TEST
        initial begin
            `ifndef FPGA
                for(int i=0; i< 256; i++) begin
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer0.MEM[i] = 0;
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer1.MEM[i] = 0;
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer0.MEM[i] = 0;
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer1.MEM[i] = 0;
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer0.MEM[i] = 0;
                    camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer1.MEM[i] = 0;
                end
            `endif
            //reset_n_i = 1;
            //#200
            //reset_n_i = 0;
            //#200
            //reset_n_i = 1;
            eos=1'b0;
            read_file = $fopen("../src/tb/img_in/img_bayer_3840x2160_RGGB_08bits.raw","rb");
            //csi_dphy_rx.read_file_i = read_file;
            csi_dphy_rx.reset_outputs();
            @(posedge reset_n_i);
            // Configure CSI
            axi_write_mst(`REG_ADDR_OFFSET("FPR0"), PTR0_ADDR, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("FPR1"), PTR3_ADDR, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("FWR"), IMG_WIDTH, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("FHR"), IMG_LENGTH, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("ICR"), {vc_id_reg_i[3], vc_id_reg_i[2], vc_id_reg_i[1], vc_id_reg_i[0], data_type_reg_i[3], data_type_reg_i[2], data_type_reg_i[1], data_type_reg_i[0]}, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("PCR"), {3'd2, 3'd2, 3'd2, 3'd2, bayer_filer_type[3], bayer_filer_type[2], bayer_filer_type[1], bayer_filer_type[0], 4'd4}, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("CCR"), 32'b0101, 8'hF, 1'b1);
            // verify that they have been written correctly by viewing them
            $display("active_lanes_reg = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.active_lanes_reg);
            $display("vc_id_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.vc_id_reg);
            $display("data_type_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.data_type_reg);
            $display("pixel_per_clk_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.pixel_per_clk_reg);
            $display("bayer_filter_type_reg = %p", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.bayer_filter_type_reg);
            $display("frame_width = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_width);
            $display("frame_height = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_height);
            $display("frame_ptr0 = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_ptr0);
            $display("frame_ptr1 = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.frame_ptr1);
            $display("csi_enable = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_enable);
            $display("output_select = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.output_select);
            $display("dual_buffer_en = %b", camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.double_buff_enable_reg);
            //camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.csi_enable = 1'b1;{sim:/tb_top_camera_axi/camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i/isp_pipeline_i/isp_gen[0]/flow_control_i/dst_clear_pending_o} 
            wait(!camera_ss_wrapper_i.camera_processor_0.mipi_camera_processor_i.isp_pipeline_i.isp_gen[0].flow_control_i.dst_clear_pending_o);
            csi_dphy_rx.send_frame(0,0, read_file);
            // wait for 3 lines
            //wait(frame_wr_done_intr_o);
            for(int i=0; i<3*IMG_WIDTH; i++)
               csi_dphy_rx.clock();
            //axi_write_mst(`REG_ADDR("FPR0")+'h8000, PTR3_ADDR, 8'hF, 1'b1);
            axi_write_mst(`REG_ADDR_OFFSET("FPR0"), PTR3_ADDR, 8'hF, 1'b1);
            csi_dphy_rx.send_frame(0,0, read_file);
            // wait for 3 lines
            for(int i=0; i<3*IMG_WIDTH; i++)
                csi_dphy_rx.clock();
            $fclose(read_file);
            eos=1'b1;
        end
    `endif
 
    initial begin
        slave_drv.reset();
        @(posedge sdram_reset_n_i);
        slave_drv.run();
    end

    // compare the frames
    integer output_file_h, golden_file_h;

    initial begin : proc_monitor
        static tb_axi_csirx_pkg::axi_csirx_monitor #(
        .AxiAddrWidth       (AXIM_ADDR_WIDTH       ),
        .AxiSlvPortDataWidth(AXIM_DATA_WIDTH       ),
        .AxiIdWidth         (AXIM_ID_WIDTH         ),
        .AxiUserWidth       (AXIM_USER_WIDTH       ),
        .TimeTest           (SDRAM_PERIOD           )
        ) monitor = new (slave_dv);
        fork
        monitor.run(PTR0_ADDR, PTR1_ADDR, PTR2_ADDR, PTR3_ADDR, PTR4_ADDR, PTR5_ADDR);
        forever begin
            #SDRAM_PERIOD;
            if(eos) begin
                monitor.empty_queues();
                monitor.print_result();
                //output_file_h = $fopen("../src/tb/img_out/output_file.yuv","rb");
                //golden_file_h = $fopen("../src/tb/img_out/golden_file.yuv","rb");
                monitor.file_compare();
                $fclose(output_file_h);
                $fclose(golden_file_h);
                $stop();
            end
            @(posedge sdram_clk_i);
        end
        join
    end
endmodule