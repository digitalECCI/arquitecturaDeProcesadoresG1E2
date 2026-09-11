module sumDD (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       operacion,       // 0 = suma, 1 = resta
    output wire [6:0] seg_decenas,
    output wire [6:0] seg_unidades,
    output wire [6:0] seg_signo,       // display extra para el signo "-"
    output wire       negativo
);

    wire [4:0] resultado_bin;

    sumador_restador_4bit ur (
        .A(A),
        .B(B),
        .operacion(operacion),
        .resultado_bin(resultado_bin),
        .negativo(negativo)
    );

    wire [3:0] decenas, unidades;

    double_dabble_5bit dd (
        .binario  (resultado_bin),
        .decenas  (decenas),
        .unidades (unidades)
    );

    bcd_a_7seg_anodo_comun disp_d (.bcd(decenas),  .seg(seg_decenas));
    bcd_a_7seg_anodo_comun disp_u (.bcd(unidades), .seg(seg_unidades));

    // Signo: solo segmento "g" encendido = "-" ; apagado si es positivo
    assign seg_signo = negativo ? 7'b0111111 : 7'b1111111;

endmodule