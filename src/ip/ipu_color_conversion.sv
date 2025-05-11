//----------------------------------------------------------------------------
// Module: ipu_color_conversion
// Project: Reconfigurable Image Acquisition and Processing Subsystem for MPSoCs (ReImA)
// References: MIPI CSI RX to Parallel Bridge (c) by Gaurav Singh www.CircuitValley.com
// licensed under a Creative Commons Attribution 3.0 Unported License.

// You should have received a copy of the license along with this
// work.  If not, see <http://creativecommons.org/licenses/by/3.0/>.

//   Functionality: 
//   -   The module receives upto 4 rgb pixels per clock each channel 10 bit wide
// -	Programmable PPC and datatype
// -	The module implements the following formula for calculating YUV components
// 	from YUV wiki page full swing 		//* We shift by 8 to have the value within 0 to 255 (8bit) as yuv components are 8bits each
// 	 y = ((77 R + 150G + 29B + 128) >>8)
// 	 u = ((-43R - 84G + 127B + 128) >>8) + 128
// 	 v = ((127R -106G -21B + 128) >>8) + 128
// -	Each pixel on the output interface is either YU or YV
//   Authors: Mohamed Soliman <mohamed.w.soliman@tuni.fi>
// 	    Gaurav Singh www.CircuitValley.com
//----------------------------------------------------------------------------
`include "mipi_csi_data_types.svh"
module ipu_color_conversion (
  input  logic          reset_n_i,           // Active low reset
  input  logic          pixel_clk_i,         // Programmable byte clock domain
  input  logic [2:0]    pixel_per_clk_reg_i, // Programmable pixel per clock from register interface
  input  logic [5:0]    data_type_reg_i,     // Programmable data type from register interface
  input  logic          line_valid_i,
  output logic          line_valid_sync_o,
  input  logic [119:0]  rgb_data_i,          // RGB data coming from debayer filter, up to 4 RGB pixels with each channel being 10 bits wide in both RAW8 (2 MSBs are 0s) and RAW10 cases
  input  logic [3:0]    rgb_data_valid_i,
  output logic [63:0]   yuv_data_o,          // YUV data (YUYV format). If 4 PPC is selected, output is YUYV,YUYV. If 2 PPC, output is YUYV. If 1 PPC, output alternates each cycle between YU and YV
  output logic [7:0]    yuv_byte_valid_o
);

  // Parameters
  parameter int PIXEL_WIDTH = 8;
  parameter int PIXEL_WIDTH10 = 10;

  typedef struct packed{
    logic [24:0] y;
    logic [24:0] u;
    logic [24:0] v;
  } yuv_t;

  // Internal signals
  logic line_valid_q;
  logic line_valid_q2;
  logic line_valid_q3;
  logic sel_prev_v;

  yuv_t yuv_r[4]; // red channel
  yuv_t yuv_g[4]; // green channel
  yuv_t yuv_b[4]; // blue channel
  yuv_t yuv_r_p_g[4]; // red plus green
  yuv_t yuv_b_p_c[4]; // blue plus constant
  yuv_t yuv_result_q[4]; // intermediate yuv values
  yuv_t yuv_result_q2[4]; // final yuv values
  yuv_t yuv_result_q3[4]; // final yuv values delayed

  logic [1:0] datatype_offset;
  logic [3:0] rgb_data_valid_q;
  logic [3:0] rgb_data_valid_q2;
  logic [3:0] rgb_data_valid_q3;
  logic [3:0] rgb_data_valid_q4;

	// datatype offset logic used to skip the 2LSBs in rgb 10 bit channel data
	assign datatype_offset = (data_type_reg_i==`RAW10)? 2'd2: 2'd0;

	//from YUV wiki page full swing 		//* We shift by 8 to have the value within 0 to 255 (8bit) as yuv components are 8bits each
	// y = ((77 R + 150G + 29B + 128) >>8)
	// u = ((-43R - 84G + 127B + 128) >>8) + 128
	// v = ((127R -106G -21B + 128) >>8) + 128

  // RGB to YUV pipeline that calculates Y component for all pixels, and calculates UV components for the even pixels only
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      line_valid_q        <= 1'b0; 
      line_valid_q2       <= 1'b0;
      line_valid_q3       <= 1'b0;
      line_valid_sync_o   <= 1'b0;
      rgb_data_valid_q    <= 4'b0;
      rgb_data_valid_q2   <= 4'b0;
      rgb_data_valid_q3   <= 4'b0;
      rgb_data_valid_q4   <= 4'b0;
      yuv_r              <= '{default: '0};
      yuv_g              <= '{default: '0};
      yuv_b              <= '{default: '0};
      yuv_r_p_g          <= '{default: '0};
      yuv_b_p_c          <= '{default: '0};
      yuv_result_q       <= '{default: '0};
      yuv_result_q2      <= '{default: '0};
      yuv_result_q3      <= '{default: '0};      
    end else begin
      // Guard the pipeline with stall
      line_valid_q        <= line_valid_i; 
      line_valid_q2       <= line_valid_q;
      line_valid_q3       <= line_valid_q2;
      line_valid_sync_o   <= line_valid_q3;

      rgb_data_valid_q    <= rgb_data_valid_i;
      rgb_data_valid_q2   <= rgb_data_valid_q;
      rgb_data_valid_q3   <= rgb_data_valid_q2;
      rgb_data_valid_q4   <= rgb_data_valid_q3;

      for (int i = 0; i < 4; i++) begin
        // calculating the Y component for all pixels
        yuv_r[i].y         <= (25'd77 * rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + (PIXEL_WIDTH10 * 2)) + datatype_offset +: PIXEL_WIDTH]);
        yuv_g[i].y         <= (25'd150 * rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + PIXEL_WIDTH10) + datatype_offset +: PIXEL_WIDTH]);
        yuv_b[i].y         <= (25'd29 * rgb_data_i[(i * (PIXEL_WIDTH10 * 3)) + datatype_offset +: PIXEL_WIDTH]);
        
        yuv_r_p_g[i].y     <= yuv_r[i].y + yuv_g[i].y;
        yuv_b_p_c[i].y     <= yuv_b[i].y + 24'd128;
        yuv_result_q[i].y  <= (yuv_r_p_g[i].y + yuv_b_p_c[i].y) >> PIXEL_WIDTH;
        yuv_result_q2[i].y <= yuv_result_q[i].y[7:0];
      end

      for (int i = 0; i < 4; i += 2) begin
        // calculating the U component for even pixels only
        yuv_r[i].u         <= (25'd43 * rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + (PIXEL_WIDTH10 * 2)) + datatype_offset +: PIXEL_WIDTH]);
        yuv_g[i].u         <= (25'd84 * rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + PIXEL_WIDTH10) + datatype_offset +: PIXEL_WIDTH]);
        yuv_b[i].u         <= {rgb_data_i[(i * (PIXEL_WIDTH10 * 3)) + datatype_offset +: PIXEL_WIDTH], 7'b0} -
                                  rgb_data_i[(i * (PIXEL_WIDTH10 * 3)) + datatype_offset +: PIXEL_WIDTH]; // B*127 is converted to val << 7 - val to save DSP * operation
        yuv_r_p_g[i].u     <= yuv_r[i].u + yuv_g[i].u;
        yuv_b_p_c[i].u     <= yuv_b[i].u + 8'd128;
        yuv_result_q[i].u  <= (yuv_b_p_c[i].u - yuv_r_p_g[i].u) >> PIXEL_WIDTH;
        yuv_result_q2[i].u <= yuv_result_q[i].u[7:0] + 8'd128;

        // calculating the V component for even pixels only
        yuv_r[i].v         <= {rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + (PIXEL_WIDTH10 * 2)) + datatype_offset +: PIXEL_WIDTH], 7'b0} -
                                  rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + (PIXEL_WIDTH10 * 2)) + datatype_offset +: PIXEL_WIDTH];
        yuv_g[i].v         <= (25'd106 * rgb_data_i[((i * (PIXEL_WIDTH10 * 3)) + PIXEL_WIDTH10) + datatype_offset +: PIXEL_WIDTH]);
        yuv_b[i].v         <= (25'd21 * rgb_data_i[(i * (PIXEL_WIDTH10 * 3)) + datatype_offset +: PIXEL_WIDTH]);
        yuv_r_p_g[i].v     <= yuv_r[i].v + yuv_g[i].v;
        yuv_b_p_c[i].v     <= yuv_b[i].v + 8'd128;
        yuv_result_q[i].v  <= (yuv_b_p_c[i].v - yuv_r_p_g[i].v) >> PIXEL_WIDTH;
        yuv_result_q2[i].v <= yuv_result_q[i].v[7:0] + 8'd128;
      end

      yuv_result_q3 <= yuv_result_q2;
    end
  end

  assign yuv_byte_valid_o = (rgb_data_valid_q4 == 4'b1111) ? 8'b1111_1111 :
                            (rgb_data_valid_q4 == 4'b0011) ? 8'b0000_1111 :
                            (rgb_data_valid_q4 == 4'b0001) ? 8'b0000_0011 :
                                                             8'b0000_0000;
	
  // U or V selector for the first pixel logic during 1ppc
  always_ff @(posedge pixel_clk_i or negedge reset_n_i) begin
    if (!reset_n_i) begin
      sel_prev_v <= 1'b0;
    end else begin
      if ((pixel_per_clk_reg_i == 3'd1) && line_valid_sync_o) begin
        // Doesn't need reset as the minimum data size is YUYV
        sel_prev_v <= ~sel_prev_v;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < 4; i += 2) begin
      yuv_data_o[(i * 2) * 8 +: 8] = (pixel_per_clk_reg_i != 1) ? 
                                     yuv_result_q3[i].v[7:0] : 
                                     (sel_prev_v ? yuv_result_q3[i].v[7:0] : yuv_result_q2[i].u[7:0]);
      yuv_data_o[((i * 2) + 1) * 8 +: 8] = yuv_result_q2[i].y[7:0];
      yuv_data_o[((i * 2) + 2) * 8 +: 8] = yuv_result_q2[i].u[7:0];
      yuv_data_o[((i * 2) + 3) * 8 +: 8] = yuv_result_q2[i + 1].y[7:0];
    end
  end

endmodule