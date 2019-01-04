`include "defines.v"

module mem(
	input wire rst,
	input wire[`RegAddrBus] wd_in,
	input wire wreg_in,
	input wire[`RegBus] wdata_in,
	input wire[`AluOpBus] aluop_in,
	input wire[`RegBus] mem_addr_in,
	input wire[`RegBus] reg2_in,
	input wire[`RegBus] mem_data_in,

	output reg[`RegAddrBus] wd_out,
	output reg wreg_out,
	output reg[`RegBus] wdata_out,
	output reg[`RegBus] mem_addr_out,
	output wire mem_we_out,
	output reg[3:0] mem_sel_out,
	output reg[`RegBus] mem_data_out,
	output reg mem_ce_out,
	output wire[`AluOpBus] aluop_out
);

reg mem_we;

assign mem_we_out = mem_we;
assign aluop_out = aluop_in;

always @*
begin
	if(rst == `RstEnable)
	begin
		wd_out = `NOPRegAddr;
		wreg_out = `WriteDisable;
		wdata_out = `ZeroWord;
		mem_addr_out = `ZeroWord;
		mem_we = `WriteDisable;
		mem_sel_out = 4'b0000;
		mem_data_out =`ZeroWord;
		mem_ce_out = `ChipDisable;
	end
	else
	begin
		wd_out = wd_in;
		wreg_out = wreg_in;
		wdata_out = wdata_in;
		mem_addr_out = `ZeroWord;
		mem_we = `WriteDisable;
		mem_sel_out = 4'b1111;
		mem_data_out =`ZeroWord;
		mem_ce_out = `ChipDisable;
		case(aluop_in)
		`EXE_LB_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteDisable;
			mem_ce_out = `ChipEnable;
			wdata_out = {{24{mem_data_in[7]}}, mem_data_in[7:0]};
			mem_sel_out = 4'b0001;
		end
		`EXE_LBU_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteDisable;
			mem_ce_out = `ChipEnable;
			wdata_out = {24'b0, mem_data_in[7:0]};
			mem_sel_out = 4'b0001;
		end
		`EXE_LH_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteDisable;
			mem_ce_out = `ChipEnable;
			wdata_out = {{16{mem_data_in[15]}}, mem_data_in[15:0]};
			mem_sel_out = 4'b0011;
		end
		`EXE_LHU_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteDisable;
			mem_ce_out = `ChipEnable;
			wdata_out = {16'b0, mem_data_in[15:0]};
			mem_sel_out = 4'b0011;
		end
		`EXE_LW_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteDisable;
			wdata_out = mem_data_in;
			mem_sel_out = 4'b1111;
			mem_ce_out = `ChipEnable;
		end
		`EXE_SB_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteEnable;
			mem_data_out = {reg2_in[7:0], reg2_in[7:0], reg2_in[7:0], reg2_in[7:0]};
			mem_ce_out = `ChipEnable;
			mem_sel_out = 4'b0001;
		end
		`EXE_SH_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteEnable;
			mem_data_out = {reg2_in[15:0], reg2_in[15:0]};
			mem_ce_out = `ChipEnable;
			mem_sel_out = 4'b0011;
		end
		`EXE_SW_OP:
		begin
			mem_addr_out = mem_addr_in;
			mem_we = `WriteEnable;
			mem_data_out = reg2_in;
			mem_ce_out = `ChipEnable;
			mem_sel_out = 4'b1111;
		end
		endcase
	end
end

endmodule