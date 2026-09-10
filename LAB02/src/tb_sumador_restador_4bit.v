`include "sumador_restador_4bit.v"
`timescale 1ms/1ms

module tb_sumador_restador_4bit;

    reg  [3:0] A, B;
    reg        operacion;
    wire [4:0] resultado_bin;
    wire       negativo;

    integer i, j, k;
    integer suma_esp;
    reg [4:0] mag_esp;
    reg       neg_esp;
    integer errores, casos;

    sumador_restador_4bit uut (
        .A(A),
        .B(B),
        .operacion(operacion),
        .resultado_bin(resultado_bin),
        .negativo(negativo)
    );

    initial begin
        $dumpfile("sumador_restador_4bit.vcd");
        $dumpvars(0, tb_sumador_restador_4bit);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("===============================================================================");
        $display("  A     B   Op | resultado_bin(DUT) neg(DUT) | resultado_bin(esp) neg(esp) | Res.");
        $display("===============================================================================");

        // Recorre las 512 combinaciones de A(0-15) x B(0-15) x operacion(0-1)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A = i[3:0];
                    B = j[3:0];
                    operacion = k[0:0];

                    #10;

                    if (operacion == 0) begin
                        // Suma: magnitud directa (0-30), nunca negativo
                        mag_esp = A + B;
                        neg_esp = 1'b0;
                    end else begin
                        // Resta: magnitud del valor absoluto, con bandera de signo
                        if (A >= B) begin
                            mag_esp = A - B;
                            neg_esp = 1'b0;
                        end else begin
                            mag_esp = B - A;
                            neg_esp = 1'b1;
                        end
                    end

                    casos = casos + 1;

                    if ((resultado_bin !== mag_esp) || (negativo !== neg_esp)) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b  | %2d(%b)            %b       | %2d(%b)            %b      | FALLO",
                                  A, A, B, B, operacion, resultado_bin, resultado_bin, negativo,
                                  mag_esp, mag_esp, neg_esp);
                    end
                end
            end
        end

        $display("===============================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===============================================================================");

        // Casos de ejemplo
        $display("");
        $display("Casos de ejemplo:");
        A = 4'd9; B = 4'd6; operacion = 0; #10;
        $display(" 9 + 6 = %0d  (resultado_bin=%b, negativo=%b)", resultado_bin, resultado_bin, negativo);

        A = 4'd9; B = 4'd6; operacion = 1; #10;
        $display(" 9 - 6 = %0d  (resultado_bin=%b, negativo=%b)", resultado_bin, resultado_bin, negativo);

        A = 4'd6; B = 4'd9; operacion = 1; #10;
        $display(" 6 - 9 = -%0d (resultado_bin=%b, negativo=%b)", resultado_bin, resultado_bin, negativo);

        $finish;
    end

endmodule
