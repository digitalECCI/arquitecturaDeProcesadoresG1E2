`include "bcd_a_7seg_anodo_comun.v"
`timescale 1s/1s

module tb_bcd_a_7seg_anodo_comun;

    reg  [3:0] bcd;
    wire [6:0] seg;

    integer i;
    reg [6:0] esperado;
    integer errores, casos;

    bcd_a_7seg_anodo_comun uut (
        .bcd(bcd),
        .seg(seg)
    );

    // Modelo de referencia (misma tabla que el decodificador, para verificación independiente)
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
        $dumpfile("bcd_a_7seg_anodo_comun.vcd");
        $dumpvars(0, tb_bcd_a_7seg_anodo_comun);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("=====================================================");
        $display(" bcd | seg (DUT)  | seg (esp)  | Resultado");
        $display("=====================================================");

        // Recorre las 16 combinaciones de bcd (0-9 validos, 10-15 fuera de rango)
        for (i = 0; i < 16; i = i + 1) begin
            bcd = i[3:0];
            #10;

            esperado = seg_esperado(bcd);
            casos = casos + 1;

            if (seg !== esperado) begin
                errores = errores + 1;
                $display("  %2d | %b   | %b   | FALLO", bcd, seg, esperado);
            end else begin
                $display("  %2d | %b   | %b   | OK", bcd, seg, esperado);
            end
        end

        $display("=====================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================");

        $finish;
    end

endmodule
