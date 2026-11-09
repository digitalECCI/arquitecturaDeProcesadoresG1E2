`include "lab4/sumador.v"
`timescale 1ms/1ms

module tb_sumador;
    reg  A, B, Ci;
    wire S, Co;
    integer i, errores, casos;
    reg S_esp, Co_esp;

    sumador uut (.A(A), .B(B), .Ci(Ci), .S(S), .Co(Co));

    initial begin $dumpfile("sumador.vcd"); $dumpvars(0, tb_sumador); end

    initial begin
        errores = 0; casos = 0;
        $display("=================================================");
        $display(" A  B  Ci | S Co | S_esp Co_esp | Resultado");
        $display("=================================================");
        for (i = 0; i < 8; i = i + 1) begin
            {A, B, Ci} = i[2:0];
            #10;
            {Co_esp, S_esp} = A + B + Ci;     // suma aritmetica de 1 bit (modelo independiente de las compuertas)
            casos = casos + 1;
            if ((S !== S_esp) || (Co !== Co_esp)) begin
                errores = errores + 1;
                $display(" %b  %b  %b  | %b  %b  |   %b     %b    | FALLO", A, B, Ci, S, Co, S_esp, Co_esp);
            end else
                $display(" %b  %b  %b  | %b  %b  |   %b     %b    | OK", A, B, Ci, S, Co, S_esp, Co_esp);
        end
        $display("=================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=================================================");
        $finish;
    end
endmodule
