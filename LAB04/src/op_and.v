module op_and(
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] y
);
    assign y = {4'b0000, a & b};
endmodule
