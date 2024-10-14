module camera_pad_ctrl#(
    parameter PAD_CONF_WIDTH = 10
)
    (
    // I2C 2 pads
    output logic                        io_i2c_scl_in_o,
    input  logic                        io_i2c_scl_out_i,
    input  logic                        io_i2c_scl_oen_i,
    output logic                        io_i2c_sda_in_o,
    input  logic                        io_i2c_sda_out_i,
    input  logic                        io_i2c_sda_oen_i,

    output logic [PAD_CONF_WIDTH-1:0]   io_pad_i2c_sda_cfg,
    output logic                        io_pad_i2c_sda_o,
    input logic                         io_pad_i2c_sda_i,
    output logic [PAD_CONF_WIDTH-1:0]   io_pad_i2c_scl_cfg,
    output logic                        io_pad_i2c_scl_o,
    input logic                         io_pad_i2c_scl_i
);

    //pad bit definitions
    // 0 drive strength 1 drive strength 2 trigger 3 trigger 4 rate
    // 5 output en(0) 6 hold 7 pull enable 8 pd(0)/pu(1) 9 input en(1)

    assign io_pad_i2c_scl_o = io_i2c_scl_out_i;
    assign io_i2c_scl_in_o = io_pad_i2c_scl_i;
    assign io_pad_i2c_sda_o = io_i2c_sda_out_i;
    assign io_i2c_sda_in_o = io_pad_i2c_sda_i;
    always_comb 
    assign_i2c_pad_conf : begin
        io_pad_i2c_sda_cfg = 10'b10_0010_0100;
        io_pad_i2c_scl_cfg = 10'b10_0010_0100;
        io_pad_i2c_sda_cfg[5] = io_i2c_sda_oen_i;
        io_pad_i2c_sda_cfg[9] = io_i2c_sda_oen_i;
        io_pad_i2c_scl_cfg[5] = io_i2c_scl_oen_i;
        io_pad_i2c_scl_cfg[9] = io_i2c_scl_oen_i;
    end

endmodule