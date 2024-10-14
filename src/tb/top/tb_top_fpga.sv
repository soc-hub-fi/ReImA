//`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
//`define REG_SANITY_TEST 1
`include "mipi_csi_data_types.svh"
`include "axi/assign.svh"
`include "csi_regs.svh"
module tb_top_fpga #(
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
        parameter IMG_WIDTH         = 32'd512, //3840,
        parameter IMG_LENGTH        = 32'd512, //2160,
        parameter time BYTE_PERIOD  = 40ns,
        parameter time PIXEL_PERIOD = 2ns,
        parameter time AXI_PERIOD = 10ns,
        parameter time TbApplTime   = PIXEL_PERIOD,
        parameter time TbTestTime   = 2ns
    );
    logic [31:0] IMG;
    assign IMG = 32'd512;
    parameter CSI_ADDR  = 32'hA004_0000;
    parameter PTR0_ADDR = 32'h0000_0000;
    parameter PTR1_ADDR = 32'h0000_0000 + PTR0_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR2_ADDR = 32'h0000_0000 + PTR1_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;

    parameter PTR3_ADDR = 32'h0010_0000;
    parameter PTR4_ADDR = 32'h0000_0000 + PTR3_ADDR + IMG_WIDTH * IMG_LENGTH;
    parameter PTR5_ADDR = 32'h0000_0000 + PTR4_ADDR + (IMG_WIDTH * IMG_LENGTH)/4;
    logic [ 31:0] tmp_axi_data;
    logic [1:0] rsp;
    /*********************
    *  CLOCK GENERATOR  *
    *********************/
    clk_rst_gen #(
        .ClkPeriod      (BYTE_PERIOD),
        .RstClkCycles   (5          )
    ) i_clk_rst_byte_gen (
        .clk_o          (csi_dphy_rx.clk_i ),
        .rst_no         ()
    );
    
    /*clk_rst_gen #(
        .ClkPeriod      (PIXEL_PERIOD),
        .RstClkCycles   (5          )
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
    );*/
    
    /*********
    *  AXI  *
    *********/
    //! Slave port

    AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(AXIM_ADDR_WIDTH      ),
        .AXI_DATA_WIDTH(AXIM_DATA_WIDTH      ),
        .AXI_ID_WIDTH  (AXIM_ID_WIDTH        ),
        .AXI_USER_WIDTH(AXIM_USER_WIDTH      )
    ) slave_dv (
        .clk_i(tb_top_fpga.design_1_wrapper_i.design_1_i.clk_wiz_0.clk_out2)
    );
    // Assign AXIM slave
    assign slave_dv.aw_id      = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awid;
    assign slave_dv.aw_burst   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awburst;
    assign slave_dv.aw_size    = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awsize;
    assign slave_dv.aw_addr    = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awaddr;
    assign slave_dv.aw_len     = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awlen;
    assign slave_dv.aw_cache   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awcache;
    assign slave_dv.aw_valid   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_awvalid;
    assign slave_dv.aw_ready   = tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.saxigp3_awready;

    assign slave_dv.w_data   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_wdata;
    assign slave_dv.w_strb   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_wstrb;
    assign slave_dv.w_last   = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_wlast;
    assign slave_dv.w_valid  = tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.m_axi_wdata;
    assign slave_dv.w_ready  = tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.saxigp3_wready;

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
    if_csi_dphy_rx_model #(
                            .MIPI_GEAR(8), 
                            .MIPI_LANES(4), 
                            .WIDTH(IMG_WIDTH), 
                            .LENGTH(IMG_LENGTH), 
                            .DATATYPE("RAW10"), 
                            .INPUT("LINE")
                        ) 
                csi_dphy_rx(); // change this when chaning the image

    /*********
    *  DUT  *
    *********/
    design_1_wrapper design_1_wrapper_i
   (
    .IIC_0_scl_io               (),
    .IIC_0_sda_io               (),
    .push_button_4bits_tri_i    (0),
    .rx_byte_clk_hs_0           (csi_dphy_rx.rx_byte_clk_hs_o),
    .rx_data_hs0_0              (csi_dphy_rx.rx_data_hs_o[0]),
    .rx_data_hs1_0              (csi_dphy_rx.rx_data_hs_o[1]),
    .rx_data_hs2_0              (csi_dphy_rx.rx_data_hs_o[2]),
    .rx_data_hs3_0              (csi_dphy_rx.rx_data_hs_o[3]),
    .rx_valid_hs0_0             (csi_dphy_rx.rx_valid_hs_o[0]),
    .rx_valid_hs1_0             (csi_dphy_rx.rx_valid_hs_o[1]),
    .rx_valid_hs2_0             (csi_dphy_rx.rx_valid_hs_o[2]),
    .rx_valid_hs3_0             (csi_dphy_rx.rx_valid_hs_o[3]),
    .sensor_gpio_flash          (),
    .sensor_gpio_rst            (),
    .sensor_gpio_spi_cs_n       ()
    );
    /*************
    *  DRIVER  *
    *************/
    /*initial begin
        master_drv.reset_master();
    end*/
    //TODO: Replace with a driver
    // Register Sanity Test
    initial begin
        $display("Anything");
        eos=1'b0;
        read_file = $fopen("../src/tb/img_in/img_bayer_3840x2160_RGGB_08bits.raw","rb");
        csi_dphy_rx.reset_outputs();
        force tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.emio_gpio_o = 95'd0;
        #20000;
        force tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.emio_gpio_o = 95'hFFFFFFF;
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        #20000;
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b0);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(4'hF);
        #4000000;
        //minimum 16 clock pulse width delay
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.por_srstb_reset(1'b1);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.fpga_soft_reset(4'h0);
        @(posedge tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.axi_reset_n_i);
        #4000000;
        $display("Anything");
        // Configure CSI
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0014,  8'd4, PTR0_ADDR, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0018,  8'd4, PTR3_ADDR, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_000C,  8'd4, IMG, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0010,  8'd4, IMG, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0008,  8'd4, {vc_id_reg_i[3], vc_id_reg_i[2], vc_id_reg_i[1], vc_id_reg_i[0], data_type_reg_i[3], data_type_reg_i[2], data_type_reg_i[1], data_type_reg_i[0]}, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0004,  8'd4, {3'd2, 3'd2, 3'd2, 3'd2, bayer_filer_type[3], bayer_filer_type[2], bayer_filer_type[1], bayer_filer_type[0], 4'd4}, rsp);
        tb_top_fpga.design_1_wrapper_i.design_1_i.zynq_ultra_ps_e_0.inst.write_data( 32'hA004_0000,  8'd4, 32'b1101, rsp);
        // verify that they have been written correctly by viewing them
        $display("active_lanes_reg = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.active_lanes_reg);
        $display("vc_id_reg = %p", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.vc_id_reg);
        $display("data_type_reg = %p", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.data_type_reg);
        $display("pixel_per_clk_reg = %p", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.pixel_per_clk_reg);
        $display("bayer_filter_type_reg = %p", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.bayer_filter_type_reg);
        $display("frame_width = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_width);
        $display("frame_height = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_height);
        $display("frame_ptr0 = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr0);
        $display("frame_ptr1 = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.frame_ptr1);
        $display("csi_enable = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.csi_enable);
        $display("output_select = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.output_select);
        $display("dual_buffer_en = %b", tb_top_fpga.design_1_wrapper_i.design_1_i.top_csi_fpga_wrapper_0.inst.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_fpga_i.double_buff_enable_reg);
        //top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_i.csi_enable = 1'b1;
        csi_dphy_rx.send_frame(1,0,read_file);
        // wait for 3 lines
        for(int i=0; i<3*IMG_WIDTH; i++)
            csi_dphy_rx.clock();
        csi_dphy_rx.send_frame(2,0,read_file);
        // wait for 3 lines
        for(int i=0; i<3*IMG_WIDTH; i++)
            csi_dphy_rx.clock();
        $fclose(read_file);
        eos=1'b1;
    end
 
    /*initial begin
        slave_drv.reset();
        @(posedge top_csi_fpga_wrapper_v_i.top_csi_fpga_wrapper_sv_i.mipi_camera_processor_i.byte_reset_n_sync);
        slave_drv.run();
    end*/

    /*************
    *  MONITOR  *
    *************/

    initial begin : proc_monitor
        static tb_axi_csirx_pkg::axi_csirx_monitor #(
        .AxiAddrWidth       (AXIM_ADDR_WIDTH       ),
        .AxiSlvPortDataWidth(AXIM_DATA_WIDTH       ),
        .AxiIdWidth         (AXIM_ID_WIDTH         ),
        .AxiUserWidth       (AXIM_USER_WIDTH       ),
        .TimeTest           (TbTestTime            )
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
            @(posedge tb_top_fpga.design_1_wrapper_i.design_1_i.clk_wiz_0.clk_out2); // pixel clock
        end
        join
    end
endmodule