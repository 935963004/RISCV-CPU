// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "defines.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	  input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles, write takes 1 cycle
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17]==1)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

/*always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end*/

wire[31:0] mem_addr;
wire mem_wr_in;
wire[31:0] mem_data;
wire[31:0] data_out;
wire mem_ce;
wire[3:0] mem_sel;
wire stallreq_from_mem_ctrl;
wire[`InstAddrBus] if_pc;
wire[`InstAddrBus] mem_ctrl_pc;
wire if_ce;
wire branch_flag;
wire[`RegBus] branch_target_address;
wire[`RegBus] inst;
wire next;
wire[`AluOpBus] aluop_out;

mem_ctrl mem_ctrl0(
  .clk(clk_in),
  .rst(rst_in),
  .mem_data_in(mem_data),
  .mem_addr_in(mem_addr),
  .mem_wr_in(mem_wr_in),
  .mem_din(mem_din),
	.mem_ce_in(mem_ce),
	.mem_sel_in(mem_sel),
	.if_pc_in(if_pc),
	.if_ce_in(if_ce),
	.branch_flag_in(branch_flag),
	.branch_target_address_in(branch_target_address),
	.next(next),
	.mem_aluop_in(aluop_out),

  .mem_dout(mem_dout),
  .mem_a(mem_a),
  .mem_wr(mem_wr),
	.inst_out(inst),
  .data_out(data_out),
	.stallreq(stallreq_from_mem_ctrl),
	.mem_ctrl_pc(mem_ctrl_pc)
);

wire[5:0] stall;
wire stallreq_from_id;
wire stallreq_from_ex;

ctrl ctrl0(
  .rst(rst_in),
  .stallreq_from_id(stallreq_from_id),
  .stallreq_from_ex(stallreq_from_ex),
	.rdy_in(rdy_in),
	.stallreq_from_mem_ctrl(stallreq_from_mem_ctrl),
  .stall(stall)
);

pc_reg pc_reg0(
  .clk(clk_in),
  .rst(rst_in),
  .stall(stall),
	.branch_flag_in(branch_flag),
	.branch_target_address_in(branch_target_address),
	.rdy_in(rdy_in),

  .pc(if_pc),
  .ce(if_ce)
);

wire[`InstBus] if_inst;
wire[`InstAddrBus] id_pc_in;

if_id if_id0(
  .clk(clk_in),
  .rst(rst_in),
  .stall(stall),
  .if_inst(inst),
  .pc_in(mem_ctrl_pc),
  .pc_out(id_pc_in),
  .id_inst(if_inst)
);

wire we;
wire[`RegAddrBus] waddr;
wire[`RegBus] wdata;
wire re1;
wire[`RegAddrBus] raddr1;
wire[`RegBus] rdata1;
wire re2;
wire[`RegAddrBus] raddr2;
wire[`RegBus] rdata2;

regfile regfile0(
  .clk(clk_in),
  .rst(rst_in),

  .we(we),
  .waddr(waddr),
  .wdata(wdata),

	.re1(re1),
	.raddr1(raddr1),
	.rdata1(rdata1),
	
	.re2(re2),
	.raddr2(raddr2),
	.rdata2(rdata2)
);

wire[`AluOpBus] id_aluop_out;
wire[`AluSelBus] id_alusel_out;
wire[`RegBus] id_reg1_out;
wire[`RegBus] id_reg2_out;
wire[`RegAddrBus] id_wd_out;
wire id_wreg_out;
wire[`InstAddrBus] id_pc_out;
wire[`RegBus] id_link_address_out;
wire[`RegBus] id_inst_out;
wire[`AluOpBus] ex_aluop_out;
wire[`RegAddrBus] ex_wd_out;
wire ex_wreg_out;
wire[`RegBus] ex_wdata_out;
wire[`RegAddrBus] mem_wd_out;
wire mem_wreg_out;
wire[`RegBus] mem_wdata_out;

id id0(
  .rst(rst_in),
	.inst_in(if_inst),

  .pc_in(id_pc_in),
  .pc_out(id_pc_out),

	.reg1_data_in(rdata1),
	.reg2_data_in(rdata2),

  .ex_wreg_in(ex_wreg_out),
	.ex_wdata_in(ex_wdata_out),
	.ex_wd_in(ex_wd_out),

	.mem_wreg_in(mem_wreg_out),
	.mem_wdata_in(mem_wdata_out),
	.mem_wd_in(mem_wd_out),

	.reg1_read_out(re1),
	.reg2_read_out(re2),
	.reg1_addr_out(raddr1),
	.reg2_addr_out(raddr2),

	.aluop_out(id_aluop_out),
	.alusel_out(id_alusel_out),
	.reg1_out(id_reg1_out),
	.reg2_out(id_reg2_out),
	.wd_out(id_wd_out),
	.wreg_out(id_wreg_out),
  .stallreq(stallreq_from_id),

	.ex_aluop_in(ex_aluop_out),
	.branch_flag_out(branch_flag),
	.branch_target_address_out(branch_target_address),
	.link_addr_out(id_link_address_out),
	.inst_out(id_inst_out)
);

