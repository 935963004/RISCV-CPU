`include "defines.v"

module mem_ctrl(
  input wire clk,
  input wire rst,
  input wire[31:0] mem_data_in,
  input wire[31:0] mem_addr_in,
  input wire mem_wr_in,
  input wire[7:0] mem_din,
  input wire mem_ce_in,
  input wire[3:0] mem_sel_in,
  input wire[`InstAddrBus] if_pc_in,
  input wire if_ce_in,
  input wire branch_flag_in,
	input wire[`RegBus] branch_target_address_in,
  input wire next,
  input wire[`AluOpBus] mem_aluop_in,

  output reg[7:0] mem_dout,
  output reg[31:0] mem_a,
  output reg mem_wr,
  output reg[31:0] inst_out,
  output reg[31:0] data_out,
  output wire stallreq,
  output wire[`InstAddrBus] mem_ctrl_pc
);

reg[2:0] q_cnt1;
reg[2:0] d_cnt1;
reg[2:0] q_cnt2;
reg[2:0] d_cnt2;
reg[2:0] q_cnt3;
reg[2:0] d_cnt3;
reg[31:0] data;
reg stallreq_mem;
reg stallreq_if;
reg mem_ce;
reg[39:0] cache[2**8:0];

assign stallreq = stallreq_mem | stallreq_if;
assign mem_ctrl_pc = branch_flag_in ? branch_target_address_in : if_pc_in;

always @(posedge clk)
begin
  if(rst == `RstEnable)
  begin
    q_cnt1 <= 3'b000;
    q_cnt2 <= 3'b000;
    q_cnt3 <= 3'b000;
  end
  else
  begin
    q_cnt1 <= d_cnt1;
    q_cnt2 <= d_cnt2;
    q_cnt3 <= d_cnt3;
  end
end

