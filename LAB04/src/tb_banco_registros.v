`include "lab4/banco_registros.v"
`timescale 1ms/1ms

// Se instancian en paralelo las 4 combinaciones de parametros del banco:
//   cfg0: ZERO_R0=0 WRITE_THROUGH=0   (el valor por defecto, usado en lab4)
//   cfg1: ZERO_R0=1 WRITE_THROUGH=0
//   cfg2: ZERO_R0=0 WRITE_THROUGH=1
//   cfg3: ZERO_R0=1 WRITE_THROUGH=1
// y se compara cada una contra un modelo de referencia independiente.
module tb_banco_registros;

    reg        clk, rst, RegWrite;
    reg  [2:0] addrRa, addrRb, addrW;
    reg  [7:0] datW;
    wire [7:0] ra0, rb0, ra1, rb1, ra2, rb2, ra3, rb3;

    integer errores, casos, i, n, semilla;

    banco_registros #(.ZERO_R0(0), .WRITE_THROUGH(0)) d0 (.clk(clk), .rst(rst), .RegWrite(RegWrite),
        .addrRa(addrRa), .addrRb(addrRb), .addrW(addrW), .datW(datW), .datOutRa(ra0), .datOutRb(rb0));
    banco_registros #(.ZERO_R0(1), .WRITE_THROUGH(0)) d1 (.clk(clk), .rst(rst), .RegWrite(RegWrite),
        .addrRa(addrRa), .addrRb(addrRb), .addrW(addrW), .datW(datW), .datOutRa(ra1), .datOutRb(rb1));
    banco_registros #(.ZERO_R0(0), .WRITE_THROUGH(1)) d2 (.clk(clk), .rst(rst), .RegWrite(RegWrite),
        .addrRa(addrRa), .addrRb(addrRb), .addrW(addrW), .datW(datW), .datOutRa(ra2), .datOutRb(rb2));
    banco_registros #(.ZERO_R0(1), .WRITE_THROUGH(1)) d3 (.clk(clk), .rst(rst), .RegWrite(RegWrite),
        .addrRa(addrRa), .addrRb(addrRb), .addrW(addrW), .datW(datW), .datOutRa(ra3), .datOutRb(rb3));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin $dumpfile("banco_registros.vcd"); $dumpvars(0, tb_banco_registros); end

    // ---------------- Modelo de referencia ----------------
    reg [7:0] m [0:31];                // m[cfg*8 + direccion]
    integer c, k;

    initial for (k = 0; k < 32; k = k + 1) m[k] = 8'h00;   // los registros del DUT arrancan en 0

    // Actualizacion del modelo en cada flanco (las entradas son estables en el posedge)
    always @(posedge clk) begin
        for (c = 0; c < 4; c = c + 1) begin
            if (rst) begin
                for (k = 0; k < 8; k = k + 1) m[c*8 + k] = 8'h00;
            end else if (RegWrite && !((c % 2) == 1 && addrW == 3'd0)) begin
                m[c*8 + addrW] = datW;   // con ZERO_R0=1 (cfg impar) no se escribe r0
            end
        end
    end

    // Lectura esperada (combinacional): r0=0 -> forwarding -> contenido
    function [7:0] lectura_esp;
        input integer cfg;
        input [2:0]   a;
        begin
            if ((cfg % 2) == 1 && a == 3'd0)                                  lectura_esp = 8'h00;
            else if ((cfg / 2) == 1 && RegWrite && !rst && a == addrW)        lectura_esp = datW;
            else                                                              lectura_esp = m[cfg*8 + a];
        end
    endfunction

    task comparar_todo;
        input [8*40-1:0] que;
        begin
            casos = casos + 8;
            if (ra0 !== lectura_esp(0, addrRa) || rb0 !== lectura_esp(0, addrRb) ||
                ra1 !== lectura_esp(1, addrRa) || rb1 !== lectura_esp(1, addrRb) ||
                ra2 !== lectura_esp(2, addrRa) || rb2 !== lectura_esp(2, addrRb) ||
                ra3 !== lectura_esp(3, addrRa) || rb3 !== lectura_esp(3, addrRb)) begin
                errores = errores + 1;
                $display(" FALLO [%0t ns] %0s | Ra=%0d Rb=%0d W=%0d we=%b rst=%b dat=%h", $time, que, addrRa, addrRb, addrW, RegWrite, rst, datW);
                $display("        DUT : ra0=%h rb0=%h | ra1=%h rb1=%h | ra2=%h rb2=%h | ra3=%h rb3=%h", ra0, rb0, ra1, rb1, ra2, rb2, ra3, rb3);
                $display("        MOD : ra0=%h rb0=%h | ra1=%h rb1=%h | ra2=%h rb2=%h | ra3=%h rb3=%h",
                    lectura_esp(0, addrRa), lectura_esp(0, addrRb), lectura_esp(1, addrRa), lectura_esp(1, addrRb),
                    lectura_esp(2, addrRa), lectura_esp(2, addrRb), lectura_esp(3, addrRa), lectura_esp(3, addrRb));
            end
        end
    endtask

    // Comprobacion explicita de un valor (independiente del modelo)
    task exacto;
        input [8*52-1:0] que;
        input [7:0] obtenido;
        input [7:0] esperado;
        begin
            casos = casos + 1;
            if (obtenido !== esperado) begin
                errores = errores + 1;
                $display("   FALLO: %0s -> obtenido=%h esperado=%h", que, obtenido, esperado);
            end else
                $display("   OK   : %0s = %h", que, obtenido);
        end
    endtask

    // Escritura de un ciclo (invocar alineado a negedge; regresa alineado al siguiente)
    task escribir;
        input [2:0] a;
        input [7:0] d;
        begin
            RegWrite = 1; addrW = a; datW = d;
            @(negedge clk);
            RegWrite = 0;
        end
    endtask

    initial begin
        errores = 0; casos = 0; semilla = 32'hB4A5C0DE;
        rst = 0; RegWrite = 0; addrRa = 0; addrRb = 0; addrW = 0; datW = 0;

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 1) Valores iniciales: los 8 registros leen 0 antes de cualquier escritura");
        $display("=====================================================================");
        #1;
        for (i = 0; i < 8; i = i + 1) begin
            addrRa = i[2:0]; addrRb = 3'd7 - i[2:0]; #1;
            exacto("lectura inicial ra0", ra0, 8'h00);
            exacto("lectura inicial rb0", rb0, 8'h00);
        end
        @(negedge clk);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 2) Escribir cada registro con un valor distinto y leerlo por AMBOS puertos");
        $display("=====================================================================");
        for (i = 1; i < 8; i = i + 1) escribir(i[2:0], 8'h10 + i[7:0] * 8'h11);   // r1=21, r2=32, ... r7=87
        for (i = 1; i < 8; i = i + 1) begin
            addrRa = i[2:0]; addrRb = (i[2:0] == 3'd7) ? 3'd1 : i[2:0] + 3'd1; #1;
            comparar_todo("lectura de r1..r7 por Ra y Rb");
        end
        addrRa = 3'd3; addrRb = 3'd6; #1;
        exacto("cfg0 Ra=r3 (esperado 10h+3*11h = 43h)", ra0, 8'h43);
        exacto("cfg0 Rb=r6 (esperado 10h+6*11h = 76h)", rb0, 8'h76);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 3) RegWrite=0 no escribe, aunque addrW y datW cambien");
        $display("=====================================================================");
        RegWrite = 0; addrW = 3'd3; datW = 8'hFF;
        @(negedge clk); @(negedge clk);
        addrRa = 3'd3; #1;
        exacto("r3 intacto con RegWrite=0 (cfg0)", ra0, 8'h43);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 4) Registro r0: normal en cfg0/cfg2, cableado a 0 en cfg1/cfg3");
        $display("=====================================================================");
        escribir(3'd0, 8'hA5);
        addrRa = 3'd0; addrRb = 3'd0; #1;
        exacto("cfg0 (ZERO_R0=0) r0 guarda A5", ra0, 8'hA5);
        exacto("cfg1 (ZERO_R0=1) r0 vale 0",    ra1, 8'h00);
        exacto("cfg2 (ZERO_R0=0) r0 guarda A5", ra2, 8'hA5);
        exacto("cfg3 (ZERO_R0=1) r0 vale 0",    ra3, 8'h00);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 5) Lectura en el mismo ciclo de la escritura (read-during-write)");
        $display("=====================================================================");
        escribir(3'd6, 8'h11);
        RegWrite = 1; addrW = 3'd6; datW = 8'hC3; addrRa = 3'd6; addrRb = 3'd6; #1;
        exacto("sin WRITE_THROUGH (cfg0): valor anterior", ra0, 8'h11);
        exacto("sin WRITE_THROUGH (cfg1): valor anterior", ra1, 8'h11);
        exacto("con WRITE_THROUGH (cfg2): dato nuevo",     ra2, 8'hC3);
        exacto("con WRITE_THROUGH (cfg3): dato nuevo",     ra3, 8'hC3);
        @(negedge clk);
        RegWrite = 0; #1;
        exacto("tras el flanco, todas leen el dato escrito (cfg0)", ra0, 8'hC3);
        exacto("tras el flanco, todas leen el dato escrito (cfg3)", ra3, 8'hC3);

        // WRITE_THROUGH con r0 cableado a 0: el cero tiene prioridad
        RegWrite = 1; addrW = 3'd0; datW = 8'h5A; addrRa = 3'd0; #1;
        exacto("cfg3: forwarding a r0 NO rompe ZERO_R0", ra3, 8'h00);
        exacto("cfg2: forwarding a r0 (sin ZERO_R0)",    ra2, 8'h5A);
        @(negedge clk); RegWrite = 0;

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 6) Reset SINCRONO: no actua entre flancos; el forwarding se inhibe en reset");
        $display("=====================================================================");
        addrRa = 3'd6; addrRb = 3'd5; #1;
        exacto("antes del reset r6", ra0, 8'hC3);
        #2 rst = 1; #1;                                   // entre flancos (el posedge llega 2 ns despues)
        exacto("rst=1 sin flanco: r6 todavia conserva su valor", ra0, 8'hC3);
        RegWrite = 1; addrW = 3'd6; datW = 8'hED; #1;
        exacto("rst=1 + forwarding: cfg2 NO reenvia datW", ra2, 8'hC3);
        @(negedge clk);                                   // paso un flanco con rst=1
        RegWrite = 0; rst = 0; #1;
        exacto("tras el flanco con rst=1: r6 = 0 (cfg0)", ra0, 8'h00);
        exacto("tras el flanco con rst=1: r5 = 0 (cfg0)", rb0, 8'h00);
        exacto("tras el flanco con rst=1: r6 = 0 (cfg3)", ra3, 8'h00);
        comparar_todo("estado tras reset vs modelo");
        @(negedge clk);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 7) Aleatorio: 20000 ciclos, 4 configuraciones, 2 puertos, contra el modelo");
        $display("=====================================================================");
        for (n = 0; n < 20000; n = n + 1) begin
            rst      = (($random(semilla) & 32'h3F) == 0);
            RegWrite = $random(semilla);
            addrRa   = $random(semilla);
            addrRb   = $random(semilla);
            addrW    = $random(semilla);
            datW     = $random(semilla);
            #1;
            comparar_todo("aleatorio");
            @(negedge clk);
        end
        rst = 0; RegWrite = 0;

        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
