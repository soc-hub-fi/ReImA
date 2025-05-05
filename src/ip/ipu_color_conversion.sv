/*
    File: ipu_color_conversion.sv
    Project: Part of MIPI Camera Serial Interface Implementation
    References: MIPI CSI RX to Parallel Bridge (c) by Gaurav Singh www.CircuitValley.com
	licensed under a Creative Commons Attribution 3.0 Unported License.

	You should have received a copy of the license along with this
	work.  If not, see <http://creativecommons.org/licenses/by/3.0/>.

    Functionality: 
    -   The module receives upto 4 rgb pixels per clock each channel 10 bit wide
	-	Programmable PPC and datatype
	-	The module implements the following formula for calculating YUV components
		from YUV wiki page full swing 		//* We shift by 8 to have the value within 0 to 255 (8bit) as yuv components are 8bits each
		 y = ((77 R + 150G + 29B + 128) >>8)
		 u = ((-43R - 84G + 127B + 128) >>8) + 128
		 v = ((127R -106G -21B + 128) >>8) + 128
	-	Each pixel on the output interface is either YU or YV
    Authors: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
			Gaurav Singh www.CircuitValley.com
*/

`include "mipi_csi_data_types.svh"
module ipu_color_conversion	(
					input 						reset_n_i,				// Active low reset
					input 						pixel_clk_i, 			// Programmable byte clock domain
					input			[2:0]		pixel_per_clk_reg_i, 	// Programmable pixel per clock from register interface
					input			[5:0] 		data_type_reg_i, 		// Programmable data type from register interface
					input 						line_valid_i,
					output logic 				line_valid_sync_o,
					input 			[119:0] 	rgb_data_i, 			// RGB data coming from debayer filer upto 4 rgb pixels with each channel being 10 bits wide in both RAW8(2MSBs are 0s) and RAW10 cases
					input			[3:0]		rgb_data_valid_i,
					output logic 	[63:0]		yuv_data_o, 			// YUV data (YUYV format) if 4ppc is selected, output is YUYV,YUYV if 2pcc output is YUYV if 1ppc output alternates each cycle between YU and YV
					output logic	[7:0]		yuv_byte_valid_o		// byte valid for each byte in the data output
			 );

	parameter PIXEL_WIDTH=8;
	parameter PIXEL_WIDTH10=10;
	//integer i;
	logic line_valid_stage1;
	logic line_valid_stage2;
	logic line_valid_stage3;
	logic sel_prev_v;
	logic [7:0]y[4]; // result 8 pixesl , 8 bit per channel , ultimately 16bit per pixel 
	logic [7:0]u[4];
	logic [7:0]v[4];

	logic [7:0]v_last[4];

	logic [24:0]y_r[4]; //stores result  of  16bit input * ~8bit Const
	logic [24:0]y_g[4];
	logic [24:0]y_b[4];

	logic [24:0]u_r[4];  //calculated only for alternate pixel so 4 pixel per chunk for 16bit pipeline  while y is 8 pixel per chunk
	logic [24:0]u_g[4];
	logic [24:0]u_b[4];

	logic [24:0]v_r[4];
	logic [24:0]v_g[4];
	logic [24:0]v_b[4];


	logic [24:0]y_add[4]; //intermediate y result from pipeline  
	logic [24:0]u_add[4]; //intermediate u result from pipeline  
	logic [24:0]v_add[4]; //intermediate v result from pipeline  

	logic [24:0]y_b_stage_add[4];
	logic [24:0]u_b_stage_add[4];
	logic [24:0]v_b_stage_add[4];

	logic [24:0]y_add_stage2[4];
	logic [24:0]u_add_stage2[4];
	logic [24:0]v_add_stage2[4];
	logic [1:0] datatype_offset;
	logic [3:0] rgb_data_valid_delayed;
	logic [3:0] rgb_data_valid_delayed2;
	logic [3:0] rgb_data_valid_delayed3;
	logic [3:0] rgb_data_valid_delayed4;
	// datatype offset logic used to skip the 2LSBs in rgb 10 bit channel data
	assign datatype_offset = (data_type_reg_i==`RAW10)? 2'd2: 2'd0;

	//from YUV wiki page full swing 		//* We shift by 8 to have the value within 0 to 255 (8bit) as yuv components are 8bits each
	// y = ((77 R + 150G + 29B + 128) >>8)
	// u = ((-43R - 84G + 127B + 128) >>8) + 128
	// v = ((127R -106G -21B + 128) >>8) + 128

	// rgb2yuv pipeline that calculate y component for all pixels, and calculate UV components for the even pixels only
	always_ff @(posedge  pixel_clk_i, negedge reset_n_i) begin
		if(!reset_n_i) begin
			line_valid_stage1 		<= 0; 
			line_valid_stage2 		<= 0;
			line_valid_stage3 		<= 0;
			line_valid_sync_o 		<= 0;
			rgb_data_valid_delayed	<= 0;
			rgb_data_valid_delayed2	<= 0;
			rgb_data_valid_delayed3	<= 0;
			rgb_data_valid_delayed4	<= 0;
			for (int i=0; i<4; i++) begin
				y_r[i] 				<= 0;
				y_g[i] 				<= 0;
				y_b[i] 				<= 0;
				y_add[i] 			<= 0;
				y_b_stage_add[i] 	<= 0;
				y_add_stage2[i] 	<= 0;
				y[i] 				<= 0;
				u_r[i] 				<= 0;
				u_g[i] 				<= 0;
				u_b[i] 				<= 0;
				v_r[i] 				<= 0;
				v_g[i] 				<= 0;
				v_b[i] 				<= 0;
				u_add[i] 			<= 0;
				v_add[i] 			<= 0;
				u_b_stage_add[i] 	<= 0;
				v_b_stage_add[i] 	<= 0;
				u_add_stage2[i] 	<= 0;
				u[i] 				<= 0;
				v_add_stage2[i] 	<= 0;
				v[i] 				<= 0;
				v_last[i] 			<= 0;
			end
		end
		else begin // guard the pipeline with stall 
			line_valid_stage1 <= line_valid_i; 
			line_valid_stage2 <= line_valid_stage1;
			line_valid_stage3 <= line_valid_stage2;
			line_valid_sync_o <= line_valid_stage3;

			rgb_data_valid_delayed <= rgb_data_valid_i;
			rgb_data_valid_delayed2 <= rgb_data_valid_delayed;
			rgb_data_valid_delayed3 <= rgb_data_valid_delayed2;
			rgb_data_valid_delayed4 <= rgb_data_valid_delayed3;

			
			for (int i=0; i<4; i++) begin
				y_r[i] 				<= ( 25'd77 * rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10*2)) 	+ datatype_offset 	+: PIXEL_WIDTH]);
				y_g[i] 				<= (25'd150 * rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10  )) 	+ datatype_offset 	+: PIXEL_WIDTH]);
				y_b[i] 				<= ( 25'd29 * rgb_data_i[ (i* (PIXEL_WIDTH10*3)) 						+ datatype_offset 	+: PIXEL_WIDTH]);
				
				y_add[i] 			<= y_r[i] + y_g[i];
				y_b_stage_add[i] 	<= y_b[i] + 24'd128;
				y_add_stage2[i] 	<=  (y_add[i] + y_b_stage_add[i]) >> PIXEL_WIDTH ;
				y[i] 				<= y_add_stage2[i][7:0];
			end
			
			for (int i=0; i<4; i = i + 2) begin
				u_r[i] 				<= (25'd43 	*  	rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10*2)) + datatype_offset 		+: PIXEL_WIDTH]);
				u_g[i] 				<= (25'd84  * 	rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10  )) + datatype_offset 		+: PIXEL_WIDTH]);
				u_b[i] 				<= {			rgb_data_i[( i* (PIXEL_WIDTH10*3)) 						+ datatype_offset  		+: PIXEL_WIDTH], 7'b0} - rgb_data_i[	(i*(PIXEL_WIDTH10*3)) 						+ datatype_offset	+: PIXEL_WIDTH]; // B*127 is converted to  val << 7 - val to save dsp * operation
				v_r[i] 				<= {			rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10*2)) + datatype_offset 		+: PIXEL_WIDTH], 7'b0} - rgb_data_i[(	(i*(PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10*2)) 	+ datatype_offset 	+: PIXEL_WIDTH];
				v_g[i] 				<= (25'd106 * 	rgb_data_i[((i* (PIXEL_WIDTH10*3)) + (PIXEL_WIDTH10  )) + datatype_offset 		+: PIXEL_WIDTH]);
				v_b[i] 				<= ( 25'd21 * 	rgb_data_i[ (i* (PIXEL_WIDTH10*3)) + datatype_offset 							+: PIXEL_WIDTH]);

				u_add[i] 			<= u_r[i] + u_g[i];
				v_add[i] 			<= v_b[i] + v_g[i];
				u_b_stage_add[i] 	<= u_b[i] + 8'd128;
				v_b_stage_add[i] 	<= v_r[i] + 8'd128;
				u_add_stage2[i] 	<=  (u_b_stage_add[i] - u_add[i]) >> PIXEL_WIDTH;
				u[i] 				<= u_add_stage2[i][7:0]  + 8'd128;
				v_add_stage2[i] 	<=  (v_b_stage_add[i] - v_add[i]) >> PIXEL_WIDTH;
				v[i] 				<= v_add_stage2[i][7:0] + 8'd128;
				v_last[i] 			<= v[i];
			end
		end
	end

	assign yuv_byte_valid_o = 	(rgb_data_valid_delayed4==4'b1111)? 8'b1111_1111:
								(rgb_data_valid_delayed4==4'b11)? 8'b0000_1111:
								(rgb_data_valid_delayed4==4'b0001)? 8'b0000_0011:
								8'b0000_0000;
	
	// UorV selector for the first pixel logic during 1ppc
	always_ff@(posedge pixel_clk_i or negedge reset_n_i) begin
		if(!reset_n_i)
			sel_prev_v <= 0;
		else begin
			if(pixel_per_clk_reg_i==1 && line_valid_sync_o) // doesn't need reset as the minimum data size is yuyv
				sel_prev_v <= !sel_prev_v;
		end
	end

	// Output logic I think it should be the other way around ????????? switch y[i+1] and y[i]
	always_comb begin
		for(int i=0; i<4; i = i + 2) begin
			yuv_data_o[( (i*2)    * 8) +: 8] = (pixel_per_clk_reg_i!=1)? v[i]:(sel_prev_v)? v_last[i]: u[i] ;
			//yuv_data_o[(((i*2)+1) * 8) +: 8] = (pixel_per_clk_reg_i!=1)? y[i+1]: y[i] ;
			yuv_data_o[(((i*2)+1) * 8) +: 8] = y[i];
			yuv_data_o[(((i*2)+2) * 8) +: 8] = u[i];
			yuv_data_o[(((i*2)+3) * 8) +: 8] = y[i+1];
		end
	end
endmodule