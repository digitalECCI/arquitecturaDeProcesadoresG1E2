`include "sumador.v" 
`timescale 1ms/1ms

module tb_sumador;

    // Señales de estímulo y observación
    reg A, B, Ci;
    wire S, Co;

    // Variables auxiliares para el chequeo automático
    integer i;
    reg S_esperado, Co_esperado;
    integer errores;

    // Instancia del DUT (Device Under Test)
    sumador uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .S(S),
        .Co(Co)
    );

    // Volcado de formas de onda para GTKWave
    initial begin
        $dumpfile("sumador.vcd");
        $dumpvars(0, tb_sumador);
    end

    initial begin
        errores = 0;

        $display("=======================================================");
        $display(" A  B  Ci |  S  Co  |  S_esp  Co_esp  | Resultado");
        $display("=======================================================");

        // Recorre las 8 combinaciones posibles de A, B, Ci
        for (i = 0; i < 8; i = i + 1) begin
            {A, B, Ci} = i[2:0];

            #10; // Tiempo para que se propague la lógica combinacional

            // Cálculo del valor esperado (modelo de referencia)
            S_esperado  = A ^ B ^ Ci;
            Co_esperado = (A & B) | (B & Ci) | (A & Ci);

            if ((S !== S_esperado) || (Co !== Co_esperado)) begin
                errores = errores + 1;
                $display(" %b  %b  %b  |  %b   %b  |    %b      %b    | FALLO",
                          A, B, Ci, S, Co, S_esperado, Co_esperado);
            end else begin
                $display(" %b  %b  %b  |  %b   %b  |    %b      %b    | OK",
                          A, B, Ci, S, Co, S_esperado, Co_esperado);
            end
        end

        $display("=======================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (8/8)");
        else
            $display("SE ENCONTRARON %0d ERRORES", errores);
        $display("=======================================================");

        $finish;
    end

endmodule