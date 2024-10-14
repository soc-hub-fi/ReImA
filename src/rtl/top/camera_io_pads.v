//-----------------------------------------------------------------------------
// File          : camera_io_pads.v
// Creation date : 06.07.2024
// Creation time : 15:59:57
// Description   : 
// Created by    : 
// Tool : Kactus2 3.10.15 64-bit
// Plugin : Verilog generator 2.4
// This file was generated based on IP-XACT component tuni.fi:flat:camera_io_pads:1.0
// whose XML file is /opt/soc/work/moh_sol/bow/bow/ips/camera-ss/ipxact/tuni.fi/flat/camera_io_pads/1.0/camera_io_pads.1.0.xml
//-----------------------------------------------------------------------------

module camera_io_pads #(
    parameter                              PAD_TYPE         = 2,
    parameter                              PAD_CONF_WIDTH   = 10
) (
    // Interface: DPHY
    inout  wire                         PAD_CLK_RX_N,
    inout  wire                         PAD_CLK_RX_P,
    inout  wire                         PAD_DATA0_RX_N,
    inout  wire                         PAD_DATA0_RX_P,
    inout  wire                         PAD_DATA1_RX_N,
    inout  wire                         PAD_DATA1_RX_P,
    inout  wire                         PAD_DATA2_RX_N,
    inout  wire                         PAD_DATA2_RX_P,
    inout  wire                         PAD_DATA3_RX_N,
    inout  wire                         PAD_DATA3_RX_P,

    // Interface: I2C_PAD
    inout  wire                         PAD_SCL,
    inout  wire                         PAD_SDA,

    // Interface: i2c_scl_gpio
    input                [PAD_CONF_WIDTH-1:0] i2c_scl_cfg,
    input                               i2c_scl_i,
    output                              i2c_scl_o,

    // Interface: i2c_sda_gpio
    input                [PAD_CONF_WIDTH-1:0] i2c_sda_cfg,
    input                               i2c_sda_i,
    output                              i2c_sda_o
);

// WARNING: EVERYTHING ON AND ABOVE THIS LINE MAY BE OVERWRITTEN BY KACTUS2!!!

tico_pad_functional_wrapper#(.PAD_TYPE(PAD_TYPE), .PAD_CONF_WIDTH(PAD_CONF_WIDTH)) i_pad_i2c_scl(.I(i2c_scl_i), .O(i2c_scl_o), .PAD(PAD_SCL), .conf_in(i2c_scl_cfg));
tico_pad_functional_wrapper#(.PAD_TYPE(PAD_TYPE), .PAD_CONF_WIDTH(PAD_CONF_WIDTH)) i_pad_i2c_sda(.I(i2c_sda_i), .O(i2c_sda_o), .PAD(PAD_SDA), .conf_in(i2c_sda_cfg));

tico_pad_analog_wrapper#() i_pad_CLK_RX_N(.AIO(PAD_CLK_RX_N));
tico_pad_analog_wrapper#() i_pad_CLK_RX_P(.AIO(PAD_CLK_RX_P));

tico_pad_analog_wrapper#() i_pad_DATA0_RX_N(.AIO(PAD_DATA0_RX_N));
tico_pad_analog_wrapper#() i_pad_DATA0_RX_P(.AIO(PAD_DATA0_RX_P));

tico_pad_analog_wrapper#() i_pad_DATA1_RX_N(.AIO(PAD_DATA1_RX_N));
tico_pad_analog_wrapper#() i_pad_DATA1_RX_P(.AIO(PAD_DATA1_RX_P));

tico_pad_analog_wrapper#() i_pad_DATA2_RX_N(.AIO(PAD_DATA2_RX_N));
tico_pad_analog_wrapper#() i_pad_DATA2_RX_P(.AIO(PAD_DATA2_RX_P));

tico_pad_analog_wrapper#() i_pad_DATA3_RX_N(.AIO(PAD_DATA3_RX_N));
tico_pad_analog_wrapper#() i_pad_DATA3_RX_P(.AIO(PAD_DATA3_RX_P));
endmodule
