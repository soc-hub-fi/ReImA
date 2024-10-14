//`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
//`define REG_SANITY_TEST 1
`include "mipi_csi_data_types.svh"
`include "assign.svh"
`include "csi_regs.svh"
module tb_top_camera_axi_fpga #(
        // AXI paramters
        parameter AXIM_ID_WIDTH      = 1,
        parameter AXIM_ADDR_WIDTH    = 32,
        parameter AXIM_DATA_WIDTH    = 32,
        parameter AXIM_USER_WIDTH    = 1,
        parameter AXIS_ID_WIDTH      = 1,
        parameter AXIS_ADDR_WIDTH    = 32,
        parameter AXIS_DATA_WIDTH    = 32,
        parameter AXIS_USER_WIDTH    = 1,
        // TB parameters
        parameter IMG_WIDTH         = 3840,
        parameter IMG_LENGTH        = 2160,
        parameter time BYTE_PERIOD  = 5.555ns,
        parameter time PIXEL_PERIOD = 3.333ns,
        parameter time AXI_PERIOD = 10ns,
        parameter time TbApplTime   = PIXEL_PERIOD,
        parameter time TbTestTime   = 2ns
    );
    parameter PTR0_ADDR = 32'h0000_0000;
    parameter PTR1_ADDR = 32'h0000_0000 + PTR0_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR2_ADDR = 32'h0000_0000 + PTR1_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;

    parameter PTR3_ADDR = 32'h0010_0000;
    parameter PTR4_ADDR = 32'h0000_0000 + PTR3_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR5_ADDR = 32'h0000_0000 + PTR4_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;
    logic [ 31:0] tmp_axi_data;
    logic           reset_n_i;

    /*********************
    *  CLOCK GENERATOR  *
    *********************/
    clk_rst_gen #(
        .ClkPeriod      (BYTE_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_byte_gen (
        .clk_o          (csi_dphy_rx.clk_i),
        .rst_no         (reset_n_i)
    );
    
    clk_rst_gen #(
        .ClkPeriod      (PIXEL_PERIOD),
        .RstClkCycles   (5           )
    ) i_clk_rst_pixel_gen (
        .clk_o          (pixel_clk_i ),
        .rst_no         ()
    );
    clk_rst_gen #(
        .ClkPeriod      (AXI_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_axi_gen (
        .clk_o          (axi_clk_i),
        .rst_no         (axi_reset_n_i)
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
        .clk_i(pixel_clk_i)
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
        .TA(TbApplTime          ),
        .TT(TbTestTime          ),
        .RESP_MAX_WAIT_CYCLES(0)
    ) slave_drv = new (slave_dv);

    `AXI_ASSIGN(slave_dv, slave)

    // Master port
    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AXIS_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXIS_DATA_WIDTH    ),
        .AXI_USER_WIDTH ( AXIS_USER_WIDTH    ),
        .AXI_ID_WIDTH   ( AXIS_ID_WIDTH      )
    ) axi_mst_dv ( axi_clk_i );

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
        .TA(TbApplTime          ),
        .TT(TbTestTime          )
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
    logic    [31:0] yuv_pixels;

    /*************
    *  DRIVERS  *
    *************/
    //if_csi_dphy_rx_model #(
    //                        .CLOCK_PERIOD(BYTE_PERIOD),
    //                        .MIPI_GEAR(8), 
    //                        .MIPI_LANES(4), 
    //                        .WIDTH(IMG_WIDTH), 
    //                        .LENGTH(IMG_LENGTH), 
    //                        .DATATYPE("RAW10"), 
    //                        .INPUT("BLANK")
    //                    ) 
    //            csi_dphy_rx(); // change this when chaning the image
    if_csi_dphy_rx_model_old #(
                    .MIPI_GEAR(8), 
                    .MIPI_LANES(4), 
                    .WIDTH(IMG_WIDTH), 
                    .LENGTH(IMG_LENGTH), 
                    .DATATYPE("RAW10"), 
                    .INPUT("IMG")
                ) 
        csi_dphy_rx(); // change this when chaning the image

    /*********
    *  DUT  *
    *********/
    top_csi_fpga_wrapper_v top_csi_fpga_wrapper_v_i(
                            .reset_n_i          (reset_n_i),
                            .pixel_clk_i        (pixel_clk_i),
                            .AXIS_ARESETN      (axi_reset_n_i),
                            .AXIS_ACLK          (axi_clk_i),
                            // AXI Slave Interface
                            .s_axi_awaddr     (master.aw_addr),
                            .s_axi_awvalid    (master.aw_valid),
                            .s_axi_awready    (master.aw_ready),

                            .s_axi_wdata      (master.w_data),
                            .s_axi_wstrb      (master.w_strb),
                            .s_axi_wvalid     (master.w_valid),
                            .s_axi_wready     (master.w_ready),

                            .s_axi_bresp      (master.b_resp),
                            .s_axi_bvalid     (master.b_valid),
                            .s_axi_bready     (master.b_ready),

                            .s_axi_araddr     (master.ar_addr),
                            .s_axi_arvalid    (master.ar_valid),
                            .s_axi_arready    (master.ar_ready),

                            .s_axi_rdata      (master.r_data),
                            .s_axi_rresp      (master.r_resp),
                            .s_axi_rvalid     (master.r_valid),
                            .s_axi_rready     (master.r_ready),

                            // AXI master interface
                            .AXIM_ACLK        (pixel_clk_i),
                            .m_axi_awid       (slave.aw_id),
                            .m_axi_awaddr     (slave.aw_addr),
                            .m_axi_awlen      (slave.aw_len),
                            .m_axi_awsize     (slave.aw_size),
                            .m_axi_awburst    (slave.aw_burst),
                            .m_axi_awlock     (slave.aw_lock),
                            .m_axi_awcache    (slave.aw_cache),
                            .m_axi_awprot     (slave.aw_prot),
                            .m_axi_awqos      (slave.aw_qos),
                            .m_axi_awregion   (slave.aw_region),
                            .m_axi_awatop     (slave.aw_atop),
                            .m_axi_awvalid    (slave.aw_valid),
                            .m_axi_awready    (slave.aw_ready),

                            .m_axi_wdata      (slave.w_data),
                            .m_axi_wstrb      (slave.w_strb),
                            .m_axi_wlast      (slave.w_last),
                            .m_axi_wvalid     (slave.w_valid),
                            .m_axi_wready     (slave.w_ready),

                            .m_axi_bid              (slave.b_id),
                            .m_axi_bresp            (slave.b_resp),
                            .m_axi_bvalid           (slave.b_valid),
                            .m_axi_bready           (slave.b_ready),

                            .m_axi_arid             (slave.ar_id),
                            .m_axi_araddr           (slave.ar_addr),
                            .m_axi_arlen            (slave.ar_len),
                            .m_axi_arsize           (slave.ar_size),
                            .m_axi_arburst          (slave.ar_burst),
                            .m_axi_arlock           (slave.ar_lock),
                            .m_axi_arcache          (slave.ar_cache),
                            .m_axi_arprot           (slave.ar_prot),
                            .m_axi_arqos            (slave.ar_qos),
                            .m_axi_arregion         (slave.ar_region),
                            .m_axi_arvalid          (slave.ar_valid),
                            .m_axi_arready          (slave.ar_ready),

                            .m_axi_rid              (slave.r_id),
                            .m_axi_rdata            (slave.r_data),
                            .m_axi_rresp            (slave.r_resp),
                            .m_axi_rlast            (slave.r_last),
                            .m_axi_rvalid           (slave.r_valid),
                            .m_axi_rready           (slave.r_ready),
                            .byte_clock_int         (byte_clock_int),
                            .rx_byte_clk_hs         (csi_dphy_rx.rx_byte_clk_hs_o),
                            .rx_valid_hs0           (csi_dphy_rx.rx_valid_hs_o[0]),
                            .rx_valid_hs1           (csi_dphy_rx.rx_valid_hs_o[1]),
                            .rx_valid_hs2           (csi_dphy_rx.rx_valid_hs_o[2]),
                            .rx_valid_hs3           (csi_dphy_rx.rx_valid_hs_o[3]),
                            .rx_data_hs0            (csi_dphy_rx.rx_data_hs_o[0]),
                            .rx_data_hs1            (csi_dphy_rx.rx_data_hs_o[1]),
                            .rx_data_hs2            (csi_dphy_rx.rx_data_hs_o[2]),
                            .rx_data_hs3            (csi_dphy_rx.rx_data_hs_o[3]),
                            .frame_wr_done_intr     (frame_wr_done_intr_o)
                    );

    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr = PTR0_ADDR;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_width = IMG_WIDTH;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_hight = IMG_LENGTH;
    ////assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr1 = PTR1_ADDR;
    ////assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr2 = PTR2_ADDR;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.output_select = 1'b1;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.rx_byte_clk_hs = csi_dphy_rx.rx_byte_clk_hs_o;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.vc_id_reg = vc_id_reg_i;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.data_type_reg = data_type_reg_i;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.active_lanes_reg = 3'd4;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.clear_frame_data = '{1'b0,1'b0,1'b0,1'b0};
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.clear_frame_sync = '{1'b0,1'b0,1'b0,1'b0};
    assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.err_sot_hs =1'b0;
    assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.err_sot_sync_hs =1'b0;
    assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.axi_lite_req.ar.prot =1'b0;
    assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.axi_lite_req.aw.prot =1'b0;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.rx_valid_hs = csi_dphy_rx.rx_valid_hs_o;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.rx_data_hs = csi_dphy_rx.rx_data_hs_o;
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.pixel_per_clk_reg ='{3'd2,3'd2,3'd2,3'd2};
    //assign top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.bayer_filter_type_reg = bayer_filer_type;
    //assign yuv422_data = top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.yuv422_data;
    //assign yuv422_byte_valid = top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.yuv422_byte_valid;

    /*************
    *  DRIVER  *
    *************/
    initial begin
        master_drv.reset_master();
    end

    initial begin
        `ifndef FPGA
            for(int i=0; i< 256; i++) begin
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer0.MEM[i] = 0;
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer1.MEM[i] = 0;
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer0.MEM[i] = 0;
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer1.MEM[i] = 0;
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer0.MEM[i] = 0;
                top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer1.MEM[i] = 0;
            end
        `endif
        eos=1'b0;
        read_file = $fopen("../src/tb/img_in/img_bayer_3840x2160_RGGB_08bits.raw","rb");
        csi_dphy_rx.reset_outputs();
        @(posedge axi_reset_n_i);
        // Configure CSI
        axi_write_mst(`REG_ADDR("FPR0"), PTR0_ADDR, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("FPR1"), PTR3_ADDR, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("FWR"), IMG_WIDTH, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("FHR"), IMG_LENGTH, 8'hF, 1'b1);
        //axi_write_mst(`REG_ADDR("CCR"), 32'b100, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("ICR"), {vc_id_reg_i[3], vc_id_reg_i[2], vc_id_reg_i[1], vc_id_reg_i[0], data_type_reg_i[3], data_type_reg_i[2], data_type_reg_i[1], data_type_reg_i[0]}, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("PCR"), {3'd2, 3'd2, 3'd2, 3'd2, bayer_filer_type[3], bayer_filer_type[2], bayer_filer_type[1], bayer_filer_type[0], 4'd4}, 8'hF, 1'b1);
        axi_write_mst(`REG_ADDR("CCR"), 32'b0101, 8'hF, 1'b1);
        // verify that they have been written correctly by viewing them
        $display("active_lanes_reg = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.active_lanes_reg);
        $display("vc_id_reg = %p", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.vc_id_reg);
        $display("data_type_reg = %p", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.data_type_reg);
        $display("pixel_per_clk_reg = %p", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.pixel_per_clk_reg);
        $display("bayer_filter_type_reg = %p", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.bayer_filter_type_reg);
        $display("frame_width = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_width);
        $display("frame_height = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_height);
        $display("frame_ptr0 = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr0);
        $display("frame_ptr1 = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr1);
        $display("csi_enable = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_enable);
        $display("output_select = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.output_select);
        $display("dual_buffer_en = %b", top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.double_buff_enable_reg);
        //top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_enable = 1'b1;
        //wait(!top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_integration_i.dphy_fifo_i.dst_clear_pending_o);
        csi_dphy_rx.send_frame(1,0,read_file);
        // wait for 3 lines
        wait(frame_wr_done_intr_o);
        for(int i=0; i<3*IMG_WIDTH; i++)
            csi_dphy_rx.clock();
        axi_write_mst(`REG_ADDR("FPR0"), PTR3_ADDR, 8'hF, 1'b1);
        csi_dphy_rx.send_frame(2,0,read_file);
        // wait for 3 lines
        for(int i=0; i<3*IMG_WIDTH; i++)
            csi_dphy_rx.clock();
        $fclose(read_file);
        eos=1'b1;
    end
 
    initial begin
        slave_drv.reset();
        @(posedge reset_n_i);
        slave_drv.run();
    end

    /*************
    *  MONITOR  *
    *************/

    initial begin : proc_monitor
        static tb_axi_csirx_pkg::axi_csirx_monitor #(
        .AxiAddrWidth       (AXIM_ADDR_WIDTH       ),
        .AxiSlvPortDataWidth(AXIM_DATA_WIDTH       ),
        .AxiIdWidth         (AXIM_ID_WIDTH         ),
        .AxiUserWidth       (AXIM_USER_WIDTH       ),
        .TimeTest           (TbTestTime           )
        ) monitor = new (slave_dv);
        fork
        monitor.run(PTR0_ADDR, PTR1_ADDR, PTR2_ADDR, PTR3_ADDR, PTR4_ADDR, PTR5_ADDR);
        forever begin
            #TbTestTime;
            if(eos) begin
                monitor.empty_queues();
                monitor.print_result();
                $stop();
            end
            @(posedge pixel_clk_i);
        end
        join
    end
endmodule