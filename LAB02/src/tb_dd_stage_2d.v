`include "dd_stage_2d.v"
`timescale 1s/1s

module tb_dd_stage_2d;

    reg  [7:0] bcd_in;
    reg        bin_bit_in;
    wire [7:0] bcd_out;

    integer i, k;
    reg [3:0] u_corr, d_corr;
    reg [7:0] corregido, esperado;
    integer errores, casos;

    dd_stage_2d uut (
        .bcd_in(bcd_in),
        .bin_bit_in(bin_bit_in),
        .bcd_out(bcd_out)
    );

    initial begin
        $dumpfile("dd_stage_2d.vcd");
        $dumpvars(0, tb_dd_stage_2d);
    end

    initial begin
        errores = 0;
        casos   = 0;

        $display("===========================================================");
        $display(" bcd_in    bit_in | bcd_out (DUT) | bcd_out (esp) | Resultado");
        $display("===========================================================");

        // Recorre las 256 combinaciones de bcd_in x 2 de bin_bit_in = 512 casos
        for (i = 0; i < 256; i = i + 1) begin
            for (k = 0; k < 2; k = k + 1) begin
                bcd_in     = i[7:0];
                bin_bit_in = k[0:0];

                #10;

                // Modelo de referencia: replica la regla "suma 3 si >=5" y el shift
                u_corr = (bcd_in[3:0] >= 5) ? (bcd_in[3:0] + 4'd3) : bcd_in[3:0];
                d_corr = (bcd_in[7:4] >= 5) ? (bcd_in[7:4] + 4'd3) : bcd_in[7:4];
                corregido = {d_corr, u_corr};
                esperado  = {corregido[6:0], bin_bit_in};

                casos = casos + 1;

                if (bcd_out !== esperado) begin
                    errores = errores + 1;
                    $display(" %b  %b       | %b     | %b     | FALLO",
                              bcd_in, bin_bit_in, bcd_out, esperado);
                end
            end
        end

        $display("===========================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===========================================================");

        $finish;
    end

endmodule
