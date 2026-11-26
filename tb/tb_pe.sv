`timescale 1ns/1ps

module tb_pe;

integer counter;

logic clk = 0;

initial begin
    forever #5 clk = ~clk;
    if(counter != 0)
        $fatal;
end

logic signed [7:0] a_out;
logic signed [31:0] psum_out;
logic rst_n, load_w;
logic signed [7:0] w_in;
logic signed [7:0] a_in;
logic signed [31:0] psum_in;


pe #(
    .A_W(8),
    .W_W(8),
    .ACC_W(32)
) DUT (
    .rst_n(rst_n),
    .clk(clk),
    .load_w(load_w),
    .w_in(w_in),
    .a_in(a_in),
    .psum_in(psum_in),
    .a_out(a_out),
    .psum_out(psum_out)
);



task check (
    input load,
    input rst,
    input logic signed [7:0] w,
    input logic signed [7:0] a,
    input logic signed [31:0] psum,
    input signed [31:0] expected_p,
    input signed [7:0] expected_a
);
    load_w = load;
    rst_n = rst;
    w_in = w;
    a_in = a;
    psum_in = psum;

    @(posedge clk);
    #1;

    if(psum_out == expected_p && a_out == expected_a) begin
            $display("PASS load_w=%h rst_n=%h | w_in=%h a_in=%h psum_in=%h : psum_out=%h a_out=%h and expected_p=%h expected_a=%h", 
                                                                            load, rst, w, a, psum, psum_out, a_out, expected_p, expected_a);
    end else begin
            $display("FAIL load_w=%h rst_n=%h | w_in=%h a_in=%h psum_in=%h : psum_out=%h a_out=%h but expected_p=%h expected_a=%h", 
                                                                            load, rst, w, a, psum, psum_out, a_out, expected_p, expected_a);
            ++counter;
    end
        
endtask 

initial begin
    $dumpfile("build/tb_pe.vcd");
    $dumpvars(0, tb_pe);
    $display("");
    $display("----------------------- test starting ---------------------------------------");
    // ---- reset (rst_n = 0): outputs must be 0 despite junk inputs
    check(0, 0,  8'sd9,    8'sd7,    32'sd123,      0,       0);
    check(0, 0,  8'sd9,    8'sd7,    32'sd123,      0,       0);
    // release: weight was reset to 0, so psum passes through
    check(0, 1,  8'sd9,    8'sd5,    32'sd7,        7,       5);

    // ---- load / hold
    check(1, 1,  8'sd5,    8'sd0,    32'sd0,        0,       0);  // load 5
    check(0, 1,  8'sd99,   8'sd1,    32'sd0,        5,       1);  // w_in=99 ignored
    check(0, 1,  8'sd99,   8'sd2,    32'sd0,        10,      2);  // still 5

    // ---- signed multiply (psum = 0)
    check(1, 1,  8'sd4,    8'sd0,    32'sd0,        0,       0);  // load 4
    check(0, 1,  8'sd4,    8'sd3,    32'sd0,        12,      3);
    check(0, 1,  8'sd4,   -8'sd3,    32'sd0,       -12,     -3);
    check(1, 1, -8'sd4,    8'sd0,    32'sd0,        0,       0);  // load -4
    check(0, 1, -8'sd4,    8'sd3,    32'sd0,       -12,      3);
    check(0, 1, -8'sd4,   -8'sd3,    32'sd0,        12,     -3);
    check(1, 1, -8'sd128,  8'sd0,    32'sd0,        0,       0);  // load -128
    check(0, 1, -8'sd128, -8'sd128,  32'sd0,        16384,  -128);
    check(1, 1,  8'sd127,  8'sd0,    32'sd0,        0,       0);  // load 127
    check(0, 1,  8'sd127, -8'sd128,  32'sd0,       -16256,  -128);
    check(0, 1,  8'sd127,  8'sd127,  32'sd0,        16129,   127);

    // ---- signed accumulate / sign extension
    check(1, 1,  8'sd1,    8'sd0,    32'sd0,        0,       0);  // load 1
    check(0, 1,  8'sd1,   -8'sd1,    32'sd0,       -1,      -1);  // sign-ext test
    check(1, 1,  8'sd5,    8'sd0,    32'sd0,        0,       0);  // load 5
    check(0, 1,  8'sd5,    8'sd3,   -32'sd100,     -85,      3);
    check(0, 1,  8'sd5,   -8'sd3,   -32'sd50000,   -50015,  -3);
    check(1, 1,  8'sd127,  8'sd0,    32'sd0,        0,       0);  // load 127
    check(0, 1,  8'sd127, -8'sd128,  32'sd1000000,  983744, -128);
    check(1, 1, -8'sd128,  8'sd0,    32'sd0,        0,       0);  // load -128
    check(0, 1, -8'sd128, -8'sd128, -32'sd1000000, -983616, -128);

    // ---- latency: a_out must not change until the clock edge
    a_in = 8'sd7;  @(posedge clk); #1;
    a_in = -8'sd5; #1;
    if (a_out !== 8'sd7) $display("FAIL latency: a_out changed before the clock edge");

    $finish;
end

endmodule   

