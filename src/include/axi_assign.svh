////////////////////////////////////////////////////////////////////////////////////////////////////
// Macros for assigning flattened AXI ports to req/resp AXI structs
// Flat AXI ports are required by the Vivado IP Integrator. Vivado naming convention is followed.
//
// Usage Example:
// `AXI_ASSIGN_MASTER_TO_FLAT("my_bus", my_req_struct, my_rsp_struct)
`ifndef AXI_ASSIGN_SVH
`define AXI_ASSIGN_SVH

`define AXI_IOASSIGN_MASTER_TO_FLAT(pat, req, rsp) \
  assign m_axi_``pat``_awvalid_o  = req.aw_valid;  \
  assign m_axi_``pat``_awid_o     = req.aw.id;     \
  assign m_axi_``pat``_awaddr_o   = req.aw.addr;   \
  assign m_axi_``pat``_awlen_o    = req.aw.len;    \
  assign m_axi_``pat``_awsize_o   = req.aw.size;   \
  assign m_axi_``pat``_awburst_o  = req.aw.burst;  \
  assign m_axi_``pat``_awlock_o   = req.aw.lock;   \
  assign m_axi_``pat``_awcache_o  = req.aw.cache;  \
  assign m_axi_``pat``_awprot_o   = req.aw.prot;   \
  assign m_axi_``pat``_awqos_o    = req.aw.qos;    \
  assign m_axi_``pat``_awregion_o = req.aw.region; \
  assign m_axi_``pat``_awuser_o   = req.aw.user;   \
  assign m_axi_``pat``_awatop_o   = req.aw.atop;   \
                                                 \
  assign m_axi_``pat``_wvalid_o   = req.w_valid;   \
  assign m_axi_``pat``_wdata_o    = req.w.data;    \
  assign m_axi_``pat``_wstrb_o    = req.w.strb;    \
  assign m_axi_``pat``_wlast_o    = req.w.last;    \
  assign m_axi_``pat``_wuser_o    = req.w.user;    \
                                                 \
  assign m_axi_``pat``_bready_o   = req.b_ready;   \
                                                 \
  assign m_axi_``pat``_arvalid_o  = req.ar_valid;  \
  assign m_axi_``pat``_arid_o     = req.ar.id;     \
  assign m_axi_``pat``_araddr_o   = req.ar.addr;   \
  assign m_axi_``pat``_arlen_o    = req.ar.len;    \
  assign m_axi_``pat``_arsize_o   = req.ar.size;   \
  assign m_axi_``pat``_arburst_o  = req.ar.burst;  \
  assign m_axi_``pat``_arlock_o   = req.ar.lock;   \
  assign m_axi_``pat``_arcache_o  = req.ar.cache;  \
  assign m_axi_``pat``_arprot_o   = req.ar.prot;   \
  assign m_axi_``pat``_arqos_o    = req.ar.qos;    \
  assign m_axi_``pat``_arregion_o = req.ar.region; \
  assign m_axi_``pat``_aruser_o   = req.ar.user;   \
                                                 \
  assign m_axi_``pat``_rready_o   = req.r_ready;   \
                                                 \
  assign rsp.aw_ready = m_axi_``pat``_awready_i;   \
  assign rsp.ar_ready = m_axi_``pat``_arready_i;   \
  assign rsp.w_ready  = m_axi_``pat``_wready_i;    \
                                                 \
  assign rsp.b_valid  = m_axi_``pat``_bvalid_i;    \
  assign rsp.b.id     = m_axi_``pat``_bid_i;       \
  assign rsp.b.resp   = m_axi_``pat``_bresp_i;     \
  assign rsp.b.user   = m_axi_``pat``_buser_i;     \
                                                 \
  assign rsp.r_valid  = m_axi_``pat``_rvalid_i;    \
  assign rsp.r.id     = m_axi_``pat``_rid_i;       \
  assign rsp.r.data   = m_axi_``pat``_rdata_i;     \
  assign rsp.r.resp   = m_axi_``pat``_rresp_i;     \
  assign rsp.r.last   = m_axi_``pat``_rlast_i;     \
  assign rsp.r.user   = m_axi_``pat``_ruser_i;

`define AXI_IOASSIGN_SLAVE_TO_FLAT(pat, req, rsp)  \
  assign req.aw_valid  = s_axi_``pat``_awvalid_i;  \
  assign req.aw.id     = s_axi_``pat``_awid_i;     \
  assign req.aw.addr   = {24'd0, s_axi_``pat``_awaddr_i[7:0]};   \
  assign req.aw.len    = s_axi_``pat``_awlen_i;    \
  assign req.aw.size   = s_axi_``pat``_awsize_i;   \
  assign req.aw.burst  = s_axi_``pat``_awburst_i;  \
  assign req.aw.lock   = s_axi_``pat``_awlock_i;   \
  assign req.aw.cache  = s_axi_``pat``_awcache_i;  \
  assign req.aw.prot   = s_axi_``pat``_awprot_i;   \
  assign req.aw.qos    = s_axi_``pat``_awqos_i;    \
  assign req.aw.region = s_axi_``pat``_awregion_i; \
  assign req.aw.user   = s_axi_``pat``_awuser_i;   \
  assign req.aw.atop   = s_axi_``pat``_awatop_i;   \
                                                 \
  assign req.w_valid   = s_axi_``pat``_wvalid_i;   \
  assign req.w.data    = s_axi_``pat``_wdata_i;    \
  assign req.w.strb    = s_axi_``pat``_wstrb_i;    \
  assign req.w.last    = s_axi_``pat``_wlast_i;    \
  assign req.w.user    = s_axi_``pat``_wuser_i;    \
                                                 \
  assign req.b_ready   = s_axi_``pat``_bready_i;   \
                                                 \
  assign req.ar_valid  = s_axi_``pat``_arvalid_i;  \
  assign req.ar.id     = s_axi_``pat``_arid_i;     \
  assign req.ar.addr   = s_axi_``pat``_araddr_i;   \
  assign req.ar.len    = s_axi_``pat``_arlen_i;    \
  assign req.ar.size   = s_axi_``pat``_arsize_i;   \
  assign req.ar.burst  = s_axi_``pat``_arburst_i;  \
  assign req.ar.lock   = s_axi_``pat``_arlock_i;   \
  assign req.ar.cache  = s_axi_``pat``_arcache_i;  \
  assign req.ar.prot   = s_axi_``pat``_arprot_i;   \
  assign req.ar.qos    = s_axi_``pat``_arqos_i;    \
  assign req.ar.region = s_axi_``pat``_arregion_i; \
  assign req.ar.user   = s_axi_``pat``_aruser_i;   \
                                                 \
  assign req.r_ready   = s_axi_``pat``_rready_i;   \
                                                 \
  assign s_axi_``pat``_awready_o = rsp.aw_ready;   \
  assign s_axi_``pat``_arready_o = rsp.ar_ready;   \
  assign s_axi_``pat``_wready_o  = rsp.w_ready;    \
                                                 \
  assign s_axi_``pat``_bvalid_o  = rsp.b_valid;    \
  assign s_axi_``pat``_bid_o     = rsp.b.id;       \
  assign s_axi_``pat``_bresp_o   = rsp.b.resp;     \
  assign s_axi_``pat``_buser_o   = rsp.b.user;     \
                                                 \
  assign s_axi_``pat``_rvalid_o  = rsp.r_valid;    \
  assign s_axi_``pat``_rid_o    = rsp.r.id;       \
  assign s_axi_``pat``_rdata_o   = rsp.r.data;     \
  assign s_axi_``pat``_rresp_o   = rsp.r.resp;     \
  assign s_axi_``pat``_rlast_o   = rsp.r.last;     \
  assign s_axi_``pat``_ruser_o   = rsp.r.user;



// inverse

  `define AXI_IOASSIGN_FLAT_TO_MASTER(pat, tra, req, rsp) \
  assign req.aw_valid   = m_axi_``pat``_awvalid_``tra``;  \
  assign req.aw.id      = m_axi_``pat``_awid_``tra``;     \
  assign req.aw.addr    = m_axi_``pat``_awaddr_``tra``;   \
  assign req.aw.len     = m_axi_``pat``_awlen_``tra``;    \
  assign req.aw.size    = m_axi_``pat``_awsize_``tra``;   \
  assign req.aw.burst   = m_axi_``pat``_awburst_``tra``;  \
  assign req.aw.lock    = m_axi_``pat``_awlock_``tra``;   \
  assign req.aw.cache   = m_axi_``pat``_awcache_``tra``;  \
  assign req.aw.prot    = m_axi_``pat``_awprot_``tra``;   \
  assign req.aw.qos     = m_axi_``pat``_awqos_``tra``;    \
  assign req.aw.region  = m_axi_``pat``_awregion_``tra``; \
  assign req.aw.user    = m_axi_``pat``_awuser_``tra``;   \
  assign req.aw.atop    = m_axi_``pat``awatop``tra``;   \
                                                 \
  assign req.w_valid   = m_axi_``pat``_wvalid_``tra``;   \
  assign req.w.data    = m_axi_``pat``_wdata_``tra``;    \
  assign req.w.strb    = m_axi_``pat``_wstrb_``tra``;    \
  assign req.w.last    = m_axi_``pat``_wlast_``tra``;    \
  assign req.w.user    = m_axi_``pat``_wuser_``tra``;    \
                                                 \
  assign req.b_ready   = m_axi_``pat``_bready_``tra``;   \
                                                 \
  assign req.ar_valid  = m_axi_``pat``_arvalid_``tra``;  \
  assign req.ar.id     = m_axi_``pat``_arid_``tra``;     \
  assign req.ar.addr   = m_axi_``pat``_araddr_``tra``;   \
  assign req.ar.len    = m_axi_``pat``_arlen_``tra``;    \
  assign req.ar.size   = m_axi_``pat``_arsize_``tra``;   \
  assign req.ar.burst  = m_axi_``pat``_arburst_``tra``;  \
  assign req.ar.lock   = m_axi_``pat``_arlock_``tra``;   \
  assign req.ar.cache  = m_axi_``pat``_arcache_``tra``;  \
  assign req.ar.prot   = m_axi_``pat``_arprot_``tra``;   \
  assign req.ar.qos    = m_axi_``pat``_arqos_``tra``;    \
  assign req.ar.region = m_axi_``pat``_arregion_``tra``; \
  assign req.ar.user   = m_axi_``pat``_aruser_``tra``;   \
                                                 \
  assign req.r_ready   = m_axi_``pat``_rready_``tra``;   \
                                                 \
  assign m_axi_``pat``_awready_``tra`` = rsp.aw_ready;   \
  assign m_axi_``pat``_arready_``tra`` = rsp.ar_ready;   \
  assign m_axi_``pat``_wready_``tra``  = rsp.w_ready;    \
                                                 \
  assign m_axi_``pat``_bvalid_``tra``  = rsp.b_valid;    \
  assign m_axi_``pat``_bid_``tra``     = rsp.b.id;       \
  assign m_axi_``pat``_bresp_``tra``   = rsp.b.resp;     \
  assign m_axi_``pat``_buser_``tra``   = rsp.b.user;     \
                                                 \
  assign m_axi_``pat``_rvalid_``tra``  = rsp.r_valid;    \
  assign m_axi_``pat``_rid_``tra``    = rsp.r.id;       \
  assign m_axi_``pat``_rdata_``tra``   = rsp.r.data;     \
  assign m_axi_``pat``_rresp_``tra``   = rsp.r.resp;     \
  assign m_axi_``pat``_rlast_``tra``   = rsp.r.last;     \
  assign m_axi_``pat``_ruser_``tra``   = rsp.r.user;

`define AXI_IOASSIGN_FLAT_TO_SLAVE(pat, tra, req, rsp)  \
  assign s_axi_``pat``_awvalid_``tra`` = req.aw_valid;  \
  assign s_axi_``pat``_awid_``tra``    = req.aw.id;     \
  assign s_axi_``pat``_awaddr_``tra``  = req.aw.addr;   \
  assign s_axi_``pat``_awlen_``tra``   = req.aw.len;    \
  assign s_axi_``pat``_awsize_``tra``  = req.aw.size;   \
  assign s_axi_``pat``_awburst_``tra`` = req.aw.burst;  \
  assign s_axi_``pat``_awlock_``tra``  = req.aw.lock;   \
  assign s_axi_``pat``_awcache_``tra`` = req.aw.cache;  \
  assign s_axi_``pat``_awprot_``tra``  = req.aw.prot;   \
  assign s_axi_``pat``_awqos_``tra``   = req.aw.qos;    \
  assign s_axi_``pat``_awregion_``tra`` = req.aw.region; \
  assign s_axi_``pat``_awuser_``tra``   = req.aw.user;   \
  assign s_axi_``pat``_awatop_``tra``   = req.aw.atop;   \
                                                 \
  assign s_axi_``pat``_wvalid_``tra``  = req.w_valid;   \
  assign s_axi_``pat``_wdata_``tra``   = req.w.data;    \
  assign s_axi_``pat``_wstrb_``tra``   = req.w.strb;    \
  assign s_axi_``pat``_wlast_``tra``   = req.w.last;    \
  assign s_axi_``pat``_wuser_``tra``   = req.w.user;    \
                                                 \
  assign s_axi_``pat``_bready_``tra``  = req.b_ready;   \
                                                 \
  assign s_axi_``pat``_arvalid_``tra`` = req.ar_valid;  \
  assign s_axi_``pat``_arid_``tra``    = req.ar.id;     \
  assign s_axi_``pat``_araddr_``tra``  = req.ar.addr;   \
  assign s_axi_``pat``_arlen_``tra``   = req.ar.len;    \
  assign s_axi_``pat``_arsize_``tra``  = req.ar.size;   \
  assign s_axi_``pat``_arburst_``tra`` = req.ar.burst;  \
  assign s_axi_``pat``_arlock_``tra``  = req.ar.lock;   \
  assign s_axi_``pat``_arcache_``tra`` = req.ar.cache;  \
  assign s_axi_``pat``_arprot_``tra``  = req.ar.prot;   \
  assign s_axi_``pat``_arqos_``tra``   = req.ar.qos;    \
  assign s_axi_``pat``_arregion_``tra`` = req.ar.region; \
  assign s_axi_``pat``_aruser_``tra``   = req.ar.user;   \
                                                 \
  assign s_axi_``pat``_rready_``tra``  = req.r_ready;   \
                                                 \
  assign rsp.aw_ready = s_axi_``pat``_awready_``tra``;   \
  assign rsp.ar_ready = s_axi_``pat``_arready_``tra``;   \
  assign rsp.w_ready  = s_axi_``pat``_wready_``tra``;    \
                                                 \
  assign rsp.b_valid  = s_axi_``pat``_bvalid_``tra``;    \
  assign rsp.b.id     = s_axi_``pat``_bid_``tra``;       \
  assign rsp.b.resp   = s_axi_``pat``_bresp_``tra``;     \
  assign rsp.b.user   = s_axi_``pat``_buser_``tra``;     \
                                                 \
  assign rsp.r_valid  = s_axi_``pat``_rvalid_``tra``;    \
  assign rsp.r.id     = s_axi_``pat``_rid_``tra``;       \
  assign rsp.r.data   = s_axi_``pat``_rdata_``tra``;     \
  assign rsp.r.resp   = s_axi_``pat``_rresp_``tra``;     \
  assign rsp.r.last   = s_axi_``pat``_rlast_``tra``;     \
  assign rsp.r.user   = s_axi_``pat``_ruser_``tra``;
`endif // AXI_ASSIGN_SVH