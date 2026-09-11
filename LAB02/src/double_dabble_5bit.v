module double_dabble_5bit (
    input  wire [4:0] binario,
    output wire [3:0] decenas,
    output wire [3:0] unidades
);
    wire [7:0] bcd0, bcd1, bcd2, bcd3, bcd4, bcd5;

    assign bcd0 = 8'd0;

    dd_stage_2d s0 (.bcd_in(bcd0), .bin_bit_in(binario[4]), .bcd_out(bcd1));
    dd_stage_2d s1 (.bcd_in(bcd1), .bin_bit_in(binario[3]), .bcd_out(bcd2));
    dd_stage_2d s2 (.bcd_in(bcd2), .bin_bit_in(binario[2]), .bcd_out(bcd3));
    dd_stage_2d s3 (.bcd_in(bcd3), .bin_bit_in(binario[1]), .bcd_out(bcd4));
    dd_stage_2d s4 (.bcd_in(bcd4), .bin_bit_in(binario[0]), .bcd_out(bcd5));

    assign decenas  = bcd5[7:4];
    assign unidades = bcd5[3:0];
endmodule