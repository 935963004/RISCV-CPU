`include "defines.v"

module pc_reg(
  input wire clk,
  input wire rst,
  input wire[5:0] stall,
  input wire branch_flag_in,
  input wire[`RegBus] branch_target_address_in,
  input wire rdy_in,

  output reg[`InstAddrBus] pc,
  output reg ce
);

always @(posedge clk)
begin
  if(rst == `RstEnable)
    ce <= `ChipDisable;
  else
    ce <= `ChipEnable;
end

always @(posedge clk)
begin
	if(ce == `ChipDisable)
  begin
		pc <= 32'h0;
  end
	else if(stall[0] == `NoStop)
  begin
    if(branch_flag_in == `Branch)
      pc <= branch_target_address_in + 4;
    else
		  pc <= pc + 4'h4;
  end
end

endmodule