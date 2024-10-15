//`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
//`define REG_SANITY_TEST 1
`include "mipi_csi_data_types.svh"
`include "axi/assign.svh"
`include "csi_regs.svh"
module tb_top_camera_axi #(
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
        parameter time TbApplTime   = PIXEL_PERIOD,
        parameter time TbTestTime   = PIXEL_PERIOD
    );
    parameter PTR0_ADDR = 32'h0000_0000;
    parameter PTR1_ADDR = 32'h0000_0000 + PTR0_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR2_ADDR = 32'h0000_0000 + PTR1_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;

    parameter PTR3_ADDR = 32'h0010_0000;
    parameter PTR4_ADDR = 32'h0000_0000 + PTR3_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR5_ADDR = 32'h0000_0000 + PTR4_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;
    logic [ 31:0] tmp_axi_data;

    /*********************
    *  CLOCK GENERATOR  *
    *********************/
    logic reset_n_i;
    clk_rst_gen #(
        .ClkPeriod      (BYTE_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_byte_gen (
        .clk_o          (csi_dphy_rx.clk_i ),
        .rst_no         (reset_n_i)
    );
    
    clk_rst_gen #(
        .ClkPeriod      (PIXEL_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_pixel_gen (
        .clk_o          (pixel_clk_i ),
        .rst_no         ()
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
    ) axi_mst_dv ( pixel_clk_i );

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
    mipi_camera_processor #(
        .AXIM_ID_WIDTH(AXIM_ID_WIDTH),
        .AXIS_ID_WIDTH(AXIS_ID_WIDTH)
    )
    mipi_camera_processor_i(
                            .reset_n_i              (reset_n_i),
                            .pixel_clk_i            (pixel_clk_i),
                            .axi_reset_n_i          (reset_n_i),
                            .axi_clk_i              (pixel_clk_i),
                            // AXI Slave Interface
                            .s_axi_csi_awid_i       (master.aw_id),
                            .s_axi_csi_awaddr_i     (master.aw_addr),
                            .s_axi_csi_awlen_i      (master.aw_len),
                            .s_axi_csi_awsize_i     (master.aw_size),
                            .s_axi_csi_awburst_i    (master.aw_burst),
                            .s_axi_csi_awlock_i     (master.aw_lock),
                            .s_axi_csi_awcache_i    (master.aw_cache),
                            .s_axi_csi_awprot_i     (master.aw_prot),
                            .s_axi_csi_awqos_i      (master.aw_qos),
                            .s_axi_csi_awregion_i   (master.aw_region),
                            .s_axi_csi_awatop_i     (master.aw_atop),
                            .s_axi_csi_awuser_i     (master.aw_user),
                            .s_axi_csi_awvalid_i    (master.aw_valid),
                            .s_axi_csi_awready_o    (master.aw_ready),

                            .s_axi_csi_wdata_i      (master.w_data),
                            .s_axi_csi_wstrb_i      (master.w_strb),
                            .s_axi_csi_wlast_i      (master.w_last),
                            .s_axi_csi_wuser_i      (master.w_user),
                            .s_axi_csi_wvalid_i     (master.w_valid),
                            .s_axi_csi_wready_o     (master.w_ready),

                            .s_axi_csi_bid_o        (master.b_id),
                            .s_axi_csi_bresp_o      (master.b_resp),
                            .s_axi_csi_buser_o      (master.b_user),
                            .s_axi_csi_bvalid_o     (master.b_valid),
                            .s_axi_csi_bready_i     (master.b_ready),

                            .s_axi_csi_arid_i       (master.ar_id),
                            .s_axi_csi_araddr_i     (master.ar_addr),
                            .s_axi_csi_arlen_i      (master.ar_len),
                            .s_axi_csi_arsize_i     (master.ar_size),
                            .s_axi_csi_arburst_i    (master.ar_burst),
                            .s_axi_csi_arlock_i     (master.ar_lock),
                            .s_axi_csi_arcache_i    (master.ar_cache),
                            .s_axi_csi_arprot_i     (master.ar_prot),
                            .s_axi_csi_arqos_i      (master.ar_qos),
                            .s_axi_csi_arregion_i   (master.ar_region),
                            .s_axi_csi_aruser_i     (master.ar_user),
                            .s_axi_csi_arvalid_i    (master.ar_valid),
                            .s_axi_csi_arready_o    (master.ar_ready),

                            .s_axi_csi_rid_o        (master.r_id),
                            .s_axi_csi_rdata_o      (master.r_data),
                            .s_axi_csi_rresp_o      (master.r_resp),
                            .s_axi_csi_rlast_o      (master.r_last),
                            .s_axi_csi_ruser_o      (master.r_user),
                            .s_axi_csi_rvalid_o     (master.r_valid),
                            .s_axi_csi_rready_i     (master.r_ready),

                            // AXI master interface
                            .m_axi_csi_awid_o       (slave.aw_id),
                            .m_axi_csi_awaddr_o     (slave.aw_addr),
                            .m_axi_csi_awlen_o      (slave.aw_len),
                            .m_axi_csi_awsize_o     (slave.aw_size),
                            .m_axi_csi_awburst_o    (slave.aw_burst),
                            .m_axi_csi_awlock_o     (slave.aw_lock),
                            .m_axi_csi_awcache_o    (slave.aw_cache),
                            .m_axi_csi_awprot_o     (slave.aw_prot),
                            .m_axi_csi_awqos_o      (slave.aw_qos),
                            .m_axi_csi_awregion_o   (slave.aw_region),
                            .m_axi_csi_awatop_o     (slave.aw_atop),
                            .m_axi_csi_awuser_o     (slave.aw_user),
                            .m_axi_csi_awvalid_o    (slave.aw_valid),
                            .m_axi_csi_awready_i    (slave.aw_ready),

                            .m_axi_csi_wdata_o      (slave.w_data),
                            .m_axi_csi_wstrb_o      (slave.w_strb),
                            .m_axi_csi_wlast_o      (slave.w_last),
                            .m_axi_csi_wuser_o      (slave.w_user),
                            .m_axi_csi_wvalid_o     (slave.w_valid),
                            .m_axi_csi_wready_i     (slave.w_ready),

                            .m_axi_csi_bid_i        (slave.b_id),
                            .m_axi_csi_bresp_i      (slave.b_resp),
                            .m_axi_csi_buser_i      (slave.b_user),
                            .m_axi_csi_bvalid_i     (slave.b_valid),
                            .m_axi_csi_bready_o     (slave.b_ready),

                            .m_axi_csi_arid_o       (slave.ar_id),
                            .m_axi_csi_araddr_o     (slave.ar_addr),
                            .m_axi_csi_arlen_o      (slave.ar_len),
                            .m_axi_csi_arsize_o     (slave.ar_size),
                            .m_axi_csi_arburst_o    (slave.ar_burst),
                            .m_axi_csi_arlock_o     (slave.ar_lock),
                            .m_axi_csi_arcache_o    (slave.ar_cache),
                            .m_axi_csi_arprot_o     (slave.ar_prot),
                            .m_axi_csi_arqos_o      (slave.ar_qos),
                            .m_axi_csi_arregion_o   (slave.ar_region),
                            .m_axi_csi_aruser_o     (slave.ar_user),
                            .m_axi_csi_arvalid_o    (slave.ar_valid),
                            .m_axi_csi_arready_i    (slave.ar_ready),

                            .m_axi_csi_rid_i        (slave.r_id),
                            .m_axi_csi_rdata_i      (slave.r_data),
                            .m_axi_csi_rresp_i      (slave.r_resp),
                            .m_axi_csi_rlast_i      (slave.r_last),
                            .m_axi_csi_ruser_i      (slave.r_user),
                            .m_axi_csi_rvalid_i     (slave.r_valid),
                            .m_axi_csi_rready_o     (slave.r_ready),
                            .rx_byte_clk_hs         (csi_dphy_rx.rx_byte_clk_hs_o),
                            .rx_valid_hs            (csi_dphy_rx.rx_valid_hs_o),
                            .rx_data_hs             (csi_dphy_rx.rx_data_hs_o),
                            .frame_wr_done_intr_o   (frame_wr_done_intr_o)
                    );

    assign mipi_camera_processor_i.err_sot_hs =1'b0;
    assign mipi_camera_processor_i.err_sot_sync_hs =1'b0;
    assign yuv422_data = mipi_camera_processor_i.yuv422_data;
    assign yuv422_byte_valid = mipi_camera_processor_i.yuv422_byte_valid;

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
            @(posedge mipi_camera_processor_i.reset_n_i);
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
            $display("active_lanes_reg = %b", mipi_camera_processor_i.active_lanes_reg);
            $display("vc_id_reg = %p", mipi_camera_processor_i.vc_id_reg);
            $display("data_type_reg = %p", mipi_camera_processor_i.data_type_reg);
            $display("pixel_per_clk_reg = %p", mipi_camera_processor_i.pixel_per_clk_reg);
            $display("bayer_filter_type_reg = %p", mipi_camera_processor_i.bayer_filter_type_reg);
            $display("frame_width = %b", mipi_camera_processor_i.frame_width);
            $display("frame_height = %b", mipi_camera_processor_i.frame_height);
            $display("frame_ptr0 = %b", mipi_camera_processor_i.frame_ptr0);
            $display("frame_ptr1 = %b", mipi_camera_processor_i.frame_ptr1);
            $display("csi_enable = %b", mipi_camera_processor_i.csi_enable);
            $finish;
        end
    `elsif PIC_TEST
        initial begin
            `ifndef FPGA
                for(int i=0; i< 256; i++) begin
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer0.MEM[i] = 0;
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.y_buffer1.MEM[i] = 0;
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer0.MEM[i] = 0;
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.u_buffer1.MEM[i] = 0;
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer0.MEM[i] = 0;
                    mipi_camera_processor_i.csi_axi_master_i.yuv_mem_array_wrapper_i.v_buffer1.MEM[i] = 0;
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
            @(posedge mipi_camera_processor_i.reset_n_i);
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
            $display("active_lanes_reg = %b", mipi_camera_processor_i.active_lanes_reg);
            $display("vc_id_reg = %p", mipi_camera_processor_i.vc_id_reg);
            $display("data_type_reg = %p", mipi_camera_processor_i.data_type_reg);
            $display("pixel_per_clk_reg = %p", mipi_camera_processor_i.pixel_per_clk_reg);
            $display("bayer_filter_type_reg = %p", mipi_camera_processor_i.bayer_filter_type_reg);
            $display("frame_width = %b", mipi_camera_processor_i.frame_width);
            $display("frame_height = %b", mipi_camera_processor_i.frame_height);
            $display("frame_ptr0 = %b", mipi_camera_processor_i.frame_ptr0);
            $display("frame_ptr1 = %b", mipi_camera_processor_i.frame_ptr1);
            $display("csi_enable = %b", mipi_camera_processor_i.csi_enable);
            $display("output_select = %b", mipi_camera_processor_i.output_select);
            $display("dual_buffer_en = %b", mipi_camera_processor_i.double_buff_enable_reg);
            //mipi_camera_processor_i.csi_enable = 1'b1;{sim:/tb_top_camera_axi/mipi_camera_processor_i/isp_pipeline_i/isp_gen[0]/flow_control_i/dst_clear_pending_o} 
            wait(!mipi_camera_processor_i.isp_pipeline_i.isp_gen[0].flow_control_i.dst_clear_pending_o);
            csi_dphy_rx.send_frame(0,0, read_file);
            // wait for 3 lines
            //wait(frame_wr_done_intr_o);
            for(int i=0; i<3*IMG_WIDTH; i++)
               csi_dphy_rx.clock();
            axi_write_mst(`REG_ADDR("FPR0"), PTR3_ADDR, 8'hF, 1'b1);
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
        @(posedge reset_n_i);
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
        .TimeTest           (TbTestTime           )
        ) monitor = new (slave_dv);
        fork
        monitor.run(PTR0_ADDR, PTR1_ADDR, PTR2_ADDR, PTR3_ADDR, PTR4_ADDR, PTR5_ADDR);
        forever begin
            #TbTestTime;
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
            @(posedge pixel_clk_i);
        end
        join
    end
endmodule