`include "full_adder_1bit.v"
`timescale 1ns/1ps

module tb_full_adder_1bit;

    reg  a, b, cin;
    wire sum, cout;

    integer i;
    reg sum_esp, cout_esp;
    integer errores, casos;

    full_adder_1bit uut (
        .a(a), .b(b), .cin(cin),
        .sum(sum), .cout(cout)
    );

    initial begin
        $dumpfile("full_adder_1bit.vcd");
        $dumpvars(0, tb_full_adder_1bit);
    end

    initial begin
        errores = 0; casos = 0;
        $display("=================================================");
        $display(" a  b  cin | sum cout | sum_esp cout_esp | Resultado");
        $display("=================================================");

        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10;

            sum_esp  = a ^ b ^ cin;
            cout_esp = (a & b) | (b & cin) | (a & cin);
            casos = casos + 1;

            if ((sum !== sum_esp) || (cout !== cout_esp)) begin
                errores = errores + 1;
                $display(" %b  %b  %b  |  %b   %b  |    %b       %b     | FALLO", a, b, cin, sum, cout, sum_esp, cout_esp);
            end else begin
                $display(" %b  %b  %b  |  %b   %b  |    %b       %b     | OK", a, b, cin, sum, cout, sum_esp, cout_esp);
            end
        end

        $display("=================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=================================================");

        $finish;
    end

endmodule
