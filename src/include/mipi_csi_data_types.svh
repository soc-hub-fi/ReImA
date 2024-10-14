// Synchronization Short Packet Data Type Codes
`define FSC             6'h00
`define FEC             6'h01
`define LSC             6'h02
`define LEC             6'h03
`define RESERVED1       6'h04
`define RESERVED2       6'h05
`define RESERVED3       6'h06
`define RESERVED4       6'h07

// Generic Short Packet Data Type Codes
`define GSPC1            6'h08
`define GSPC2            6'h09
`define GSPC3            6'h0A
`define GSPC4            6'h0B
`define GSPC5            6'h0C
`define GSPC6            6'h0D
`define GSPC7            6'h0E
`define GSPC8            6'h0F

// Generic 8-bit Long Packet Data Types
`define NULL            6'h10
`define BLANK           6'h11
`define EMB             6'h12
`define RESERVED5       6'h13
`define RESERVED6       6'h14
`define RESERVED7       6'h15
`define RESERVED8       6'h16
`define RESERVED9       6'h17

// YUV Image Data Types
`define YUV420_8        6'h18
`define YUV420_10       6'h19
`define LYUV420_8       6'h1A
`define YUV420_8_CSPS   6'h1C
`define YUV420_10_CSPS  6'h1D
`define YUV422_8        6'h1E
`define YUV422_10       6'h1F

// RGB Image Data Types
`define RGB444          6'h20
`define RGB555          6'h21
`define RGB565          6'h22
`define RGB666          6'h23
`define RGB888          6'h24
`define RESERVED10      6'h25
`define RESERVED11      6'h26
`define RESERVED12      6'h27

// RAW Image Data Types
`define RAW6            6'h28
`define RAW7            6'h29
`define RAW8            6'h2A
`define RAW10           6'h2B
`define RAW12           6'h2C
`define RAW14           6'h2D
`define RESERVED13      6'h2E
`define RESERVED14      6'h2F