module op_xnor(
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] y
);
    // XNOR bit a bit; el resultado ocupa solo los 4 bits inferiores.
    assign y = {4'b0000, ~(a ^ b)};
endmodule
