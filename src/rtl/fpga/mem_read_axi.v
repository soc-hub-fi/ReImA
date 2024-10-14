module mem_read 
    #(  parameter                       DATA_WIDTH=256, 
        parameter                       ADDR_WIDTH=32,
        parameter                       ID_WIDTH = 1,
        parameter                       ARUSER_WIDTH = 0,
        parameter                       RUSER_WIDTH = 0
        ) 
    (   input                           reset_n_i,
        input                           clk_i,
        input                           start_i,
        
        // master axi interface
        output wire  [ID_WIDTH-1:0]      m_axi_arid_o,
        output reg  [ADDR_WIDTH-1:0]      m_axi_araddr_o,
        output wire  [7:0]               m_axi_arlen_o,
        output wire  [2:0]               m_axi_arsize_o,
        output wire  [1:0]               m_axi_arburst_o,
        output wire                      m_axi_arlock_o,
        output wire  [3:0]               m_axi_arcache_o,
        output wire  [2:0]               m_axi_arprot_o,
        output wire  [3:0]               m_axi_arregion_o,
        output wire  [3:0]               m_axi_arqos_o,
        output wire  [ARUSER_WIDTH-1:0]  m_axi_aruser_o,
        output reg                      m_axi_arvalid_o,
        input                           m_axi_arready_i,
        input       [ID_WIDTH-1:0]      m_axi_rid_i,
        input       [DATA_WIDTH-1:0]    m_axi_rdata_i,
        input       [1:0]               m_axi_rresp_i,
        input                           m_axi_rlast_i,
        input       [RUSER_WIDTH-1:0]   m_axi_ruser_i,
        input                           m_axi_rvalid_i,
        output wire                     m_axi_rready_o
        );

    assign m_axi_arid_o = 0;
    assign m_axi_arlen_o=8'b0; // 1 transfer in a burst
    assign m_axi_arsize_o ='d5; // 32 bytes in a transfer
    assign m_axi_arburst_o = 'd0; // CONST
    assign m_axi_arcache_o = 0;
    assign m_axi_arprot_o = 0;
    assign m_axi_arregion_o = 0;
    assign m_axi_arqos_o = 0;
    assign m_axi_aruser_o = 0;
    assign m_axi_arlock_o = 0;
    assign m_axi_rready_o = 1;
    always@(posedge clk_i, negedge reset_n_i) begin
        if(!reset_n_i) begin
            m_axi_araddr_o <= 0;
            m_axi_arvalid_o <= 0;
        end
        else begin
            if(start_i && (m_axi_araddr_o != 'h3FFE0))
                m_axi_arvalid_o <= 1;
            else
                m_axi_arvalid_o <= 0;

            if(m_axi_arvalid_o && m_axi_arready_i)
                m_axi_araddr_o <= m_axi_araddr_o + 'd32;
        end
    end

    
endmodule