always @*
begin
  if(rst == `RstEnable)
  begin
    mem_dout = `ZeroWord;
    mem_a = `ZeroWord;
    mem_wr = 1'b0;
    data_out = `ZeroWord;
    d_cnt1 = 3'b000;
    d_cnt2 = 3'b000;
    d_cnt3 = 3'b000;
    stallreq_mem = `NoStop;
    stallreq_if = `NoStop;
    mem_ce = 1'b0;
  end
  else
  begin
    mem_dout = `ZeroWord;
    mem_a = `ZeroWord;
    mem_wr = 1'b0;
    if(mem_ce_in == 1'b1 && next == 1'b1)
      mem_ce = 1'b1;
    if(mem_ce == `ChipEnable)
    begin
      if(mem_wr_in == 1'b0)
      begin
        case(q_cnt1)
          3'b000:
          begin
            mem_a = mem_addr_in;
            mem_wr = mem_wr_in;
            stallreq_mem = `Stop;
            d_cnt1 = 3'b001;
            d_cnt3 = 3'b000;
          end
          3'b001:
          begin
            mem_a = mem_addr_in + 1;
            mem_wr = mem_wr_in;
            d_cnt1 = 3'b010;
            data[7:0] = mem_din;
          end
          3'b010:
          begin
            mem_a = mem_addr_in + 2;
            mem_wr = mem_wr_in;
            d_cnt1 = 3'b011;
            data[15:8] = mem_din;
          end
          3'b011:
          begin
            mem_a = mem_addr_in + 3;
            mem_wr = mem_wr_in;
            d_cnt1 = 3'b100;
            data[23:16] = mem_din;
          end
          3'b100:
          begin
            mem_wr = mem_wr_in;
            d_cnt1 = 3'b101;
            data[31:24] = mem_din;
          end
          3'b101:
          begin
            mem_wr = mem_wr_in;
            data_out = data;
            d_cnt1 = 3'b110;
          end
          3'b110:
          begin
            stallreq_mem = `NoStop;
            d_cnt1 = 3'b000;
            mem_ce = 1'b0;
          end
        endcase
      end
      else
      begin
        case(q_cnt2)
          3'b000:
          begin
            stallreq_mem = `Stop;
            d_cnt2 = 3'b001;
            d_cnt3 = 3'b000;
            if(mem_sel_in[0] == 1'b1)
            begin
              mem_a = mem_addr_in;
              mem_wr = mem_wr_in;
              mem_dout = mem_data_in[7:0];
            end
          end
          3'b001:
          begin
            d_cnt2 = 3'b010;
            if(mem_sel_in[1] == 1'b1)
            begin
              mem_a = mem_addr_in + 1;
              mem_wr = mem_wr_in;
              mem_dout = mem_data_in[15:8];
            end
          end
          3'b010:
          begin
            d_cnt2 = 3'b011;
            if(mem_sel_in[2] == 1'b1)
            begin
              mem_a = mem_addr_in + 2;
              mem_wr = mem_wr_in;
              mem_dout = mem_data_in[23:16];
            end
          end
          3'b011:
          begin
            d_cnt2 = 3'b100;
            if(mem_sel_in[3] == 1'b1)
            begin
              mem_a = mem_addr_in + 3;
              mem_wr = mem_wr_in;
              mem_dout = mem_data_in[31:24];
            end
          end
          3'b100:
          begin
            d_cnt2 = 3'b000;
            stallreq_mem = `NoStop;
            mem_ce = 1'b0;
          end
        endcase
      end
    end
    else if(if_ce_in == `ChipEnable)
    begin
      if(branch_flag_in == `Branch)
      begin
        case(q_cnt3)
          3'b000:
          begin
            if(cache[branch_target_address_in[9:2]][39] == 1'b1 && cache[branch_target_address_in[9:2]][38:32] == branch_target_address_in[16:10])
            begin
              data[31:0] = cache[branch_target_address_in[9:2]][31:0];
              mem_a = branch_target_address_in;
              mem_wr = 1'b0;
              stallreq_if = `Stop;
              d_cnt3 = 3'b101;
              d_cnt1 = 3'b000;
              d_cnt2 = 3'b000;
            end
            else
            begin
              mem_a = branch_target_address_in;
              mem_wr = 1'b0;
              stallreq_if = `Stop;
              d_cnt3 = 3'b001;
              d_cnt1 = 3'b000;
              d_cnt2 = 3'b000;
            end
          end
          3'b001:
          begin
            mem_a = branch_target_address_in + 1;
            mem_wr = 1'b0;
            d_cnt3 = 3'b010;
            data[7:0] = mem_din;
          end
          3'b010:
          begin
            mem_a = branch_target_address_in + 2;
            mem_wr = 1'b0;
            d_cnt3 = 3'b011;
            data[15:8] = mem_din;
          end
          3'b011:
          begin
            mem_a = branch_target_address_in + 3;
            mem_wr = 1'b0;
            d_cnt3 = 3'b100;
            data[23:16] = mem_din;
          end
          3'b100:
          begin
            mem_wr = 1'b0;
            d_cnt3 = 3'b101;
            data[31:24] = mem_din;
          end
          3'b101:
          begin
            if(cache[branch_target_address_in[9:2]][39] != 1'b1 || cache[branch_target_address_in[9:2]][38:32] != branch_target_address_in[16:10])
              cache[branch_target_address_in[9:2]] = {1'b1, branch_target_address_in[16:10], data};
            mem_wr = 1'b0;
            mem_wr = 1'b0;
            inst_out = data;
            stallreq_if = `NoStop;
            d_cnt3 = 3'b000;
          end
        endcase
      end
      else
      begin
        case(q_cnt3)
          3'b000:
          begin
            if(cache[if_pc_in[9:2]][39] == 1'b1 && cache[if_pc_in[9:2]][38:32] == if_pc_in[16:10])
            begin
              data[31:0] = cache[if_pc_in[9:2]][31:0];
              mem_a = if_pc_in;
              mem_wr = 1'b0;
              stallreq_if = `Stop;
              d_cnt3 = 3'b101;
              d_cnt1 = 3'b000;
              d_cnt2 = 3'b000;
            end
            else
            begin
              mem_a = if_pc_in;
              mem_wr = 1'b0;
              stallreq_if = `Stop;
              d_cnt3 = 3'b001;
              d_cnt1 = 3'b000;
              d_cnt2 = 3'b000;
            end
          end
          3'b001:
          begin
            mem_a = if_pc_in + 1;
            mem_wr = 1'b0;
            d_cnt3 = 3'b010;
            data[7:0] = mem_din;
          end
          3'b010:
          begin
            mem_a = if_pc_in + 2;
            mem_wr = 1'b0;
            d_cnt3 = 3'b011;
            data[15:8] = mem_din;
          end
          3'b011:
          begin
            mem_a = if_pc_in + 3;
            mem_wr = 1'b0;
            d_cnt3 = 3'b100;
            data[23:16] = mem_din;
          end
          3'b100:
          begin
            mem_wr = 1'b0;
            d_cnt3 = 3'b101;
            data[31:24] = mem_din;
          end
          3'b101:
          begin
            if(cache[if_pc_in[9:2]][39] != 1'b1 || cache[if_pc_in[9:2]][38:32] != if_pc_in[16:10])
              cache[if_pc_in[9:2]] = {1'b1, if_pc_in[16:10], data};
            mem_wr = 1'b0;
            inst_out = data;
            stallreq_if = `NoStop;
            d_cnt3 = 3'b000;
          end
        endcase
      end
    end
  end
end

endmodule