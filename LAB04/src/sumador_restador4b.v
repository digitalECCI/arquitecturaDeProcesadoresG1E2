module sumador_restador4b (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       sub,    // 0 = suma, 1 = resta
    output wire [4:0] R       // {Co, S}
);
    wire [3:0] B_x = B ^ {4{sub}};        // invierte B solo en resta
    assign R = {1'b0, A} + {1'b0, B_x} + {4'b0, sub};
endmodule