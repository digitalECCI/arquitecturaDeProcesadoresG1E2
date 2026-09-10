`include "double_dabble_5bit.v"
`include "dd_stage_2d.v"
`timescale 1s/1s

module tb_double_dabble_5bit;

    reg  [4:0] binario;
    wire [3:0] decenas, unidades;

    integer i;
    integer valor;
    reg [3:0] decenas_esp, unidades_esp;
    integer errores, casos;

    double_dabble_5bit uut (
        .binario(binario),
        .decenas(decenas),
        .unidades(unidades)
    );

    initial begin
        $dumpfile("double_dabble_5bit.vcd");
        $dumpvars(0, tb_double_dabble_5bit);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("=========================================================================================");
        $display(" binario  | decenas(DUT) unidades(DUT) | decenas(esp) unidades(esp) | Resultado");
        $display("=========================================================================================");

        // Recorre las 32 combinaciones posibles (0-31)
        for (i = 0; i < 32; i = i + 1) begin
            binario = i[4:0];
            #10;

            valor = i;
            decenas_esp  = valor / 10;
            unidades_esp = valor % 10;
            casos = casos + 1;

            if ((decenas !== decenas_esp) || (unidades !== unidades_esp)) begin
                errores = errores + 1;
                $display("  %2d(%b) |    %0d            %0d          |    %0d            %0d          | FALLO",
                          binario, binario, decenas, unidades, decenas_esp, unidades_esp);
            end else begin
                $display("  %2d(%b) |    %0d            %0d          |    %0d            %0d          | OK",
                          binario, binario, decenas, unidades, decenas_esp, unidades_esp);
            end
        end

        $display("=========================================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=========================================================================================");

        $finish;
    end

endmodule
