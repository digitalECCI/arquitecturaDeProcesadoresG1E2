module dd_stage_2d (
    input  wire [7:0] bcd_in,      // {decenas, unidades}
    input  wire       bin_bit_in,
    output wire [7:0] bcd_out
);
    wire [3:0] u_corr = (bcd_in[3:0] >= 5) ? (bcd_in[3:0] + 4'd3) : bcd_in[3:0];
    wire [3:0] d_corr = (bcd_in[7:4] >= 5) ? (bcd_in[7:4] + 4'd3) : bcd_in[7:4];

    wire [7:0] corregido = {d_corr, u_corr};

    assign bcd_out = {corregido[6:0], bin_bit_in};
endmodule