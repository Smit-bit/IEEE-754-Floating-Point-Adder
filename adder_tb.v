`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 14:12:44
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder_tb;
    reg clk, exception, reset, available;
    reg [31:0] a;
    reg [31:0] b;

    wire [31:0] sum;
    wire done;

    adder uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .available(available),
        .exception(exception),
        .sum(sum),
        .done(done)
    );

    always #5 clk = ~clk; 

    initial begin
        clk = 0;
        reset = 1;
        a = 32'b0;
        b = 32'b0;
        available = 0;
        exception = 0;
        #10 reset = 0;

        a = 32'b01000000010000000000000000000000; 
        b = 32'b01000000100000000000000000000000; 
        available = 1;
        exception = 0;
        #10 available = 0;

        wait(done);

        #10 $stop;
    end
endmodule
