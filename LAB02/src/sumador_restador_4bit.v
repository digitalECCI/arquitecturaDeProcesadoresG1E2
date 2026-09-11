module sumador_restador_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       operacion,      // 0 = suma, 1 = resta
    output wire [4:0] resultado_bin,  // magnitud (0-30 para suma, 0-15 para resta)
    output wire       negativo
);
    wire [4:0] suma  = A + B;                       // 0 a 30, cabe en 5 bits
    wire [4:0] resta = {1'b0, A} - {1'b0, B};        // resta en complemento a 2, 5 bits

    wire resta_es_neg = resta[4];                   // bit de signo del complemento a 2
    wire [4:0] resta_mag = resta_es_neg ? (~resta + 5'd1) : resta; // magnitud (ternario)

    assign resultado_bin = operacion ? resta_mag : suma;
    assign negativo      = operacion & resta_es_neg;

endmodule