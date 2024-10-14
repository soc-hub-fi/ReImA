`timescale 1ns/1ns
module tb_wrapper_fpga();

    logic reset_n_i;
    logic clk_in1_n_0;
    logic clk_in1_p_0;
    logic enable_i_0;
    logic done_o_0;
    logic error_0;

    BD_wrapper BD_wrapper_i
                    (   .clk_in1_n_0,
                        .clk_in1_p_0,
                        .done_o_0,
                        .enable_i_0,
                        .error_0,
                        .reset_n_i);
    
    initial clk_in1_p_0 = 0;
    always #4 clk_in1_p_0 = ~clk_in1_p_0;

    assign clk_in1_n_0 = !clk_in1_p_0;
    initial begin
        reset_n_i = 1;
        enable_i_0 = 0;
        #8
        reset_n_i = 0;
        #8
        reset_n_i = 1;
        enable_i_0 = 1;
        wait(done_o_0);
        $finish;
    end
endmodule