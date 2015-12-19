/* instruction memory */

`timescale 1ps/1ps

module mem(input clk,
    // read ports
    input fetchEnable, 
    input [15:0]raddr0, output [15:0]rdata0,

    input load1Enable,
    input [15:0]raddr1, output [15:0]rdata1,

    input load2Enable,
    input [15:0]raddr2, output [15:0]rdata2, 

    // write port
    input writeEnable, input [15:0]writeAddress, input [15:0]writeData);

    reg [15:0]mem[1023:0];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",mem);
    end

    /* memory address register */
    reg [15:0]in0 = 16'hxxxx;
    reg [15:0]in1 = 16'hxxxx;

    /* memory data register */
    reg [15:0]out0 = 16'hxxxx;
    reg [15:0]out1 = 16'hxxxx;
    reg [15:0]out2 = 16'hxxxx; 

    /* memory write regs */
    reg [15:0]writeAddress1;
    reg [15:0]writeData1;
    reg writeEnable1;

    assign rdata0 = out0;
    assign rdata1 = out1;
    assign rdata2 = out2; 

    always @(posedge clk) begin
        if (writeEnable) begin
            $display("#mem[%x] <= %x",writeAddress,writeData);
            mem[writeAddress] <= writeData;
        end
        if (fetchEnable) begin
           out0 <= mem[raddr0];        
        end
        if (load1Enable) begin
           out1 <= mem[raddr1];
        end
        if (load2Enable) begin
           out2 <= mem[raddr2]; 
        end


    end

endmodule
