`include "lab4/multiplicador4b.v"
`include "lab4/sumador4b.v"
`include "lab4/sumador.v"
`timescale 1ms/1ms

module tb_multiplicador4b;
    // VERBOSO = 1 imprime la tabla completa (256 filas); 0 imprime solo los fallos
    localparam VERBOSO = 1;

    reg  [3:0] A, B;
    wire [7:0] R_Producto;
    integer i, j, errores, casos;
    reg [7:0] esperado;

    multiplicador4b uut (.A(A), .B(B), .R_Producto(R_Producto));

    initial begin $dumpfile("multiplicador4b.vcd"); $dumpvars(0, tb_multiplicador4b); end

    initial begin
        errores = 0; casos = 0;
        $display("=====================================================================");
        $display("  A    B  | R_Producto (DUT) | esperado | Resultado");
        $display("=====================================================================");
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A = i[3:0]; B = j[3:0];
                #10;
                esperado = i * j;
                casos = casos + 1;
                if (R_Producto !== esperado) begin
                    errores = errores + 1;
                    $display(" %2d(%b) %2d(%b) | %3d (%b) | %3d (%b) | FALLO", A, A, B, B, R_Producto, R_Producto, esperado, esperado);
                end else if (VERBOSO)
                    $display(" %2d(%b) %2d(%b) | %3d (%b) | %3d (%b) | OK", A, A, B, B, R_Producto, R_Producto, esperado, esperado);
            end
        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================");

        $display("");
        $display("Casos de ejemplo:");
        A = 4'd15; B = 4'd15; #10; $display("  15 x 15 = %0d  <- maximo", R_Producto);
        A = 4'd0;  B = 4'd13; #10; $display("   0 x 13 = %0d", R_Producto);
        A = 4'd7;  B = 4'd9;  #10; $display("   7 x  9 = %0d", R_Producto);
        $finish;
    end
endmodule
