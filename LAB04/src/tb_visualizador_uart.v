`include "lab4/visualizador_uart.v"
`timescale 1ms/1ms

// El visualizador se prueba aislado, con un modelo simple de la memoria (lectura combinacional,
// como banco_registros) y un UART simulado cuyo retardo de 'tx_done' es configurable.
module tb_visualizador_uart;

    reg        clk, rst, start;
    wire [2:0] addr;
    wire       read_en;
    wire [7:0] data_out;
    wire       tx_start;
    wire [7:0] tx_data;
    wire       busy;
    wire       tx_done_w;

    reg [7:0] mem [0:7];
    assign data_out = mem[addr];            // lectura combinacional de la "memoria"

    integer errores, casos, i, k, n, semilla;

    visualizador_uart uut (
        .clk(clk), .rst(rst), .start(start),
        .addr(addr), .read_en(read_en), .data_out(data_out),
        .tx_start(tx_start), .tx_data(tx_data), .tx_done(tx_done_w),
        .busy(busy)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin $dumpfile("visualizador_uart.vcd"); $dumpvars(0, tb_visualizador_uart); end

    // ---------------- UART simulado ----------------
    reg     tx_done_m, spur, pend, aleatorio;
    integer cnt, d_cfg, suma_d;
    assign tx_done_w = tx_done_m | spur;

    always @(posedge clk) begin
        tx_done_m <= 1'b0;
        if (tx_start) begin
            pend = 1; cnt = d_cfg;
            suma_d = suma_d + d_cfg;
            if (aleatorio) d_cfg = $random(semilla) & 32'h1F;       // retardo del siguiente byte: 0..31
        end else if (pend) begin
            if (cnt == 0) begin tx_done_m <= 1'b1; pend = 0; end
            else cnt = cnt - 1;
        end
    end

    // ---------------- Monitores (muestrean antes de cada flanco) ----------------
    integer nread, ntx, busy_ciclos, viol_busy, viol_pulso;
    reg [2:0] addr_log [0:63];
    reg [7:0] data_log [0:63];
    reg       read_prev, txs_prev;
    reg       contando;

    always @(posedge clk) begin
        if (read_en)  begin addr_log[nread] = addr;    nread = nread + 1; end
        if (tx_start) begin data_log[ntx]   = tx_data; ntx   = ntx + 1;   end
        if (busy === 1'b1) busy_ciclos = busy_ciclos + 1;
        // invariante: fuera de IDLE, busy debe valer 1
        if (uut.state !== 3'd0 && busy !== 1'b1) viol_busy = viol_busy + 1;
        // los pulsos de read_en y tx_start deben durar exactamente 1 ciclo
        if ((read_en && read_prev) || (tx_start && txs_prev)) viol_pulso = viol_pulso + 1;
        read_prev = read_en; txs_prev = tx_start;
    end

    task chk;
        input [8*62-1:0] que;
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

    task limpiar_logs;
        begin
            nread = 0; ntx = 0; busy_ciclos = 0; viol_busy = 0; viol_pulso = 0; suma_d = 0;
            read_prev = 0; txs_prev = 0;
        end
    endtask

    task llenar_mem;
        integer q;
        begin for (q = 0; q < 8; q = q + 1) mem[q] = $random(semilla); end
    endtask

    // Verifica una secuencia de 'nsec' recorridos completos de las 8 direcciones
    task verificar_secuencia;
        input integer nsec;
        input [8*40-1:0] que;
        integer q, bad;
        begin
            bad = 0;
            for (q = 0; q < 8*nsec; q = q + 1) begin
                if (addr_log[q] !== (q % 8))        bad = bad + 1;
                if (data_log[q] !== mem[q % 8])     bad = bad + 1;
            end
            casos = casos + 1;
            if ((nread != 8*nsec) || (ntx != 8*nsec) || bad != 0 || viol_busy != 0 || viol_pulso != 0) begin
                errores = errores + 1;
                $display("   FALLO: %0s | lecturas=%0d tx_start=%0d (esperado %0d) discrepancias=%0d busy_viol=%0d pulso_viol=%0d",
                          que, nread, ntx, 8*nsec, bad, viol_busy, viol_pulso);
            end else
                $display("   OK   : %0s | %0d lecturas (addr 0..7 en orden), %0d tx_start con tx_data = contenido de cada direccion", que, nread, ntx);
        end
    endtask

    // Pulso de start de 1 ciclo y espera a que busy vuelva a 0
    task correr;
        integer lim;
        begin
            @(negedge clk);
            start = 1; @(negedge clk); start = 0;
            lim = 0;
            while ((busy !== 1'b0 || lim < 3) && lim < 20000) begin @(negedge clk); lim = lim + 1; end
            repeat (3) @(negedge clk);
        end
    endtask

    integer dd;
    integer vd [0:5];

    initial begin
        errores = 0; casos = 0; semilla = 32'h5EED0001;
        rst = 1; start = 0; spur = 0; pend = 0; aleatorio = 0; d_cfg = 0; cnt = 0; tx_done_m = 0;
        limpiar_logs;
        vd[0] = 0; vd[1] = 1; vd[2] = 2; vd[3] = 7; vd[4] = 40; vd[5] = 300;
        repeat (3) @(negedge clk);
        rst = 0; @(negedge clk);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 1) Reposo tras reset: sin actividad");
        $display("=====================================================================");
        #1;
        chk("busy = 0", busy, 0);
        chk("read_en = 0", read_en, 0);
        chk("tx_start = 0", tx_start, 0);
        chk("addr = 0", addr, 0);
        repeat (20) @(negedge clk);
        chk("sin start no hay lecturas ni envios (lecturas)", nread, 0);
        chk("sin start no hay lecturas ni envios (tx_start)", ntx, 0);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 2) Recorrido completo con retardos de tx_done fijos de 0, 1, 2, 7, 40 y 300 ciclos");
        $display("    duracion de busy esperada (derivada del FSM) = 57 + suma de retardos");
        $display("=====================================================================");
        for (dd = 0; dd < 6; dd = dd + 1) begin
            llenar_mem; limpiar_logs; d_cfg = vd[dd]; aleatorio = 0; pend = 0;
            correr;
            verificar_secuencia(1, "retardo fijo");
            chk("duracion de busy (ciclos)", busy_ciclos, 57 + suma_d);
            chk("suma de retardos observada (8 bytes x d)", suma_d, 8 * vd[dd]);
            chk("addr vuelve a 0 en reposo", addr, 0);
            chk("busy = 0 al terminar", busy, 0);
        end

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 3) 40 recorridos con retardos aleatorios (0..31) y contenido aleatorio");
        $display("=====================================================================");
        aleatorio = 1;
        for (n = 0; n < 40; n = n + 1) begin
            llenar_mem; limpiar_logs; d_cfg = $random(semilla) & 32'h1F; pend = 0;
            correr;
            casos = casos + 1;
            if ((nread != 8) || (ntx != 8) || (busy_ciclos != 57 + suma_d) || (viol_busy != 0) || (viol_pulso != 0)) begin
                errores = errores + 1;
                $display("   FALLO recorrido %0d: lecturas=%0d tx=%0d busy=%0d (esperado %0d)", n, nread, ntx, busy_ciclos, 57 + suma_d);
            end
            for (k = 0; k < 8; k = k + 1) begin
                casos = casos + 1;
                if ((addr_log[k] !== k) || (data_log[k] !== mem[k])) begin
                    errores = errores + 1;
                    $display("   FALLO recorrido %0d byte %0d: addr=%0d dato=%h esperado=%h", n, k, addr_log[k], data_log[k], mem[k]);
                end
            end
        end
        $display("   (40 recorridos verificados)");
        aleatorio = 0;

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 4) start durante la operacion: se ignora (no reinicia ni duplica)");
        $display("=====================================================================");
        llenar_mem; limpiar_logs; d_cfg = 5; pend = 0;
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        repeat (30) @(negedge clk);
        start = 1; @(negedge clk); start = 0;             // start espurio a mitad de la secuencia
        repeat (25) @(negedge clk);
        start = 1; @(negedge clk); start = 0;
        while (busy !== 1'b0) @(negedge clk);
        repeat (3) @(negedge clk);
        verificar_secuencia(1, "start espurio ignorado");
        chk("duracion de busy no se altera", busy_ciclos, 57 + suma_d);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 5) tx_done espurio fuera de WAIT_TX: se ignora");
        $display("=====================================================================");
        llenar_mem; limpiar_logs; d_cfg = 20; pend = 0;
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        // pulsos de tx_done durante READ / WAIT_READ / SEND del primer byte
        spur = 1; @(negedge clk); spur = 0;
        spur = 1; @(negedge clk); spur = 0;
        spur = 1; @(negedge clk); spur = 0;
        while (busy !== 1'b0) @(negedge clk);
        repeat (3) @(negedge clk);
        verificar_secuencia(1, "tx_done espurio ignorado");

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 6) start sostenido en 1: encadena recorridos; al soltarlo se detiene");
        $display("=====================================================================");
        llenar_mem; limpiar_logs; d_cfg = 3; pend = 0;
        @(negedge clk); start = 1;
        while (nread < 16) @(negedge clk);                 // espera a que arranque el segundo recorrido completo
        start = 0;
        while (busy !== 1'b0) @(negedge clk);
        repeat (3) @(negedge clk);
        casos = casos + 1;
        if (nread < 16 || nread > 24 || (nread % 8) != 0) begin
            errores = errores + 1; $display("   FALLO: lecturas=%0d, se esperaban recorridos completos (16 o 24)", nread);
        end else
            $display("   OK   : %0d lecturas (%0d recorridos completos encadenados)", nread, nread / 8);
        chk("busy nunca bajo entre recorridos (violaciones)", viol_busy, 0);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 7) Reset asincrono a mitad de la secuencia");
        $display("=====================================================================");
        llenar_mem; limpiar_logs; d_cfg = 50; pend = 0;
        @(negedge clk); start = 1; @(negedge clk); start = 0;
        repeat (80) @(negedge clk);                        // a mitad de la transmision del segundo byte
        #2 rst = 1; #1;
        chk("busy = 0 sin flanco", busy, 0);
        chk("read_en = 0 sin flanco", read_en, 0);
        chk("tx_start = 0 sin flanco", tx_start, 0);
        chk("addr = 0 sin flanco", addr, 0);
        chk("estado = IDLE sin flanco", uut.state, 0);
        #1 rst = 0; pend = 0;
        repeat (100) @(negedge clk);
        limpiar_logs; llenar_mem; d_cfg = 4;
        correr;
        verificar_secuencia(1, "recorrido completo tras el reset");

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 8) Recuperacion desde estados ilegales (6 y 7)");
        $display("=====================================================================");
        for (n = 6; n <= 7; n = n + 1) begin
            uut.state = n[2:0];
            @(negedge clk);
            #1;
            chk("regresa a IDLE", uut.state, 0);
            chk("busy = 0", busy, 0);
            chk("read_en = 0", read_en, 0);
            chk("tx_start = 0", tx_start, 0);
        end

        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
