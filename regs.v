/* register file */

`timescale 1ps/1ps
module regs(input clk,
            input ren0, input [2:0]raddr0, output [15:0]rdata0,
            input ren1, input [2:0]raddr1, output [15:0]rdata1,
            input wen, input [2:0]waddr, input [15:0]wdata);
    reg [7:0]data[15:0];

    reg [15:0]out0 = 16'hxxxx;
    assign rdata0 = out0;
    reg [15:0]out1 = 16'hxxxx;
    assign rdata1 = out1;

    always @(posedge clk) begin

        if (ren0) begin
            out0 <= data[raddr0];
        end
        if (ren1) begin
            out1 <= data[raddr1];
        end
        if (wen) begin
            $display("#reg[%d] <= 0x%x",waddr,wdata);
            data[waddr] <= wdata;
        end
    end

endmodule
