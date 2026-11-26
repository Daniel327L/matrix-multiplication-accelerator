module pe #(
    parameter A_W = 8,
    parameter W_W = 8,
    parameter ACC_W = 32 
)(
    input rst_n, clk, load_w,
    input logic signed [W_W-1:0] w_in,
    input logic signed [A_W-1:0] a_in,
    input logic signed [ACC_W-1:0] psum_in,
    output logic signed [A_W-1:0] a_out,
    output logic signed [ACC_W-1:0] psum_out
);

logic signed [W_W-1:0] weight;


always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        psum_out <= '0;
        a_out <= '0;
        weight <= '0;
    end
    else begin
        if(load_w) begin
            weight <= w_in;
        end
        psum_out <= psum_in + a_in*weight;
        a_out <= a_in;
    end
end

endmodule
