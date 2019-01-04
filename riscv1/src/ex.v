`include "defines.v"

module ex(
	input wire rst,
	input wire[`AluOpBus] aluop_in,
	input wire[`AluSelBus] alusel_in,
	input wire[`RegBus] reg1_in,
	input wire[`RegBus] reg2_in,
	input wire[`RegAddrBus] wd_in,
	input wire wreg_in,
	input wire[`InstAddrBus] pc_in,
	input wire[`RegBus] link_address_in,
	input wire[`RegBus] inst_in,

	output reg[`RegAddrBus] wd_out,
	output reg wreg_out,
	output reg[`RegBus] wdata_out,
	output wire stallreq,
	output wire[`AluOpBus] aluop_out,
	output wire[`RegBus] mem_addr_out,
	output wire[`RegBus] reg2_out
);

wire[`RegBus] imm;
assign aluop_out = aluop_in;
assign reg2_out = reg2_in;
assign imm = (aluop_in == `EXE_LB_OP || aluop_in == `EXE_LH_OP || aluop_in == `EXE_LW_OP || aluop_in == `EXE_LBU_OP || 
aluop_in == `EXE_LHU_OP) ? {{20{inst_in[31]}}, inst_in[31:20]} : {{20{inst_in[31]}}, inst_in[31:25], inst_in[11:7]};
assign mem_addr_out = reg1_in + imm;

reg[`RegBus] logicout;
reg[`RegBus] shiftres;
reg[`RegBus] arithmeticres;
reg stallreq_ex;

assign stallreq = stallreq_ex;

always @*
begin
	if(rst == `RstEnable)
	begin
		logicout = `ZeroWord;
		stallreq_ex = `NoStop;
	end
	else
	begin
		case(aluop_in)
			`EXE_OR_OP:
			begin
				logicout = reg1_in | reg2_in;
			end
			`EXE_AND_OP:
			begin
				logicout = reg1_in & reg2_in;
			end
			`EXE_XOR_OP:
			begin
				logicout = reg1_in ^ reg2_in;
			end
			default:
			begin
				logicout = `ZeroWord;
			end
		endcase
	end
end

always @*
begin
	if(rst == `RstEnable)
	begin
		shiftres = `ZeroWord;
		stallreq_ex = `NoStop;
	end
	else
	begin
		case(aluop_in)
			`EXE_SLL_OP:
			begin
				shiftres = reg1_in << reg2_in[4:0];
			end
			`EXE_SRL_OP:
			begin
				shiftres = reg1_in >> reg2_in[4:0];
			end
			`EXE_SRA_OP:
			begin
				shiftres = ({32{reg1_in[31]}} << (6'd32 - {1'b0,reg2_in[4:0]})) | reg1_in >> reg2_in[4:0];
			end
			default:
			begin
				shiftres = `ZeroWord;
			end
		endcase
	end
end

always @*
begin
	if(rst == `RstEnable)
	begin
		arithmeticres = `ZeroWord;
		stallreq_ex = `NoStop;
	end
	else
	begin
		case(aluop_in)
			`EXE_ADD_OP:
			begin
				arithmeticres = reg1_in + reg2_in;
			end
			`EXE_SUB_OP:
			begin
				arithmeticres = reg1_in - reg2_in;
			end
			`EXE_LUI_OP:
			begin
				arithmeticres = reg1_in;
			end
			`EXE_AUIPC_OP:
			begin
				arithmeticres = pc_in + reg1_in;
			end
			`EXE_SLT_OP:
			begin
				arithmeticres = {31'b0, $signed(reg1_in) < $signed(reg2_in)};
			end
			`EXE_SLTU_OP:
			begin
				arithmeticres = {31'b0, reg1_in < reg2_in};
			end
			default:
			begin
				arithmeticres = `ZeroWord;
			end
		endcase
	end
end

always @*
begin
	wd_out = wd_in;
	wreg_out = wreg_in;
	case(alusel_in)
		`EXE_RES_LOGIC:
		begin
			wdata_out = logicout;
		end
		`EXE_RES_SHIFT:
		begin
			wdata_out = shiftres;
		end
		`EXE_RES_ARITHMETIC:
		begin
			wdata_out = arithmeticres;
		end
		`EXE_RES_JUMP_BRANCH:
		begin
			wdata_out = link_address_in;
		end
		default:
		begin
			wdata_out = `ZeroWord;
		end
	endcase
end

endmodule