`include "lab4/comparador1b.v"
`timescale 1ms/1ms

module tb_comparador1b;
    reg  A, B;
    wire I, MA, MB;
    integer i, errores, casos;

    comparador1b uut (.A(A), .B(B), .I(I), .MA(MA), .MB(MB));

    initial begin $dumpfile("comparador1b.vcd"); $dumpvars(0, tb_comparador1b); end

    initial begin
        errores = 0; casos = 0;
        $display("=============================================");
        $display(" A  B | I MA MB | esp: I MA MB | Resultado");
        $display("=============================================");
        for (i = 0; i < 4; i = i + 1) begin
            {A, B} = i[1:0];
            #10;
            casos = casos + 1;
            if ((I !== (A == B)) || (MA !== (A > B)) || (MB !== (A < B))) begin
                errores = errores + 1;
                $display(" %b  %b | %b  %b  %b |      %b  %b  %b   | FALLO", A, B, I, MA, MB, (A == B), (A > B), (A < B));
            end else
                $display(" %b  %b | %b  %b  %b |      %b  %b  %b   | OK", A, B, I, MA, MB, (A == B), (A > B), (A < B));
        end
        $display("=============================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=============================================");
        $finish;
    end
endmodule
