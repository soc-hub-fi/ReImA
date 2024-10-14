/*
    File: tb_axi_csirx_pkg.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: MIPI CSI RX to Parallel Bridge (c) by Gaurav Singh www.CircuitValley.com
	licensed under a Creative Commons Attribution 3.0 Unported License.

    Functionality: 
    -   

    Authors: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
*/
//`timescale 1 ns / 1 ns

package tb_axi_csirx_pkg  ;
import axi_pkg::len_t     ;
import axi_pkg::burst_t   ;
import axi_pkg::size_t    ;
import axi_pkg::cache_t   ;
import axi_pkg::modifiable;

/****************
 *  BASE CLASS  *
 ****************/

    class axi_csirx_monitor #(
        parameter int unsigned AxiAddrWidth       ,
        parameter int unsigned AxiSlvPortDataWidth,
        parameter int unsigned AxiIdWidth         ,
        parameter int unsigned AxiUserWidth       ,
        // Stimuli application and test time
        parameter time TimeTest
    );

    localparam AxiSlvPortStrbWidth = AxiSlvPortDataWidth / 8;

    localparam AxiSlvPortMaxSize = $clog2(AxiSlvPortStrbWidth);

    typedef logic [AxiIdWidth-1:0] axi_id_t    ;
    typedef logic [AxiAddrWidth-1:0] axi_addr_t;

    typedef logic [AxiSlvPortDataWidth-1:0] slv_port_data_t;
    typedef logic [AxiSlvPortStrbWidth-1:0] slv_port_strb_t;

    typedef struct packed {
        axi_id_t axi_id;
        logic axi_last ;
    } exp_b_t;

    typedef struct packed {
        axi_id_t axi_id         ;
        slv_port_data_t axi_data;
        slv_port_strb_t axi_strb;
        logic axi_last          ;
    } slv_w_t;

    typedef struct packed {
        axi_id_t axi_id    ;
        axi_addr_t axi_addr;
        len_t axi_len      ;
        burst_t axi_burst  ;
        size_t axi_size    ;
        cache_t axi_cache  ;
    } ax_t;

    /**********************
    *  Helper functions  *
    **********************/

    // Returns a byte mask corresponding to the size of the AXI transaction
    function automatic axi_addr_t size_mask(axi_pkg::size_t size);
        return (axi_addr_t'(1) << size) - 1;
    endfunction

    /**
    * Returns the conversion rate between tgt_size and src_size.
    * @return ceil(num_bytes(tgt_size)/num_bytes(src_size))
    */
    function automatic int unsigned conv_ratio(axi_pkg::size_t tgt_size, axi_pkg::size_t src_size)         ;
        return (axi_pkg::num_bytes(tgt_size) + axi_pkg::num_bytes(src_size) - 1)/axi_pkg::num_bytes(src_size);
    endfunction: conv_ratio

    /************************
    *  Virtual Interfaces  *
    ************************/

    virtual AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(AxiAddrWidth       ),
        .AXI_DATA_WIDTH(AxiSlvPortDataWidth),
        .AXI_ID_WIDTH  (AxiIdWidth         ),
        .AXI_USER_WIDTH(AxiUserWidth       )
    ) slv_port_axi;

    /*****************
    *  Bookkeeping  *
    *****************/

    longint unsigned tests_expected;
    longint unsigned tests_conducted;
    longint unsigned tests_failed;
    semaphore        cnt_sem;
    bit              data_pulled;
    bit              addr_pulled;
    bit              select=1;
    ax_t             aw;
    int              num_of_pixels;
    bit              end_flag;
    logic [23:0]     concat24_data;
    logic [15:0]     concat16_data;
    logic [7:0]      concat8_data;
    // Queues and FIFOs to hold the expected AXIDs

    // Write transactions
    ax_t     slv_port_aw_queue [$];
    slv_w_t slv_port_w_queue [$];
    slv_w_t y_channel_queue0[$];
    slv_w_t u_channel_queue0[$];
    slv_w_t v_channel_queue0[$];
    slv_w_t y_channel_queue1[$];
    slv_w_t u_channel_queue1[$];
    slv_w_t v_channel_queue1[$];

    // Read transactions

    // output files
    integer write_yuv_file;
    /*****************
    *  Constructor  *
    *****************/

    function new (
        virtual AXI_BUS_DV #(
            .AXI_ADDR_WIDTH(AxiAddrWidth       ),
            .AXI_DATA_WIDTH(AxiSlvPortDataWidth),
            .AXI_ID_WIDTH  (AxiIdWidth         ),
            .AXI_USER_WIDTH(AxiUserWidth       )
        ) slv_port_vif
        );
        begin
        this.write_yuv_file = $fopen("../src/tb/img_out/output_file.yuv","wb");
        this.slv_port_axi          = slv_port_vif;
        this.tests_expected        = 0           ;
        this.tests_conducted       = 0           ;
        this.tests_failed          = 0           ;
        this.data_pulled           = 1           ;
        this.addr_pulled           = 0           ;
        this.num_of_pixels         = 0           ;
        this.cnt_sem               = new(1)      ;
        this.end_flag              = 0           ;
        end
    endfunction

    task cycle_start;
        #TimeTest;
    endtask: cycle_start

    task cycle_end;
        @(posedge slv_port_axi.clk_i);
    endtask: cycle_end

    /**************
    *  Monitors  *
    **************/

    /*
    * You need to override this task. Use it to push the expected AW requests on
    * the slave side, and the B and R responses expected on the master side.
    */
    virtual task automatic mon_slv_port_aw ()    ;
        $error("This task needs to be overridden.");
    endtask : mon_slv_port_aw

    /*
    * You need to override this task. Use it to push the expected W requests on
    * the slave side.
    */
    virtual task automatic mon_slv_port_w ()     ;
        $error("This task needs to be overridden.");
    endtask : mon_slv_port_w

    /*
    * You need to override this task. Use it to push the expected W requests on
    * the slave side.
    */
    virtual task automatic mon_port_req (input logic [31:0] addr_ptr0, input logic [31:0] addr_ptr1, input logic [31:0] addr_ptr2, input logic [31:0] addr_ptr3, input logic [31:0] addr_ptr4, input logic [31:0] addr_ptr5);
        if (slv_port_aw_queue.size()!=0 || this.addr_pulled==1) begin
            if(this.data_pulled) begin
                this.aw = slv_port_aw_queue.pop_front();
                this.addr_pulled = 1;
                this.data_pulled = 0;
                if(this.aw.axi_addr==addr_ptr0)
                    this.select = 0;
                else if(this.aw.axi_addr==addr_ptr3)
                    this.select = 1;
            end

            if(this.end_flag) begin
                this.end_flag = 0; 
                if(slv_port_w_queue.size() > 1)
                    $fatal("Error first wqueuesize = %d", slv_port_w_queue.size());       
            end
            
            if((this.aw.axi_len+1 == slv_port_w_queue.size())) begin
                this.end_flag = 1;
            end

            // Wait untill write queue is filled with the required length
            if(slv_port_w_queue.size()==(this.aw.axi_len+1)) begin
                // Pop W transactions based on AW length
                while(slv_port_w_queue.size()!=0) begin
                    if(this.select==0) begin
                        if (this.aw.axi_addr < addr_ptr1) begin
                            y_channel_queue0.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                        else if (this.aw.axi_addr < addr_ptr2) begin
                            u_channel_queue0.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                        else begin
                            v_channel_queue0.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                    end
                    else if(this.select==1) begin
                        if (this.aw.axi_addr < addr_ptr4) begin
                            y_channel_queue1.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                        else if (this.aw.axi_addr < addr_ptr5) begin
                            u_channel_queue1.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                        else begin
                            v_channel_queue1.push_back(slv_port_w_queue.pop_front());
                            if(slv_port_w_queue.size()==0) begin
                            end
                        end
                    end
                end
                this.data_pulled = 1;
                this.addr_pulled = 0;
            end
        end
    endtask : mon_port_req

    task empty_queues();
        slv_w_t write_b;
        $display("y_channel_queue0.size = %d", y_channel_queue0.size());
        $display("u_channel_queue0.size = %d", u_channel_queue0.size());
        $display("v_channel_queue0.size = %d", v_channel_queue0.size());
        $display("y_channel_queue1.size = %d", y_channel_queue1.size());
        $display("u_channel_queue1.size = %d", u_channel_queue1.size());
        $display("v_channel_queue1.size = %d", v_channel_queue1.size());
        $display("total number of pixels = %d", num_of_pixels);

        while (y_channel_queue0.size()!=0) begin
            //$display("data_written");
            write_b = y_channel_queue0.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end
        while (u_channel_queue0.size()!=0) begin
            write_b = u_channel_queue0.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end
        while (v_channel_queue0.size()!=0) begin
            write_b = v_channel_queue0.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end

        while (y_channel_queue1.size()!=0) begin
            //$display("data_written");
            write_b = y_channel_queue1.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end
        while (u_channel_queue1.size()!=0) begin
            write_b = u_channel_queue1.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end
        while (v_channel_queue1.size()!=0) begin
            write_b = v_channel_queue1.pop_front();
            concat24_data = write_b.axi_data[23:0];
            concat16_data = write_b.axi_data[15:0];
            concat8_data = write_b.axi_data[7:0];
            if(write_b.axi_strb==4'b1111)
                $fwrite(write_yuv_file, "%u", write_b.axi_data[31:0]);
            else if(write_b.axi_strb==4'b0111)
                $fwrite(write_yuv_file, "%u", concat24_data);
            else if(write_b.axi_strb==4'b0011)
                $fwrite(write_yuv_file, "%u", concat16_data);
            else if(write_b.axi_strb==4'b0001)
                $fwrite(write_yuv_file, "%u", concat8_data);
        end
    endtask

    /*
    * This tasks stores the beats seen by the AW and W channels
    * into the respective queues.
    */
    virtual task automatic store_channels ();
        if (slv_port_axi.aw_valid && slv_port_axi.aw_ready) begin
            //$display("Debug") ;
            slv_port_aw_queue.push_back('{
                axi_id   : slv_port_axi.aw_id   ,
                axi_burst: slv_port_axi.aw_burst,
                axi_size : slv_port_axi.aw_size ,
                axi_addr : slv_port_axi.aw_addr ,
                axi_len  : slv_port_axi.aw_len  ,
                axi_cache: slv_port_axi.aw_cache
                });
        end

        if (slv_port_axi.w_valid && slv_port_axi.w_ready) begin
            this.num_of_pixels += 1;
            //$display("time=%t ,queue size = %d",$time(), slv_port_w_queue.size());
            this.slv_port_w_queue.push_back('{
                axi_id  : {AxiIdWidth{1'b?}} ,
                axi_data: slv_port_axi.w_data,
                axi_strb: slv_port_axi.w_strb,
                axi_last: slv_port_axi.w_last
                });
        end
    endtask


    // Some tasks to manage bookkeeping of the tests conducted.
    task incr_expected_tests(input int unsigned times);
        cnt_sem.get()               ;
        this.tests_expected += times;
        cnt_sem.put()               ;
    endtask : incr_expected_tests

    task incr_conducted_tests(input int unsigned times);
        cnt_sem.get()                ;
        this.tests_conducted += times;
        cnt_sem.put()                ;
    endtask : incr_conducted_tests

    task incr_failed_tests(input int unsigned times);
        cnt_sem.get()             ;
        this.tests_failed += times;
        cnt_sem.put()             ;
    endtask : incr_failed_tests

    /*
    * This task invokes the various monitoring tasks. First, all processes that only
    * push something in the FIFOs are invoked. After they are finished, the processes
    * that pop something from them are invoked.
    */
    task run(input int addr_ptr0, input int addr_ptr1, input int addr_ptr2, input int addr_ptr3, input int addr_ptr4, input int addr_ptr5);
        forever begin
        // At every cycle, spawn some monitoring processes.
        cycle_start();

        // Execute all processes that push something into the queues
        //PushMon: fork
            proc_store_channel: store_channels() ;
        //join: PushMon

        // These only pop something from the queues
        //PopMon: fork
            proc_monitor_request: mon_port_req(addr_ptr0, addr_ptr1, addr_ptr2, addr_ptr3, addr_ptr4, addr_ptr5);
        //join : PopMon


        cycle_end();
        end
    endtask : run

    task file_compare();
        // File handles
        integer output_file_h;
        integer golden_file_h;
        integer status1, status2;
        integer line_num;
        logic ok=1;
        reg [3840*8-1:0] line1, line2;  // Registers to store each line of the file

        // Open the files
        output_file_h = $fopen("../src/tb/img_out/output_file.yuv", "r");
        golden_file_h = $fopen("../src/tb/img_out/golden_file.yuv", "r");
        $display("Comparing files.....");

        if (output_file_h == 0 || golden_file_h == 0) begin
        $display("Error: One or both files could not be opened.");
        $finish;
        end

        line_num = 1;
        status1 = $fgets(line1, output_file_h);
        status2 = $fgets(line2, golden_file_h);
        $display("status is %h", status2);

        while (! $feof(golden_file_h)) begin
            $display(status1);
        // Compare lines
        if (line1 != line2) begin
            $display("Difference found at line %d:", line_num);
            //$display("output_file_h: %h", line1);
            //$display("golden_file_h: %h", line2);
            ok=0;
        end

        // Read next lines
        status1 = $fgets(line1, output_file_h);
        status2 = $fgets(line2, golden_file_h);
        line_num = line_num + 1;
        end

        if (ok) $display("[ok]");
        else $display("[not ok]");

        // Close the files
        $fclose(output_file_h);
        $fclose(golden_file_h);

        $display("File comparison completed.");
        $finish;
    endtask

    task print_result()                                    ;
        $info("Simulation has ended!")                       ;
        $display("Tests Expected:  %d", this.tests_expected) ;
        $display("Tests Conducted: %d", this.tests_conducted);
        $display("Tests Failed:    %d", this.tests_failed)   ;
        if (tests_failed > 0) begin
        $error("Simulation encountered unexpected transactions!");
        end
    endtask : print_result

    endclass : axi_csirx_monitor
endpackage