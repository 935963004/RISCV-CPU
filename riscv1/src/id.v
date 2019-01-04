`include "defines.v"

module id(
  input wire rst,
	input wire[`InstBus] inst_in,

	input wire[`InstAddrBus] pc_in,
	output wire[`InstAddrBus] pc_out,

	input wire[`RegBus] reg1_data_in,
	input wire[`RegBus] reg2_data_in,

	input wire ex_wreg_in,
	input wire[`RegBus] ex_wdata_in,
	input wire[`RegAddrBus] ex_wd_in,

	input wire mem_wreg_in,
	input wire[`RegBus] mem_wdata_in,
	input wire[`RegAddrBus] mem_wd_in,

	output reg reg1_read_out,
	output reg reg2_read_out,
	output reg[`RegAddrBus] reg1_addr_out,
	output reg[`RegAddrBus] reg2_addr_out,

	output reg[`AluOpBus] aluop_out,
	output reg[`AluSelBus] alusel_out,
	output reg[`RegBus] reg1_out,
	output reg[`RegBus] reg2_out,
	output reg[`RegAddrBus] wd_out,
	output reg wreg_out,
	output wire stallreq,

	input wire[`AluOpBus] ex_aluop_in,
	output reg branch_flag_out,
	output reg[`RegBus] branch_target_address_out,
	output reg[`RegBus] link_addr_out,
	output wire[`RegBus] inst_out
);

assign pc_out = pc_in;
assign inst_out = inst_in;

wire[6:0] op = inst_in[6:0];
wire[3:0] op2 = inst_in[14:12];
wire[6:0] op3 = inst_in[31:25];
reg[`RegBus] imm;
wire[`RegBus] pc_plus_4;
wire[`RegBus] imm_J;
wire[`RegBus] imm_B;
wire[`RegBus] b_target_res;
wire[`RegBus] jalr_target_res;

assign pc_plus_4 = pc_in + 4;
assign imm_J = {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'h0};
assign imm_B = {{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'h0};
assign b_target_res = op == `EXE_JAL ? pc_in + imm_J : pc_in + imm_B;
assign jalr_target_res = reg1_data_in + {{20{inst_in[31]}}, inst_in[31:20]};

reg stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;
wire pre_inst_is_load;

assign pre_inst_is_load = (ex_aluop_in == `EXE_LB_OP || ex_aluop_in == `EXE_LBU_OP || ex_aluop_in == `EXE_LH_OP || 
ex_aluop_in == `EXE_LHU_OP || ex_aluop_in == `EXE_LW_OP) ? 1'b1 : 1'b0;

always @*
begin
	if(rst == `RstEnable)
	begin
		aluop_out = `EXE_NOP_OP;
		alusel_out = `EXE_RES_NOP;
		wd_out = `NOPRegAddr;
		wreg_out = `WriteDisable;
		reg1_read_out = 1'b0;
		reg2_read_out = 1'b0;
		reg1_addr_out = `NOPRegAddr;
		reg2_addr_out = `NOPRegAddr;
		imm = `ZeroWord;
		link_addr_out = `ZeroWord;
		branch_target_address_out = `ZeroWord;
		branch_flag_out = `NotBranch;
	end
	else
	begin
		aluop_out = `EXE_NOP_OP;
		alusel_out = `EXE_RES_NOP;
		wd_out = inst_in[11:7];
		wreg_out = `WriteDisable;
		reg1_read_out = 1'b0;
		reg2_read_out = 1'b0;
		reg1_addr_out = inst_in[19:15];
		reg2_addr_out = inst_in[24:20];
		imm = `ZeroWord;
		link_addr_out = `ZeroWord;
		branch_target_address_out = `ZeroWord;
		branch_flag_out = `NotBranch;
		case(op)
			7'b0010011:
			begin
				case(op2)
					`EXE_ORI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_OR_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					`EXE_ANDI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_AND_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					`EXE_XORI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_XOR_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					`EXE_SLLI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLL_OP;
						alusel_out = `EXE_RES_SHIFT;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {27'b0, inst_in[24:20]};
					end
					`EXE_ADDI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_ADD_OP;
						alusel_out = `EXE_RES_ARITHMETIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					`EXE_SLTI:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLT_OP;
						alusel_out = `EXE_RES_ARITHMETIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					`EXE_SLTIU:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLTU_OP;
						alusel_out = `EXE_RES_ARITHMETIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
						imm = {{20{inst_in[31]}}, inst_in[31:20]};
					end
					3'b101:
					begin
						if(op3 == `EXE_SRLI)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_SRL_OP;
							alusel_out = `EXE_RES_SHIFT;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b0;
							imm = {27'b0, inst_in[24:20]};
						end
						else if(op3 == `EXE_SRAI)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_SRA_OP;
							alusel_out = `EXE_RES_SHIFT;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b0;
							imm = {27'b0, inst_in[24:20]};
						end
					end
					default:
					begin
					end
				endcase
			end
			7'b0110011:
			begin
				case(op2)
					`EXE_OR:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_OR_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_AND:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_AND_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_XOR:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_XOR_OP;
						alusel_out = `EXE_RES_LOGIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_SLL:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLL_OP;
						alusel_out = `EXE_RES_SHIFT;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_SLT:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLT_OP;
						alusel_out = `EXE_RES_ARITHMETIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_SLTU:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_SLTU_OP;
						alusel_out = `EXE_RES_ARITHMETIC;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					3'b101:
					begin
						if(op3 == `EXE_SRL)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_SRL_OP;
							alusel_out = `EXE_RES_SHIFT;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b1;
						end
						else if(op3 == `EXE_SRA)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_SRA_OP;
							alusel_out = `EXE_RES_SHIFT;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b1;
						end
					end
					3'b000:
					begin
						if(op3 == `EXE_ADD)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_ADD_OP;
							alusel_out = `EXE_RES_ARITHMETIC;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b1;
						end
						else if(op3 == `EXE_SUB)
						begin
							wreg_out = `WriteEnable;
							aluop_out = `EXE_SUB_OP;
							alusel_out = `EXE_RES_ARITHMETIC;
							reg1_read_out = 1'b1;
							reg2_read_out = 1'b1;
						end
					end
					default:
					begin
					end
				endcase
			end
			`EXE_FENCE:
			begin
				wreg_out = `WriteDisable;
				aluop_out = `EXE_NOP_OP;
				alusel_out = `EXE_RES_NOP;
				reg1_read_out = 1'b0;
				reg2_read_out = 1'b0;
			end
			`EXE_LUI:
			begin
				wreg_out = `WriteEnable;
				aluop_out = `EXE_LUI_OP;
				alusel_out = `EXE_RES_ARITHMETIC;
				reg1_read_out = 1'b0;
				reg2_read_out = 1'b0;
				imm = {inst_in[31:12], 12'b0};
			end
			`EXE_AUIPC:
			begin
				wreg_out = `WriteEnable;
				aluop_out = `EXE_AUIPC_OP;
				alusel_out = `EXE_RES_ARITHMETIC;
				reg1_read_out = 1'b0;
				reg2_read_out = 1'b0;
				imm = {inst_in[31:12], 12'b0};
			end
			`EXE_JAL:
			begin
				wreg_out = `WriteEnable;
				aluop_out = `EXE_JAL_OP;
				alusel_out = `EXE_RES_JUMP_BRANCH;
				reg1_read_out = 1'b0;
				reg2_read_out = 1'b0;
				link_addr_out = pc_plus_4;
				branch_flag_out = `Branch;
				branch_target_address_out = b_target_res;
			end
			`EXE_JALR:
			begin
				wreg_out = `WriteEnable;
				aluop_out = `EXE_JAL_OP;
				alusel_out = `EXE_RES_JUMP_BRANCH;
				reg1_read_out = 1'b1;
				reg2_read_out = 1'b0;
				link_addr_out = pc_plus_4;
				branch_flag_out = `Branch;
				branch_target_address_out = jalr_target_res;
			end
			7'b1100011:
			begin
				case(op2)
					`EXE_BEQ:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BEQ_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if(reg1_out == reg2_out)
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
					`EXE_BNE:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BNE_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if(reg1_out != reg2_out)
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
					`EXE_BLT:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BLT_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if($signed(reg1_out) < $signed(reg2_out))
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
					`EXE_BLTU:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BLT_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if(reg1_out < reg2_out)
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
					`EXE_BGE:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BGE_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if($signed(reg1_out) >= $signed(reg2_out))
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
					`EXE_BGEU:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_BGE_OP;
						alusel_out = `EXE_RES_JUMP_BRANCH;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
						if(reg1_out >= reg2_out)
						begin
							branch_target_address_out = b_target_res;
							branch_flag_out = `Branch;
						end
					end
				endcase
			end
			7'b0000011:
			begin
				case(op2)
					`EXE_LB:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_LB_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
					end
					`EXE_LBU:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_LBU_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
					end
					`EXE_LH:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_LH_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
					end
					`EXE_LHU:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_LHU_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
					end
					`EXE_LW:
					begin
						wreg_out = `WriteEnable;
						aluop_out = `EXE_LW_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b0;
					end
				endcase
			end
			7'b0100011:
			begin
				case(op2)
					`EXE_SB:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_SB_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_SH:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_SH_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
					`EXE_SW:
					begin
						wreg_out = `WriteDisable;
						aluop_out = `EXE_SW_OP;
						alusel_out = `EXE_RES_LOAD_STORE;
						reg1_read_out = 1'b1;
						reg2_read_out = 1'b1;
					end
				endcase
			end
			default:
			begin
			end
		endcase
	end
end

always @*
begin
	stallreq_for_reg1_loadrelate = `NoStop;
	if(rst == `RstEnable)
		reg1_out = `ZeroWord;
	else if(pre_inst_is_load == 1'b1 && ex_wd_in == reg1_addr_out && reg1_read_out == 1'b1)
		stallreq_for_reg1_loadrelate = `Stop;
	else if(reg1_read_out == 1'b1 && ex_wreg_in == 1'b1 && ex_wd_in == reg1_addr_out && ex_wd_in != 5'b0)
		reg1_out = ex_wdata_in;
	else if(reg1_read_out == 1'b1 && mem_wreg_in == 1'b1 && mem_wd_in == reg1_addr_out && mem_wd_in != 5'b0)
		reg1_out = mem_wdata_in;
	else if(reg1_read_out == 1'b1)
		reg1_out = reg1_data_in;
	else if(reg1_read_out == 1'b0)
		reg1_out = imm;
	else
		reg1_out = `ZeroWord;
end

always @*
begin
	stallreq_for_reg2_loadrelate = `NoStop;
	if(rst == `RstEnable)
		reg2_out = `ZeroWord;
	else if(pre_inst_is_load == 1'b1 && ex_wd_in == reg2_addr_out && reg2_read_out == 1'b1)
		stallreq_for_reg2_loadrelate = `Stop;
	else if(reg2_read_out == 1'b1 && ex_wreg_in == 1'b1 && ex_wd_in == reg2_addr_out && ex_wd_in != 5'b0)
		reg2_out = ex_wdata_in;
	else if(reg2_read_out == 1'b1 && mem_wreg_in == 1'b1 && mem_wd_in == reg2_addr_out && mem_wd_in != 5'b0)
		reg2_out = mem_wdata_in;
	else if(reg2_read_out == 1'b1)
		reg2_out = reg2_data_in;
	else if(reg2_read_out == 1'b0)
		reg2_out = imm;
	else
		reg2_out = `ZeroWord;
end

assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

endmodule