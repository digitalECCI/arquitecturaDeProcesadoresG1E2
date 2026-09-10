`include "sumDD.v"
`include "sumador_restador_4bit.v"
`include "double_dabble_5bit.v"
`include "bcd_a_7seg_anodo_comun.v"
`include "dd_stage_2d.v"
`timescale 1s/1s

module tb_sumDD;

    reg  [3:0] A, B;
    reg        operacion;
    wire [6:0] seg_decenas, seg_unidades, seg_signo;
    wire       negativo;

    integer i, j, k;
    integer mag_esp;
    reg     neg_esp;
    reg [3:0] decenas_esp, unidades_esp;
    reg [6:0] seg_decenas_esp, seg_unidades_esp, seg_signo_esp;
    integer errores, casos;

    sumDD uut (
        .A(A),
        .B(B),
        .operacion(operacion),
        .seg_decenas(seg_decenas),
        .seg_unidades(seg_unidades),
        .seg_signo(seg_signo),
        .negativo(negativo)
    );

    // Modelo de referencia del decodificador BCD -> 7 segmentos (independiente del DUT)
    function [6:0] seg_esperado;
        input [3:0] b;
        begin
            case (b)
                4'd0: seg_esperado = 7'b1000000;
                4'd1: seg_esperado = 7'b1111001;
                4'd2: seg_esperado = 7'b0100100;
                4'd3: seg_esperado = 7'b0110000;
                4'd4: seg_esperado = 7'b0011001;
                4'd5: seg_esperado = 7'b0010010;
                4'd6: seg_esperado = 7'b0000010;
                4'd7: seg_esperado = 7'b1111000;
                4'd8: seg_esperado = 7'b0000000;
                4'd9: seg_esperado = 7'b0010000;
                default: seg_esperado = 7'b1111111;
            endcase
        end
    endfunction

    initial begin
        $dumpfile("sumDD.vcd");
        $dumpvars(0, tb_sumDD);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("=====================================================================================");
        $display("  A     B   Op | seg_dec  seg_uni  seg_signo  neg | (esperados)              | Resultado");
        $display("=====================================================================================");

        // Recorre las 512 combinaciones de A(0-15) x B(0-15) x operacion(0-1)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A = i[3:0];
                    B = j[3:0];
                    operacion = k[0:0];

                    #10;

                    // Modelo de referencia end-to-end: magnitud, signo, digitos BCD y 7-seg
                    if (operacion == 0) begin
                        mag_esp = A + B;
                        neg_esp = 1'b0;
                    end else begin
                        if (A >= B) begin
                            mag_esp = A - B;
                            neg_esp = 1'b0;
                        end else begin
                            mag_esp = B - A;
                            neg_esp = 1'b1;
                        end
                    end

                    decenas_esp  = mag_esp / 10;
                    unidades_esp = mag_esp % 10;
                    seg_decenas_esp  = seg_esperado(decenas_esp);
                    seg_unidades_esp = seg_esperado(unidades_esp);
                    seg_signo_esp    = neg_esp ? 7'b0111111 : 7'b1111111;

                    casos = casos + 1;

                    if ((seg_decenas !== seg_decenas_esp) || (seg_unidades !== seg_unidades_esp) ||
                        (seg_signo !== seg_signo_esp) || (negativo !== neg_esp)) begin
                        errores = errores + 1;
                        $display(" %2d(%b) %2d(%b) %b  | %b %b %b %b | %b %b %b %b | FALLO",
                                  A, A, B, B, operacion,
                                  seg_decenas, seg_unidades, seg_signo, negativo,
                                  seg_decenas_esp, seg_unidades_esp, seg_signo_esp, neg_esp);
                    end
                end
            end
        end

        $display("=====================================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================================");

        // Casos de ejemplo con interpretacion decimal
        $display("");
        $display("Casos de ejemplo:");

        A = 4'd9; B = 4'd8; operacion = 0; #10;
        $display(" 9 + 8 = 17  -> seg_decenas=%b seg_unidades=%b seg_signo=%b negativo=%b",
                  seg_decenas, seg_unidades, seg_signo, negativo);

        A = 4'd2; B = 4'd9; operacion = 1; #10;
        $display(" 2 - 9 = -7  -> seg_decenas=%b seg_unidades=%b seg_signo=%b negativo=%b",
                  seg_decenas, seg_unidades, seg_signo, negativo);

        A = 4'd15; B = 4'd15; operacion = 0; #10;
        $display("15 + 15 = 30 -> seg_decenas=%b seg_unidades=%b seg_signo=%b negativo=%b",
                  seg_decenas, seg_unidades, seg_signo, negativo);

        $finish;
    end

endmodule
