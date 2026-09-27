`include "multiplicador.v"
`include "sumador_8bit_ripple.v"
`include "full_adder_1bit.v"
`timescale 1ns/1ps

module tb_multiplicador;

    reg clk, rst_global;
    reg [3:0] multiplicando, multiplicador_in;
    reg cargaDatos, suma, despla;
    wire LSB_B, Z;
    wire [7:0] producto;

    integer i, j, n;
    integer esperado;
    integer errores, casos;

    multiplicador uut (
        .clk(clk),
        .rst_global(rst_global),
        .multiplicando(multiplicando),
        .multiplicador(multiplicador_in),
        .cargaDatos(cargaDatos),
        .suma(suma),
        .despla(despla),
        .LSB_B(LSB_B),
        .Z(Z),
        .producto(producto)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("multiplicador.vcd");
        $dumpvars(0, tb_multiplicador);
    end

    // Emula exactamente la secuencia que generaria unidad_control:
    // carga -> (CHECK, [ADD_S], SHIFT) x4
    task multiplicar;
        input [3:0] a_in, b_in;
        begin
            cargaDatos = 0; suma = 0; despla = 0;

            @(negedge clk);
            multiplicando    = a_in;
            multiplicador_in = b_in;
            cargaDatos = 1;
            @(posedge clk); #1;
            @(negedge clk);
            cargaDatos = 0;

            for (n = 0; n < 4; n = n + 1) begin
                // Estado CHECK: se observa LSB_B (combinacional, ya disponible)
                if (LSB_B) begin
                    suma = 1;
                    @(posedge clk); #1;
                    @(negedge clk);
                    suma = 0;
                end
                despla = 1;
                @(posedge clk); #1;
                @(negedge clk);
                despla = 0;
            end
        end
    endtask

    initial begin
        errores = 0; casos = 0;
        rst_global = 1; cargaDatos = 0; suma = 0; despla = 0;
        multiplicando = 0; multiplicador_in = 0;
        @(negedge clk); @(negedge clk);
        rst_global = 0;

        $display("===========================================================");
        $display(" A(multiplicando) x B(multiplicador) | producto(DUT) esperado | Resultado");
        $display("===========================================================");

        // Recorre las 256 combinaciones de A(0-15) x B(0-15)
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                // Reset entre cada prueba para partir de un estado limpio
                rst_global = 1;
                @(negedge clk); @(negedge clk);
                rst_global = 0;

                multiplicar(i[3:0], j[3:0]);

                esperado = i * j;
                casos = casos + 1;

                if (producto !== esperado[7:0]) begin
                    errores = errores + 1;
                    $display("  %2d x %2d | %3d (esp=%3d) | FALLO", i, j, producto, esperado);
                end
            end
        end

        $display("===========================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===========================================================");

        // Casos de ejemplo
        $display("");
        $display("Casos de ejemplo:");
        rst_global = 1; @(negedge clk); @(negedge clk); rst_global = 0;
        multiplicar(4'd5, 4'd3);
        $display(" 5 x 3   = %0d", producto);

        rst_global = 1; @(negedge clk); @(negedge clk); rst_global = 0;
        multiplicar(4'd15, 4'd15);
        $display(" 15 x 15 = %0d  <- caso maximo", producto);

        rst_global = 1; @(negedge clk); @(negedge clk); rst_global = 0;
        multiplicar(4'd0, 4'd9);
        $display(" 0 x 9   = %0d", producto);

        $finish;
    end

endmodule
