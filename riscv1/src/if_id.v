`include "defines.v"

module if_id(
  input wire clk,
  input wire rst,
  input wire[5:0] stall,
  input wire[`InstBus] if_inst,
  input wire[`InstAddrBus] pc_in,
  output reg[`InstAddrBus] pc_out,
  output reg[`InstBus] id_inst
);

always @(posedge clk)
begin
  if(rst == `RstEnable)
  begin
    id_inst <= `ZeroWord;
    pc_out <= `ZeroWord;
  end
  else if(stall[1] == `Stop && stall[2] == `NoStop)
  begin
    id_inst <= `ZeroWord;
    pc_out <= `ZeroWord;
  end
	else if(stall[1] == `NoStop)
  begin
    id_inst <= if_inst;
    pc_out <= pc_in;
  end
end

endmodule