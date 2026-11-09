module des_izq(
    input  wire [3:0] a,    // Entrada A de 4 bits
    input  wire [3:0] b,    // Entrada B (no se usa en esta operación, pero mantiene la consistencia de puertos)
    output wire [7:0] R_des_izq    // Salida de 8 bits para la ALU
);

    // Desplazamos 'a' un bit a la izquierda rellenando con cero el LSB.
    // Los bits superiores quedan en cero para completar los 8 bits del bus.
    assign R_des_izq = {4'b0000, a[2:0], 1'b0};

endmodule