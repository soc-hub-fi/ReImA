
`timescale 1ns/1ns
`define RGGB 2'b00
`define BGGR 2'b01
`define GBRG 2'b10
`define GRBG 2'b11
//`define RAW10_TEST
`define RAW8_TEST
`define PPC4
//`define PPC2
//`define PPC1
//`define TEST_IMG
`define RAW8DT            6'h2A
`define RAW10DT           6'h2B
/*
Test bench for debayering layer has 2 kinds of tests
1 full image test and 1 red line test
Functionalities to be tested are
RAW10 4 PPC
RAW10 2 PPC
RAW10 1 PPC
RAW8 4 PPC
RAW8 2 PPC
RAW8 1 PPC
*/
module tb_isp_pipeline();
	parameter PIPELINE_WIDTH=1;
	logic [383:0]	rgb_input;
	logic 			rgb_valid;
	logic 			line_valid;
	logic 			frame_sync [PIPELINE_WIDTH];
	logic 			out_clock;
	logic [31:0]	data_out;
    logic [1:0] 	bayer_filter_type [PIPELINE_WIDTH];
	logic [2:0] 	active_lanes_i;
	logic [5:0] 	data_type_i [PIPELINE_WIDTH];
	logic 			reset_n_i;
	logic 			is_raw_line_valid [PIPELINE_WIDTH];
	logic [3:0] 	byte_data_valid;
	logic [3:0] 	is_rgb_valid;
	logic [3:0] 	is_yuv_valid [PIPELINE_WIDTH];
	logic [47:0] 	byte_data;
	logic [119:0] 	rgb_data;
	logic [63:0]	yuv_data [PIPELINE_WIDTH]; 			// YUV data (YUYV format) if 4ppc is selected, output is YUYV,YUYV if 2pcc output is YUYV if 1ppc output alternates each cycle between YU and YV
	logic [63:0]	yuv_data_reg [PIPELINE_WIDTH];
	logic 			ppc1_write;
	logic 			byte_clk_i;
	logic 			pixel_clk_i;
	logic [95:0]    pixel_data;
	logic pixel_stream_stall_i [PIPELINE_WIDTH];
	logic [2:0] pixel_per_clk_reg_i [PIPELINE_WIDTH];
	logic [31:0] pixel_counter;
	// clk generation
    initial byte_clk_i = 0;
    always #20 byte_clk_i = ~byte_clk_i;

	initial pixel_clk_i = 0;
    always #1 pixel_clk_i = ~pixel_clk_i;

	isp_pipeline #(
                        .PIPELINE_WIDTH(PIPELINE_WIDTH)
                )
        isp_pipeline_i  (
                            // clocks and reset interface
                            .reset_n_i                  (   reset_n_i               ),      // Active low reset
                            .byte_clk_i                 (   byte_clk_i          	),      // Byte clock usually 1/8 of the line rate coming from the DPHY
                            .pixel_clk_i                (   pixel_clk_i             ),      // Pixel clock needs to be higher than ((line rate(Mb/s) * #of ActiveLanes) / (PPC * #of BitsPerPixel))
                            
                            // configuration register interface
                            .pixel_per_clk_reg_i        (  pixel_per_clk_reg_i      ),      // Controls the desired number of pixels per clock on the output interface (1,2 or 4)
                            .data_type_reg_i            (   data_type_i           	),      // Programmable datatype that each pipeline should process
                            .bayer_filter_type_reg_i    (   bayer_filter_type   	),      // Can be RGGB(00), BGGR(01), GBRG(10), GRBG(11)
                            
                            // stream information interface
                            .activate_stream_i          (   4'd1         			),      // Picks which ISP pipeline does the data go to
                            .pixel_stream_stall_i       (   pixel_stream_stall_i   	),      // If high data is pushed to the line buffer without being read
                            .frame_valid_i              (   frame_sync             	),      // Frame receiption is in progress signal
                            .line_valid_i               (   is_raw_line_valid      	),      // Line receiption is in progress signal
                            
                            // data interface
                            .byte_data_valid_i          (   byte_data_valid         ),      // Pixel data valid signal for each pixel in the pixel data in the byte clock domain
                            .byte_data_i                (   byte_data               ),      // Max width is 2 RGB888 pixels 2*24 = 48 these are pixels in the byte clock domain
                            .yuv_data_o                 (   yuv_data                ),      // YUV data (YUYV format) if 4ppc is selected, output is YUYV,YUYV if 2pcc output is YUYV if 1ppc output alternates each cycle between YU and YV
                            .yuv_data_valid_o           (   is_yuv_valid          	)       // YUV valid each bit corresponds to 16 bits (1 pixel) of the yuv data
                    );


	always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
		if(!reset_n_i) begin
			ppc1_write <= 0;
			yuv_data_reg[0] <= 0;
		end
		else begin
			yuv_data_reg[0] <= yuv_data[0];
			if(is_yuv_valid[0])
				ppc1_write<=!ppc1_write;
		end
	end

	task wait_byteclk_period;
		begin
		byte_data = 0;
		#40;
		#40;
		end
	endtask

	always@(posedge pixel_clk_i) begin
			if(is_yuv_valid[0]==4'b1111)
				$fwrite(write_yuv_fd, "%u", {yuv_data[0][7:0], yuv_data[0][15:8], yuv_data[0][23:16], yuv_data[0][31:24], yuv_data[0][39:32], yuv_data[0][47:40], yuv_data[0][55:48], yuv_data[0][63:56] });
			else if(is_yuv_valid[0]==4'b0011)
				$fwrite(write_yuv_fd, "%u", {yuv_data[0][7:0], yuv_data[0][15:8], yuv_data[0][23:16], yuv_data[0][31:24]});
			else if(ppc1_write)
				$fwrite(write_yuv_fd, "%u", {yuv_data[0][7:0], yuv_data[0][15:8], yuv_data_reg[0][7:0], yuv_data_reg[0][15:8]});
	end

	task sendbayer;
		input [39:0]bayer;
		begin
		byte_data = {8'd0, bayer};
		#40;
		end
	endtask



	integer i;
	integer j;
	logic even;
	integer read_fd;
	integer write_yuv_fd;

	`ifdef PPC4
		reg[31:0] read_bytes;
	`elsif PPC2
		reg[15:0] read_bytes;
	`else
		reg[7:0] read_bytes;
	`endif

	reg[39:0] send_read_bytes;

	initial begin
		pixel_stream_stall_i[0] = 1'b0;
		pixel_per_clk_reg_i[0] = 3'd1;
		`ifdef RAW8_TEST
			data_type_i[0] = `RAW8DT;
		`elsif RAW10_TEST
			data_type_i[0] = `RAW10DT;
		`endif

		byte_data_valid = 0;
		bayer_filter_type[0] = `BGGR;
		out_clock = 0;
		rgb_valid = 0;
		read_fd = $fopen("../src/tb/img_in/img_bayer_512x512_BGGR_08bits.raw","rb");
		write_yuv_fd = $fopen("../src/tb/img_out/italy.bmp768x512.raw.yuv","wb");
		
		$display("read_fd=%d",read_fd);
		
		rgb_input = 0;
		is_raw_line_valid[0] = 0;
		frame_sync[0] = 0; //active low
		reset_n_i = 0;
		wait_byteclk_period();
		
		frame_sync[0] = 1; //active low
		reset_n_i = 1;
		wait_byteclk_period();
		for (i = 0; i < 512; i = i + 1) begin
			rgb_valid = 1;
			line_valid = 1;
			is_raw_line_valid[0]  <= 1;
			#40
			#40
			`ifdef PPC4
				byte_data_valid = 6'b00_1111;
				for (j=0; j < 128; j = j + 1) begin
					$fread(read_bytes, read_fd);
					send_read_bytes=0;
					`ifdef TEST_IMG
						`ifdef RAW10_TEST
							send_read_bytes[39:30] = 	{read_bytes [0 +:8], 	2'h0};
							send_read_bytes[29:20] = 	{read_bytes [8 +:8], 	2'h0};
							send_read_bytes[19:10] = 	{read_bytes [16 +:8], 	2'h0};
							send_read_bytes[9:0]  = 	{read_bytes [24 +:8], 	2'h0};
						`elsif RAW8_TEST
							send_read_bytes[31:24] = 	read_bytes [0 +:8];
							send_read_bytes[23:16] = 	read_bytes [8 +:8];
							send_read_bytes[15:8]  = 	read_bytes [16 +:8];
							send_read_bytes[7:0]  = 	read_bytes [24 +:8];
						`endif
					`else
						if(i==1) begin //*RGRG
							`ifdef RAW10_TEST
								send_read_bytes[39:30] = 	{8'hFF, 	8'h0};
								send_read_bytes[29:20] = 	{8'h00, 	2'h0};
								send_read_bytes[19:10] = 	{8'hFF, 	2'h0};
								send_read_bytes[9:0]  = 	{8'h00, 	2'h0};
							`elsif RAW8_TEST
								send_read_bytes[31:24] = 	8'hFF;
								send_read_bytes[23:16] = 	8'h00;
								send_read_bytes[15:8] = 	8'hFF;
								send_read_bytes[7:0]  = 	8'h00;
							`endif
						end
					`endif

					sendbayer(send_read_bytes);
					
				end
			`elsif PPC2
				byte_data_valid = 6'b00_00_11;
				for (j=0; j < 256; j = j + 1) begin
					$fread(read_bytes, read_fd);
					send_read_bytes=0;
					`ifdef TEST_IMG
						`ifdef RAW10_TEST
							send_read_bytes[19:10] = 	{read_bytes [0 +:8], 	2'h0};
							send_read_bytes[9:0]  = 	{read_bytes [8 +:8], 	2'h0};
						`elsif RAW8_TEST
							send_read_bytes[15:8] = 	read_bytes [0 +:8];
							send_read_bytes[7:0] = 	read_bytes [8 +:8];
						`endif
					`else
						if(i==1) begin //*RGRG
							`ifdef RAW10_TEST
								send_read_bytes[19:10] = 	{8'hFF, 	2'h0};
								send_read_bytes[9:0]  = 	{8'h00, 	2'h0};
							`elsif RAW8_TEST
								send_read_bytes[15:8] = 	8'hFF;
								send_read_bytes[7:0]  = 	8'h00;
							`endif
						end
					`endif

					sendbayer(send_read_bytes);
					
					//$display("%h", rgb_data_reordered);	
				end
			`elsif PPC1
				byte_data_valid = 6'b00_00_01;
				for (j=0; j < 512; j = j + 1) begin
					$fread(read_bytes, read_fd);
					send_read_bytes=0;
					`ifdef TEST_IMG
						`ifdef RAW10_TEST
							send_read_bytes[9:0]  = 	{read_bytes [0 +:8], 	2'h0};
						`elsif RAW8_TEST
							send_read_bytes[7:0]  = 	read_bytes [0 +:8];
						`endif
					`else
						if(i==1) begin //*RGRG
							$display(j%2);
							`ifdef RAW10_TEST
								if(j%2==0)
									send_read_bytes[9:0]  = 	{8'h00, 	2'h0};
								else
									send_read_bytes[9:0]  = 	{8'hFF, 	2'h0};
							`elsif RAW8_TEST
								if(j%2==0)
									send_read_bytes[7:0]  = 	8'h00;
								else
									send_read_bytes[7:0]  = 	8'hFF;
							`endif
						end
					`endif
						
						sendbayer(send_read_bytes);
						
						//$display("%h", rgb_data_reordered);	
					end
			`endif
			rgb_valid = 0;	  
			line_valid = 0;
			is_raw_line_valid[0]  <= 0;
			byte_data_valid = 0;
			wait_byteclk_period();
			wait_byteclk_period();
			wait_byteclk_period();
			wait_byteclk_period();
		end
			
		frame_sync[0] = 0; //active low
		wait_byteclk_period();
		wait_byteclk_period();
		wait_byteclk_period();
		wait_byteclk_period();
		rgb_valid = 0;	  
		// send clock for 2 lines
		`ifdef PPC4
			for(i=0; i<250; i++)
				wait_byteclk_period();
		`elsif PPC2
			for(i=0; i<500; i++)
				wait_byteclk_period();
		`elsif PPC1
			for(i=0; i<1000; i++)
				wait_byteclk_period();
		`endif
		$fclose(read_fd);
		$fclose(write_yuv_fd);
		$finish;
	end
					   
endmodule