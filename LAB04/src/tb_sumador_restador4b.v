`include "lab4/sumador_restador4b.v"
`include "lab4/sumador.v"
`timescale 1ms/1ms

module tb_sumador_restador4b;
    // VERBOSO = 1 imprime la tabla completa (512 filas); 0 imprime solo los fallos
    localparam VERBOSO = 1;

    reg  [3:0] A, B;
    reg        Ci;
    wire [4:0] R_resta;
    integer i, j, k, errores, casos;
    reg  [4:0] esp_estructural;     // A + ~B + Ci (definicion de la estructura)
    integer    d;                   // A - B - 1 + Ci (semantica aritmetica)
    reg        co_sem;
    reg  [3:0] s_sem;

    restador4b uut (.A(A), .B(B), .Ci(Ci), .R_resta(R_resta));

    initial begin $dumpfile("restador4b.vcd"); $dumpvars(0, tb_restador4b); end

    initial begin
        errores = 0; casos = 0;
        $display("=============================================================================");
        $display("  A    B   Ci | R_resta={Co,S} | Co esp  S esp | Resultado");
        $display("=============================================================================");
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    A = i[3:0]; B = j[3:0]; Ci = k[0];
                    #10;
                    // 1) definicion estructural: A + (~B) + Ci en 5 bits
                    esp_estructural = {1'b0, A} + {1'b0, ~B} + Ci;
                    // 2) semantica aritmetica: con Ci=1 es A-B (Co=1 <=> A>=B); con Ci=0 es A-B-1 (Co=1 <=> A>B)
                    d      = i - j - 1 + k;
                    co_sem = (d >= 0);
                    s_sem  = d & 15;
                    casos = casos + 1;
                    if ((R_resta !== esp_estructural) || (R_resta[4] !== co_sem) || (R_resta[3:0] !== s_sem)) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b | %2d (%b)      |   %b      %2d    | FALLO", A, A, B, B, Ci, R_resta, R_resta, co_sem, s_sem);
                    end else if (VERBOSO)
                        $display(" %2d(%b) %2d(%b) %b | %2d (%b)      |   %b      %2d    | OK", A, A, B, B, Ci, R_resta, R_resta, co_sem, s_sem);
                end
        $display("=============================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=============================================================================");

        $display("");
        $display("Casos de ejemplo (Ci=1, resta estandar A-B):");
        A = 4'd9; B = 4'd4; Ci = 1; #10; $display("  9 - 4 = %0d  Co=%b (sin prestamo)", R_resta[3:0], R_resta[4]);
        A = 4'd4; B = 4'd9; Ci = 1; #10; $display("  4 - 9 -> S=%0d (=16-5)  Co=%b (hubo prestamo)", R_resta[3:0], R_resta[4]);
        $finish;
    end
endmodule
