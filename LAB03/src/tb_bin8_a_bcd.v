`include "bin8_a_bcd.v"
`timescale 1ns/1ps

module tb_bin8_a_bcd;

    reg  [7:0] binario;
    wire [3:0] centenas, decenas, unidades;

    integer i, valor;
    reg [3:0] centenas_esp, decenas_esp, unidades_esp;
    integer errores, casos;

    bin8_a_bcd uut (
        .binario(binario),
        .centenas(centenas),
        .decenas(decenas),
        .unidades(unidades)
    );

    initial begin
        $dumpfile("bin8_a_bcd.vcd");
        $dumpvars(0, tb_bin8_a_bcd);
    end

    initial begin
        errores = 0; casos = 0;

        $display("=========================================================================");
        $display(" binario | cen(DUT) dec(DUT) uni(DUT) | cen(esp) dec(esp) uni(esp) | Resultado");
        $display("=========================================================================");

        for (i = 0; i < 256; i = i + 1) begin
            binario = i[7:0];
            #10;

            valor = i;
            centenas_esp = valor / 100;
            decenas_esp  = (valor / 10) % 10;
            unidades_esp = valor % 10;
            casos = casos + 1;

            if ((centenas !== centenas_esp) || (decenas !== decenas_esp) || (unidades !== unidades_esp)) begin
                errores = errores + 1;
                $display(" %3d(%b) |   %0d        %0d        %0d      |   %0d        %0d        %0d     | FALLO",
                          binario, binario, centenas, decenas, unidades, centenas_esp, decenas_esp, unidades_esp);
            end
        end

        $display("=========================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=========================================================================");

        // Casos de ejemplo
        $display("");
        $display("Casos de ejemplo:");
        binario = 8'd0;   #10; $display("   0 -> cen=%0d dec=%0d uni=%0d", centenas, decenas, unidades);
        binario = 8'd9;   #10; $display("   9 -> cen=%0d dec=%0d uni=%0d", centenas, decenas, unidades);
        binario = 8'd99;  #10; $display("  99 -> cen=%0d dec=%0d uni=%0d", centenas, decenas, unidades);
        binario = 8'd100; #10; $display(" 100 -> cen=%0d dec=%0d uni=%0d", centenas, decenas, unidades);
        binario = 8'd225; #10; $display(" 225 -> cen=%0d dec=%0d uni=%0d  <- max producto 15x15", centenas, decenas, unidades);
        binario = 8'd255; #10; $display(" 255 -> cen=%0d dec=%0d uni=%0d  <- max valor de 8 bits", centenas, decenas, unidades);

        $finish;
    end

endmodule
