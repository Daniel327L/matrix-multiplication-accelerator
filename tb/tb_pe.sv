`timescale 1ns/1ps

module tb_pe;

logic clk;

initial begin
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("tb_pe.vcd");
    $dumpvars(0, tb_pe);

    repeat(10) @ (posedge clk); 

    $display("this Make command works!!");
    $finish;
end

endmodule   

