`include "lab4/sumador4b.v"
`include "lab4/sumador.v"
`timescale 1ms/1ms

module tb_sumador4b;
    // VERBOSO = 1 imprime la tabla completa (512 filas); 0 imprime solo los fallos
    localparam VERBOSO = 1;

    reg  [3:0] A, B;
    reg        Ci;
    wire [4:0] R_suma;
    integer i, j, k, errores, casos;
    reg [4:0] esperado;

    sumador4b uut (.A(A), .B(B), .Ci(Ci), .R_suma(R_suma));

    initial begin $dumpfile("sumador4b.vcd"); $dumpvars(0, tb_sumador4b); end

    initial begin
        errores = 0; casos = 0;
        $display("=====================================================================");
        $display("  A    B   Ci | R_suma={Co,S} | esperado | Resultado");
        $display("=====================================================================");
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    A = i[3:0]; B = j[3:0]; Ci = k[0];
                    #10;
                    esperado = A + B + Ci;
                    casos = casos + 1;
                    if (R_suma !== esperado) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b | %2d (%b)     | %2d (%b) | FALLO", A, A, B, B, Ci, R_suma, R_suma, esperado, esperado);
                    end else if (VERBOSO)
                        $display(" %2d(%b) %2d(%b) %b | %2d (%b)     | %2d (%b) | OK", A, A, B, B, Ci, R_suma, R_suma, esperado, esperado);
                end
        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
