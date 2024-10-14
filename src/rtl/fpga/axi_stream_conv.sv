`define LINE    3840
`define FRAME   10022400

module axi_stream_conv(
                input               reset_n_i,
                input               clk_i,
                input        [119:0]rgb_data_i,
                input        [5:0]  rgb_data_valid_i,

                output logic [47:0] m_axis_video_TDATA,
                output logic        m_axis_video_TDEST,
                output logic        m_axis_video_TID,
                output logic [5:0]  m_axis_video_TKEEP,
                output logic        m_axis_video_TLAST, // last valid pixel of each line
                input logic         m_axis_video_TREADY,
                output logic [5:0]  m_axis_video_TSTRB,
                output logic        m_axis_video_TUSER, // first valid pixel of a frame
                output logic        m_axis_video_TVALID
);

    assign m_axis_video_TDATA = {rgb_data_i[59:52],rgb_data_i[49:42],rgb_data_i[39:32],rgb_data_i[29:22],rgb_data_i[19:12],rgb_data_i[9:2]};
    assign m_axis_video_TDEST = 1;
    assign m_axis_video_TID = 1;
    assign m_axis_video_TKEEP = (|rgb_data_valid_i)? 6'b111111:0;
    assign m_axis_video_TSTRB = (|rgb_data_valid_i)? 6'b111111:0;
    assign m_axis_video_TVALID = |rgb_data_valid_i;
    logic [11:0] pixel_line_counter;
    logic [23:0] pixel_frame_counter;

    always@(posedge clk_i or negedge reset_n_i) begin
        if(!reset_n_i) begin

        end
        else begin
            if(pixel_frame_counter == `FRAME-1)
                pixel_frame_counter <= 0;
            else if(|rgb_data_valid_i)
                pixel_frame_counter <= pixel_frame_counter + 1;

            if(pixel_line_counter == `LINE-1)
                pixel_line_counter <= 0;
            else if(|rgb_data_valid_i)
                pixel_line_counter <= pixel_line_counter + 1;
        end
    end

    assign m_axis_video_TUSER = (pixel_frame_counter==0) & (|rgb_data_valid_i); // first pixel of each frame
    assign m_axis_video_TLAST = (pixel_line_counter==`LINE-2) & (|rgb_data_valid_i);// Last pixel of each line
endmodule