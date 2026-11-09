`include "lab4/decod7seg.v"
`timescale 1ms/1ms

module tb_decod7seg;
    reg  [3:0] d;
    wire [6:0] seg;
    integer i, j, errores, casos, duplicados;
    reg [6:0] esperado;
    reg [6:0] patron [0:15];

    decod7seg uut (.d(d), .seg(seg));

    // Modelo de referencia INDEPENDIENTE: segmentos que deben estar encendidos
    // (1 = encendido) en orden {g,f,e,d,c,b,a}. El display es de anodo comun,
    // asi que el patron esperado en 'seg' es el complemento (0 = encendido).
    function [6:0] encendidos;
        input [3:0] x;
        begin
            case (x)
                4'h0: encendidos = 7'b0111111;  // a b c d e f
                4'h1: encendidos = 7'b0000110;  // b c
                4'h2: encendidos = 7'b1011011;  // a b d e g
                4'h3: encendidos = 7'b1001111;  // a b c d g
                4'h4: encendidos = 7'b1100110;  // b c f g
                4'h5: encendidos = 7'b1101101;  // a c d f g
                4'h6: encendidos = 7'b1111101;  // a c d e f g
                4'h7: encendidos = 7'b0000111;  // a b c
                4'h8: encendidos = 7'b1111111;  // todos
                4'h9: encendidos = 7'b1101111;  // a b c d f g
                4'hA: encendidos = 7'b1110111;  // a b c e f g
                4'hB: encendidos = 7'b1111100;  // c d e f g   ("b")
                4'hC: encendidos = 7'b0111001;  // a d e f
                4'hD: encendidos = 7'b1011110;  // b c d e g   ("d")
                4'hE: encendidos = 7'b1111001;  // a d e f g
                4'hF: encendidos = 7'b1110001;  // a e f g
            endcase
        end
    endfunction

    initial begin $dumpfile("decod7seg.vcd"); $dumpvars(0, tb_decod7seg); end

    initial begin
        errores = 0; casos = 0; duplicados = 0;
        $display("=====================================================");
        $display(" d(hex) | seg DUT (gfedcba) | seg esperado | Resultado");
        $display("=====================================================");
        for (i = 0; i < 16; i = i + 1) begin
            d = i[3:0];
            #10;
            esperado  = ~encendidos(d);
            patron[i] = seg;
            casos = casos + 1;
            if (seg !== esperado) begin
                errores = errores + 1;
                $display("   %h    |     %b      |   %b    | FALLO", d, seg, esperado);
            end else
                $display("   %h    |     %b      |   %b    | OK", d, seg, esperado);
        end
        // Propiedad adicional: los 16 simbolos deben ser distinguibles entre si
        for (i = 0; i < 16; i = i + 1)
            for (j = i + 1; j < 16; j = j + 1)
                if (patron[i] === patron[j]) begin
                    duplicados = duplicados + 1;
                    $display(" FALLO: los digitos %h y %h producen el mismo patron %b", i, j, patron[i]);
                end
        casos = casos + 1;
        if (duplicados != 0) errores = errores + 1;
        $display("=====================================================");
        $display(" Unicidad de patrones (16 simbolos distintos): %s", (duplicados == 0) ? "OK" : "FALLO");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================");
        $finish;
    end
endmodule
