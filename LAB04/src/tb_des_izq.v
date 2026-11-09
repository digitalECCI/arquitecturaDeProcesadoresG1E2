`include "lab4/des_izq.v"
`timescale 1ms/1ms

module tb_des_izq;
    // VERBOSO = 1 imprime la tabla completa (256 filas); 0 imprime solo los fallos
    localparam VERBOSO = 1;

    reg  [3:0] a, b;
    wire [7:0] y;
    integer i, j, errores, casos;
    reg [7:0] esperado;

    des_izq uut (.a(a), .b(b), .R_des_izq(y));

    initial begin $dumpfile("des_izq.vcd"); $dumpvars(0, tb_des_izq); end

    initial begin
        errores = 0; casos = 0;
        $display("=====================================================================");
        $display(" Operacion: R_des_izq = {0000, a[2:0], 0}  (a << 1 dentro de 4 bits)");
        $display("=====================================================================");
        $display("  a    b   | y (DUT)   | esperado  | Resultado");
        $display("=====================================================================");
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                a = i[3:0]; b = j[3:0];
                #10;
                esperado = {4'b0000, i[2:0], 1'b0};
                casos = casos + 1;
                // Se compara el byte completo: el nibble alto debe ser 0 (la ALU extiende con ceros)
                if (y !== esperado) begin
                    errores = errores + 1;
                    $display(" %2d(%b) %2d(%b) | %b | %b | FALLO", a, a, b, b, y, esperado);
                end else if (VERBOSO)
                    $display(" %2d(%b) %2d(%b) | %b | %b | OK", a, a, b, b, y, esperado);
            end
        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
