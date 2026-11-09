`include "lab4/comparador4b.v"
`include "lab4/comparador1b.v"
`timescale 1ms/1ms
module tb_comparador4b;
    reg  [3:0] A, B;
    wire       Iab, Ma, Mb;
    integer i, j, errores;

    comparador4b dut (.A(A), .B(B), .Iab(Iab), .Ma(Ma), .Mb(Mb));

    initial begin
        $dumpfile("tb_comparador4b.vcd");
        $dumpvars(0, tb_comparador4b);
        errores = 0;
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                A = i; B = j;
                #5;
                if (Iab !== (A == B) || Ma !== (A > B) || Mb !== (A < B)) begin
                    errores = errores + 1;
                    $display("ERROR: A=%0d B=%0d | Iab=%b Ma=%b Mb=%b | esperado Iab=%b Ma=%b Mb=%b",
                             A, B, Iab, Ma, Mb, (A == B), (A > B), (A < B));
                end
                // Las tres salidas deben ser mutuamente excluyentes (one-hot)
                if ((Iab + Ma + Mb) !== 1) begin
                    errores = errores + 1;
                    $display("ERROR one-hot: A=%0d B=%0d | Iab=%b Ma=%b Mb=%b", A, B, Iab, Ma, Mb);
                end
            end
        end
        if (errores == 0) $display("[comparador4b] PASS: 256/256 combinaciones correctas");
        else              $display("[comparador4b] FAIL: %0d errores", errores);
        $finish;
    end
endmodule
