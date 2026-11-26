module GEMM_top #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter A_W = 8,
    parameter W_W = 8,
    localparam MIN_ACC_W = A_W + W_W + $clog2(ROWS)
);



endmodule




