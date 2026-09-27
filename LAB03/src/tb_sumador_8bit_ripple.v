`include "sumador_8bit_ripple.v"
`include "full_adder_1bit.v"
`timescale 1ns/1ns

module tb_sumador_8bit_ripple;

    reg  [7:0] A, B;
    reg        cin;
    wire [7:0] suma;
    wire       cout;

    integer i, j, k;
    reg [8:0] esperado; // {cout_esp, suma_esp[7:0]}
    integer errores, casos;

    sumador_8bit_ripple uut (
        .A(A), .B(B), .cin(cin),
        .suma(suma), .cout(cout)
    );

    initial begin
        $dumpfile("sumador_8bit_ripple.vcd");
        // Solo se vuelcan las señales de este testbench (no las internas de cada full adder)
        // para mantener el .vcd en un tamaño razonable dado el numero de casos (131072).
        $dumpvars(1, tb_sumador_8bit_ripple);
    end

    initial begin
        errores = 0; casos = 0;

        $display("=====================================================");
        $display("Prueba exhaustiva: A(0-255) x B(0-255) x cin(0-1) = 131072 casos");
        $display("Solo se imprimen los casos que fallen.");
        $display("=====================================================");

        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                for (k = 0; k < 2; k = k + 1) begin
                    A   = i[7:0];
                    B   = j[7:0];
                    cin = k[0:0];

                    #10;

                    esperado = A + B + cin;
                    casos = casos + 1;

                    if ((suma !== esperado[7:0]) || (cout !== esperado[8])) begin
                        errores = errores + 1;
                        $display(" A=%3d(%b) B=%3d(%b) cin=%b | suma=%3d(%b) cout=%b | esp_suma=%3d(%b) esp_cout=%b | FALLO",
                                  A, A, B, B, cin, suma, suma, cout,
                                  esperado[7:0], esperado[7:0], esperado[8]);
                    end
                end
            end
        end

        $display("=====================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================");

        // Casos de ejemplo
        $display("");
        $display("Casos de ejemplo:");
        A = 8'd200; B = 8'd100; cin = 0; #10;
        $display(" 200 + 100       = %0d  (suma=%b cout=%b)  <- overflow esperado (300 no cabe en 8 bits)", suma, suma, cout);
        A = 8'd255; B = 8'd255; cin = 1; #10;
        $display(" 255 + 255 + 1   = %0d  (suma=%b cout=%b)  <- caso maximo", suma, suma, cout);

        $finish;
    end

endmodule
