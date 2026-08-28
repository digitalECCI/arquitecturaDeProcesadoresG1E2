`include "sumador.v"
`include "sumadorRestador.v"
`timescale 1ms/1ms

module tb_sumadorRestador;

    reg  [3:0] A, B;
    reg        Sub;
    wire [3:0] S;
    wire       Co;

    integer i, j, k;
    integer errores;

    // Valores esperados calculados con aritmetica normal de Verilog
    reg [4:0] esperado_suma;   // 5 bits: incluye el acarreo/borrow
    reg [3:0] S_esp;
    reg       Co_esp;
    reg [3:0] B_neg;           // ~B calculado en 4 bits (evita que el
                                // operador ~ tome el ancho del contexto
                                // de 5 bits y produzca un resultado erroneo)

    // Instancia del DUT (Device Under Test)
    sumadorRestador DUT (
        .A(A),
        .B(B),
        .Sub(Sub),
        .S(S),
        .Co(Co)
    );

    // Dump para GTKWave
    initial begin
        $dumpfile("sumadorRestador.vcd");
        $dumpvars(0, tb_sumadorRestador);
    end

    initial begin
        errores = 0;

        $display("========================================================");
        $display(" Simulacion exhaustiva: sumadorRestador (4 bits)");
        $display("========================================================");
        $display(" %-4s %-4s %-4s | %-4s %-4s | %-8s %-8s | %-4s",
                  "A", "B", "Sub", "S", "Co", "S_esp", "Co_esp", "OK?");
        $display("--------------------------------------------------------");

        // Barrido exhaustivo: A (0-15) x B (0-15) x Sub (0-1) = 512 casos
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A   = i[3:0];
                    B   = j[3:0];
                    Sub = k[0:0];

                    #10; // tiempo para que se propague la logica

                    if (Sub == 1'b0) begin
                        // Suma: A + B, resultado de 5 bits (S + Co)
                        esperado_suma = A + B;
                        S_esp  = esperado_suma[3:0];
                        Co_esp = esperado_suma[4];
                    end else begin
                        // Resta: A - B en complemento a 2
                        // {Co_esp, S_esp} = A + (~B, en 4 bits) + 1
                        B_neg = ~B;
                        esperado_suma = A + B_neg + 1'b1;
                        S_esp  = esperado_suma[3:0];
                        // Co_esp = 1 indica "no hubo prestamo" (A >= B)
                        Co_esp = esperado_suma[4];
                    end

                    if ((S !== S_esp) || (Co !== Co_esp)) begin
                        errores = errores + 1;
                        $display(" %-4d %-4d %-4d | %-4d %-4d | %-8d %-8d | %-4s  <-- FALLO",
                                  A, B, Sub, S, Co, S_esp, Co_esp, "NO");
                    end
                end
            end
        end

        $display("--------------------------------------------------------");
        if (errores == 0)
            $display(" RESULTADO: Todos los 512 casos pasaron correctamente.");
        else
            $display(" RESULTADO: %0d casos fallaron de 512.", errores);
        $display("========================================================");

        $finish;
    end

endmodule
