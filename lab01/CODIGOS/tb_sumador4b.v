`include "sumador.v"
`include "sumador4b.v"
`timescale 1ms/1ms

module tb_sumador4b;

    reg  [3:0] A, B;
    reg        Ci;
    wire [3:0] S;
    wire       Co;

    integer i, j, k;
    reg [4:0] esperado;   // 5 bits: {Co_esp, S_esp[3:0]}
    integer errores;
    integer casos;

    // Instancia del DUT
    sumador4b uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .S(S),
        .Co(Co)
    );

    initial begin
        $dumpfile("sumador4b.vcd");
        $dumpvars(0, tb_sumador4b);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("===================================================================");
        $display("  A     B    Ci |   S    Co  |  S_esp  Co_esp | Resultado");
        $display("===================================================================");

        // Recorre todas las combinaciones de A (0-15), B (0-15) y Ci (0-1)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A  = i[3:0];
                    B  = j[3:0];
                    Ci = k[0:0];

                    #10;

                    // Modelo de referencia: suma aritmética de 5 bits
                    esperado = A + B + Ci;
                    casos = casos + 1;

                    if ((S !== esperado[3:0]) || (Co !== esperado[4])) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b | %2d(%b) %b | %2d(%b)  %b   | FALLO",
                                  A, A, B, B, Ci, S, S, Co,
                                  esperado[3:0], esperado[3:0], esperado[4]);
                    end else begin
                        $display(" %2d(%b) %2d(%b) %b | %2d(%b) %b | %2d(%b)  %b   | OK",
                                  A, A, B, B, Ci, S, S, Co,
                                  esperado[3:0], esperado[3:0], esperado[4]);
                    end
                end
            end
        end

        $display("===================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===================================================================");

        // Algunos casos puntuales mostrados explícitamente para verificación visual
        $display("");
        $display("Casos de ejemplo:");
        A = 4'd5;  B = 4'd3;  Ci = 0; #10;
        $display(" 5 + 3 + 0  = %0d  (S=%b Co=%b)", S + (Co<<4), S, Co);

        A = 4'd15; B = 4'd1;  Ci = 0; #10;
        $display("15 + 1 + 0  = %0d  (S=%b Co=%b)  <- overflow esperado", S + (Co<<4), S, Co);

        A = 4'd15; B = 4'd15; Ci = 1; #10;
        $display("15 + 15 + 1 = %0d  (S=%b Co=%b)  <- caso maximo", S + (Co<<4), S, Co);

        $finish;
    end

endmodule