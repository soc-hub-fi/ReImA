`timescale 1ns/1ns
module tb_mem_subblock();

    logic aclk;
    logic aresetn;
    logic m_axi_aclk;
    logic m_axi_aresetn;
    logic s_axi_aclk;
    logic s_axi_aresetn;

    mem_subblock_wrapper mem_subblock_wrapper_i (   
                                                .aclk           (aclk),
                                                .aresetn        (aresetn),
                                                .m_axi_aclk     (m_axi_aclk),
                                                .m_axi_aresetn  (m_axi_aresetn),
                                                .s_axi_aclk     (s_axi_aclk),
                                                .s_axi_aresetn  (s_axi_aresetn)
                                                );

    initial aclk = 0;
    always #10 aclk = ~aclk;
    assign m_axi_aclk = aclk;
    assign s_axi_aclk = aclk;
    //DO them with the same frequency
    initial begin
        aresetn = 1;
        m_axi_aresetn = 1;
        s_axi_aresetn = 1;
        #20
        aresetn = 0;
        m_axi_aresetn = 0;
        s_axi_aresetn = 0;
        #20
        aresetn = 1;
        m_axi_aresetn = 1;
        s_axi_aresetn = 1;
    end
endmodule