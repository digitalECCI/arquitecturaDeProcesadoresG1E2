`include "lab4/uart_tx.v"
`timescale 1ms/1ms

module tb_uart_tx;

    // VERBOSO = 1 imprime una linea por cada uno de los 256 bytes; 0 imprime solo los fallos
    localparam VERBOSO = 1;

    reg        clk, rst, start;
    reg  [7:0] data;
    wire       tx, busy, done;

    localparam integer BIT = 434;            // ciclos por bit: 50 MHz / 115200 = 434.03
    localparam integer FRAME_DONE = 10*BIT - 1;   // flancos entre la caida de tx y el pulso done (derivado del RTL)

    integer errores, casos;
    integer cyc, t_fall, t_done, N0, done_ciclos, nx;
    integer i, t, n_tramas;
    reg [7:0] rx;
    reg       ok;
    reg       armado;
    reg       buscando_fall;     // 1 = el proximo flanco de bajada de tx es el bit de inicio de una trama

    uart_tx uut (.clk(clk), .rst(rst), .start(start), .data(data), .tx(tx), .busy(busy), .done(done));

    initial clk = 0;
    always #10 clk = ~clk;                   // 50 MHz

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx.start);
        $dumpvars(0, tb_uart_tx.data);
        $dumpvars(0, tb_uart_tx.tx);
        $dumpvars(0, tb_uart_tx.busy);
        $dumpvars(0, tb_uart_tx.done);
        $dumpvars(0, tb_uart_tx.rst);
    end

    // ---- Instrumentacion ----
    always @(posedge clk) cyc <= cyc + 1;
    // Solo la PRIMERA caida de cada trama (bit de inicio); las caidas de los bits de datos no cuentan
    always @(negedge tx)  if (armado && buscando_fall) begin t_fall = cyc; buscando_fall = 0; end
    always @(posedge done) if (armado) t_done = cyc;
    always @(negedge clk) if (armado) begin
        if (done === 1'b1) done_ciclos = done_ciclos + 1;
        if ((^{tx, busy, done}) === 1'bx) nx = nx + 1;
    end

    task chk;
        input [8*66-1:0] que;
        input integer obtenido;
        input integer esperado;
        begin
            casos = casos + 1;
            if (obtenido !== esperado) begin
                errores = errores + 1;
                $display("   FALLO: %0s -> obtenido=%0d esperado=%0d", que, obtenido, esperado);
            end else
                $display("   OK   : %0s = %0d", que, obtenido);
        end
    endtask

    // ---------------- Receptor serie de referencia (independiente del DUT) ----------------
    // Detecta el flanco de bajada, muestrea en el CENTRO de cada bit y valida inicio/parada.
    task capturar;
        output [7:0] r;
        output       valido;
        integer b;
        begin
            valido = 1'b1;
            @(negedge tx);
            repeat (BIT/2) @(posedge clk);
            if (tx !== 1'b0) valido = 1'b0;                 // centro del bit de inicio = 0
            for (b = 0; b < 8; b = b + 1) begin
                repeat (BIT) @(posedge clk);
                r[b] = tx;                                  // LSB primero
            end
            repeat (BIT) @(posedge clk);
            if (tx !== 1'b1) valido = 1'b0;                 // centro del bit de parada = 1
        end
    endtask

    // Dispara una trama con un pulso de start de 1 ciclo (invocar alineado a negedge)
    task disparar;
        input [7:0] dato;
        begin
            data = dato; start = 1; N0 = cyc; buscando_fall = 1;
            @(negedge clk);
            start = 0;
            data = ~dato;                                   // los datos cambian tras el start: no deben afectar
        end
    endtask

    task esperar_done;
        begin
            t = 0;
            while (done !== 1'b1 && t < 2000) begin @(negedge clk); t = t + 1; end
        end
    endtask

    initial begin
        errores = 0; casos = 0; cyc = 0; t_fall = 0; t_done = 0; done_ciclos = 0; nx = 0; armado = 0; n_tramas = 0; buscando_fall = 0;
        rst = 1; start = 0; data = 8'h00;
        repeat (4) @(negedge clk);
        rst = 0;
        repeat (3) @(negedge clk);
        armado = 1;

        $display("=====================================================================");
        $display(" uart_tx: %0d ciclos por bit (115200 baudios @ 50 MHz), formato 8N1, LSB primero", BIT);
        $display("=====================================================================");

        // ---------------------------------------------------------------
        $display("\n[1] Linea en reposo");
        #1;
        chk("tx en reposo = 1", tx, 1);
        chk("busy en reposo = 0", busy, 0);
        chk("done en reposo = 0", done, 0);
        repeat (3 * BIT) @(negedge clk);
        chk("tx sigue en 1 sin start (3 tiempos de bit)", tx, 1);

        // ---------------------------------------------------------------
        $display("\n[2] Barrido exhaustivo: los 256 bytes (0x00-0xFF)");
        $display("   byte | rx   | ok trama | caida(ciclos tras start) | caida->done | Resultado");
        for (i = 0; i < 256; i = i + 1) begin
            disparar(i[7:0]);
            casos = casos + 1;
            if (busy !== 1'b1) begin errores = errores + 1; $display("   FALLO: busy no subio tras start (byte %0d)", i); end
            capturar(rx, ok);
            esperar_done;
            #1;
            casos = casos + 1;
            if ((rx !== i[7:0]) || !ok || (t_fall - N0 !== 2) || (t_done - t_fall !== FRAME_DONE) ||
                (busy !== 1'b0) || (done !== 1'b1) || (tx !== 1'b1)) begin
                errores = errores + 1;
                $display("   0x%h | 0x%h |   %b      |        %0d              |   %0d      | FALLO (busy=%b done=%b tx=%b)",
                          i[7:0], rx, ok, t_fall - N0, t_done - t_fall, busy, done, tx);
            end else if (VERBOSO)
                $display("   0x%h | 0x%h |   %b      |        %0d              |   %0d      | OK",
                          i[7:0], rx, ok, t_fall - N0, t_done - t_fall);
            n_tramas = n_tramas + 1;
            @(negedge clk);
        end
        chk("pulsos 'done' acumulados (uno por trama, de 1 ciclo)", done_ciclos, 256);

        // ---------------------------------------------------------------
        $display("\n[3] start durante una trama en curso: se ignora (no reinicia ni encadena otra)");
        repeat (5) @(negedge clk);
        disparar(8'h5A);
        fork
            begin capturar(rx, ok); end
            begin
                repeat (1000) @(negedge clk);
                data = 8'hFF; start = 1;
                @(negedge clk);
                start = 0;
            end
        join
        esperar_done; #1;
        chk("la trama conserva el dato original (0x5A)", rx, 8'h5A);
        chk("trama valida (inicio=0, parada=1)", ok, 1);
        repeat (3 * BIT) @(negedge clk);
        chk("no hubo una segunda trama: tx sigue en 1", tx, 1);
        chk("busy = 0 tras la trama", busy, 0);

        // ---------------------------------------------------------------
        $display("\n[4] start sostenido en 1: tramas consecutivas, separadas 2 ciclos tras done");
        repeat (5) @(negedge clk);
        data = 8'hC3; start = 1; N0 = cyc; buscando_fall = 1;
        @(negedge clk);                       // start permanece en 1; data se mantiene
        capturar(rx, ok);
        chk("trama 1 (0xC3)", rx, 8'hC3);
        esperar_done; #1;
        t = t_done;
        buscando_fall = 1;                    // la caida siguiente es el inicio de la trama 2
        capturar(rx, ok);                     // la segunda trama arranca sola porque start sigue en 1
        start = 0;
        chk("trama 2 (0xC3) encadenada", rx, 8'hC3);
        chk("la trama 2 empieza 2 ciclos despues del done de la 1", t_fall - t, 2);
        esperar_done; #1;
        repeat (3 * BIT) @(negedge clk);
        chk("sin tercera trama al soltar start: tx en 1", tx, 1);
        chk("busy = 0", busy, 0);

        // ---------------------------------------------------------------
        $display("\n[5] Reset asincrono en mitad de una trama");
        repeat (5) @(negedge clk);
        disparar(8'hA7);
        repeat (1500) @(negedge clk);          // dentro del bit de datos 3
        #2 rst = 1; #1;
        chk("tx vuelve a 1 sin flanco de reloj", tx, 1);
        chk("busy = 0 sin flanco de reloj", busy, 0);
        chk("done = 0", done, 0);
        #1 rst = 0;
        @(negedge clk);
        repeat (3 * BIT) @(negedge clk);
        chk("sin trama residual tras el reset: tx en 1", tx, 1);
        disparar(8'h96);
        capturar(rx, ok);
        esperar_done; #1;
        chk("trama normal despues del reset (0x96)", rx, 8'h96);
        chk("trama valida", ok, 1);

        // ---------------------------------------------------------------
        $display("\n[6] Integridad: ninguna muestra con X/Z en tx, busy o done");
        chk("muestras con X/Z", nx, 0);

        $display("\n=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
