module sumador4b(
    input  [3:0] A,
    input  [3:0] B,
    input        Ci,       // Acarreo de entrada inicial
    output [4:0] R_suma   // ÚNICA SALIDA: [Co, S] agrupados en 5 bits
);
    // Cables internos para propagar el acarreo entre etapas
    wire c1, c2, c3;
    
    // Cables internos para capturar temporalmente las salidas individuales
    wire [3:0] S;
    wire       Co;

    // Bit 0 (menos significativo): usa el acarreo de entrada Ci
    sumador b0 (
        .A  (A[0]),
        .B  (B[0]),
        .Ci (Ci),
        .S  (S[0]),
        .Co (c1)
    );

    // Bit 1
    sumador b1 (
        .A  (A[1]),
        .B  (B[1]),
        .Ci (c1),
        .S  (S[1]),
        .Co (c2)
    );

    // Bit 2
    sumador b2 (
        .A  (A[2]),
        .B  (B[2]),
        .Ci (c2),
        .S  (S[2]),
        .Co (c3)
    );

    // Bit 3 (más significativo): genera el acarreo de salida final
    sumador b3 (
        .A  (A[3]),
        .B  (B[3]),
        .Ci (c3),
        .S  (S[3]),
        .Co (Co)
    );

    // Concatenación directa hacia el puerto de salida de 5 bits
    assign R_suma = {Co, S};

endmodule