wire[`AluOpBus] ex_aluop_in;
wire[`AluSelBus] ex_alusel_in;
wire[`RegBus] ex_reg1_in;
wire[`RegBus] ex_reg2_in;
wire[`RegAddrBus] ex_wd_in;
wire ex_wreg_in;
wire[`InstAddrBus] ex_pc_in;
wire[`RegBus] ex_link_address_in;
wire[`RegBus] ex_inst_in;

id_ex id_ex0(
	.clk(clk_in),
	.rst(rst_in),
  .stall(stall),
	.id_aluop(id_aluop_out),
	.id_alusel(id_alusel_out),
	.id_reg1(id_reg1_out),
	.id_reg2(id_reg2_out),
	.id_wd(id_wd_out),
	.id_wreg(id_wreg_out),
  .pc_in(id_pc_out),
	.id_link_address(id_link_address_out),
	.id_inst(id_inst_out),

	.ex_aluop(ex_aluop_in),
	.ex_alusel(ex_alusel_in),
	.ex_reg1(ex_reg1_in),
	.ex_reg2(ex_reg2_in),
	.ex_wd(ex_wd_in),
	.ex_wreg(ex_wreg_in),
  .pc_out(ex_pc_in),
	.ex_link_address(ex_link_address_in),
	.ex_inst(ex_inst_in)
);

wire[`RegBus] ex_mem_addr_out;
wire[`RegBus] ex_reg2_out;

ex ex0(
	.rst(rst_in),
	.aluop_in(ex_aluop_in),
	.alusel_in(ex_alusel_in),
	.reg1_in(ex_reg1_in),
	.reg2_in(ex_reg2_in),
	.wd_in(ex_wd_in),
	.wreg_in(ex_wreg_in),
  .pc_in(ex_pc_in),
	.link_address_in(ex_link_address_in),
	.inst_in(ex_inst_in),

	.wd_out(ex_wd_out),
	.wreg_out(ex_wreg_out),
	.wdata_out(ex_wdata_out),
  .stallreq(stallreq_from_ex),
	.aluop_out(ex_aluop_out),
	.mem_addr_out(ex_mem_addr_out),
	.reg2_out(ex_reg2_out)
);

wire[`RegAddrBus] mem_wd_in;
wire mem_wreg_in;
wire[`RegBus] mem_wdata_in;
wire[`AluOpBus] mem_aluop_in;
wire[`RegBus] mem_mem_addr_in;
wire[`RegBus] mem_reg2_in;

ex_mem ex_mem0(
	.clk(clk_in),
	.rst(rst_in),
  .stall(stall),
	.ex_wd(ex_wd_out),
	.ex_wreg(ex_wreg_out),
	.ex_wdata(ex_wdata_out),
	.ex_aluop(ex_aluop_out),
	.ex_mem_addr(ex_mem_addr_out),
	.ex_reg2(ex_reg2_out),

	.mem_wd(mem_wd_in),
	.mem_wreg(mem_wreg_in),
	.mem_wdata(mem_wdata_in),
	.mem_aluop(mem_aluop_in),
	.mem_mem_addr(mem_mem_addr_in),
	.mem_reg2(mem_reg2_in),
	.next(next)
);

mem mem0(
	.rst(rst_in),
	.wd_in(mem_wd_in),
	.wreg_in(mem_wreg_in),
	.wdata_in(mem_wdata_in),
	.aluop_in(mem_aluop_in),
	.mem_addr_in(mem_mem_addr_in),
	.reg2_in(mem_reg2_in),
	.mem_data_in(data_out),

	.wd_out(mem_wd_out),
	.wreg_out(mem_wreg_out),
	.wdata_out(mem_wdata_out),
	.mem_addr_out(mem_addr),
	.mem_we_out(mem_wr_in),
	.mem_sel_out(mem_sel),
	.mem_data_out(mem_data),
	.mem_ce_out(mem_ce),
	.aluop_out(aluop_out)
);

mem_wb mem_wb0(
	.clk(clk_in),
	.rst(rst_in),
  .stall(stall),
	.mem_wd(mem_wd_out),
	.mem_wreg(mem_wreg_out),
	.mem_wdata(mem_wdata_out),

	.wb_wd(waddr),
	.wb_wreg(we),
	.wb_wdata(wdata)
);

endmodule