`include "lab4/button_pulse.v"
`timescale 1ms/1ms

module tb_button_pulse;

    reg  clk, rst, btn;
    wire pulse;

    integer errores, casos;

    // ---- Instrumentacion ----
    integer cyc;            // flancos de subida transcurridos
    integer npulse;         // flancos de subida de 'pulse'
    integer t_pulse;        // cyc cuando 'pulse' subio por ultima vez
    integer pulse_ciclos;   // ciclos de reloj con pulse = 1
    integer nx;             // muestras con X/Z en 'pulse'
    integer N0, Nref, n0;
    reg     armado;

    // Especificacion del RTL: contador hasta 499_999 (10 ms @ 50 MHz) + 3 etapas de registro
    localparam integer LAT    = 500003;   // flancos desde el cambio de 'btn' hasta que 'pulse' sube
    localparam integer UMBRAL = 500000;   // ancho minimo (ciclos) del nivel alto para ser aceptado

    button_pulse uut (.clk(clk), .rst(rst), .btn(btn), .pulse(pulse));

    initial clk = 0;
    always #10 clk = ~clk;              // 50 MHz

    initial begin
        // Solo las señales relevantes: volcar clk y el contador generaria un .vcd enorme
        $dumpfile("button_pulse.vcd");
        $dumpvars(0, tb_button_pulse.btn);
        $dumpvars(0, tb_button_pulse.rst);
        $dumpvars(0, tb_button_pulse.pulse);
    end

    always @(posedge clk) cyc <= cyc + 1;
    always @(posedge pulse) if (armado) begin npulse = npulse + 1; t_pulse = cyc; end
    always @(negedge clk) if (armado) begin
        if (pulse === 1'b1) pulse_ciclos = pulse_ciclos + 1;
        if (pulse === 1'bx || pulse === 1'bz) nx = nx + 1;
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

    task poner;  input v; begin btn = v; N0 = cyc; end endtask      // invocar alineado a negedge
    task esperar; input integer n; begin repeat (n) @(negedge clk); end endtask

    initial begin
        errores = 0; casos = 0;
        cyc = 0; npulse = 0; t_pulse = 0; pulse_ciclos = 0; nx = 0; armado = 0;
        btn = 0; rst = 1;
        repeat (4) @(negedge clk);
        rst = 0;
        repeat (3) @(negedge clk);
        armado = 1;

        $display("=====================================================================");
        $display(" button_pulse: LAT esperada = %0d flancos (%0d ns = 10.00006 ms @ 50 MHz)", LAT, LAT * 20);
        $display("=====================================================================");

        // ---------------------------------------------------------------
        $display("\n[S0] Estado tras reset");
        #1;
        chk("pulse = 0", pulse, 0);

        // ---------------------------------------------------------------
        $display("\n[S1] Pulsacion limpia, boton mantenido");
        n0 = npulse;
        poner(1);
        esperar(LAT - 1); #1;
        chk("sin pulso un flanco antes de la latencia", npulse - n0, 0);
        esperar(1); #1;
        chk("pulso generado", npulse - n0, 1);
        chk("latencia exacta (flancos)", t_pulse - N0, LAT);
        esperar(50); #1;
        chk("ancho del pulso (ciclos de reloj)", pulse_ciclos, 1);
        esperar(10000); #1;
        chk("boton mantenido: NO se repite el pulso", npulse - n0, 1);

        // ---------------------------------------------------------------
        $display("\n[S2] Soltado con rebote (no debe generar pulso)");
        n0 = npulse;
        poner(0); esperar(9);
        poner(1); esperar(40);
        poner(0); esperar(300);
        poner(1); esperar(25);
        poner(0);
        esperar(LAT + 100); #1;
        chk("el soltado no genera pulso", npulse - n0, 0);

        // ---------------------------------------------------------------
        $display("\n[S3] Pulsacion con rebote (1,0,1,0,1): un solo pulso, LAT desde el ultimo rebote");
        n0 = npulse;
        poner(1); esperar(4);
        poner(0); esperar(17);
        poner(1); esperar(600);
        poner(0); esperar(3000);
        poner(1);
        esperar(LAT - 1); #1;
        chk("sin pulso durante/tras el rebote", npulse - n0, 0);
        esperar(1); #1;
        chk("un unico pulso", npulse - n0, 1);
        chk("latencia exacta desde el ultimo rebote", t_pulse - N0, LAT);
        esperar(1000);

        // ---------------------------------------------------------------
        $display("\n[S4] Re-pulsar antes de que el boton se considere liberado: no hay nuevo pulso");
        n0 = npulse;
        poner(0); esperar(1000);                       // soltado breve (< 10 ms)
        poner(1);
        esperar(UMBRAL + 1000); #1;
        chk("no hay pulso (botonCorregido seguia en 1)", npulse - n0, 0);

        // ---------------------------------------------------------------
        $display("\n[S5] Liberar de verdad (10 ms estable) y probar glitches");
        poner(0); esperar(LAT + 100);
        n0 = npulse;
        $display(" -- nivel alto de UMBRAL-1 = %0d ciclos: debe ignorarse", UMBRAL - 1);
        poner(1); esperar(UMBRAL - 1);
        poner(0); esperar(LAT + 100); #1;
        chk("sin pulso (glitch demasiado corto)", npulse - n0, 0);
        $display(" -- nivel alto de UMBRAL = %0d ciclos: debe aceptarse", UMBRAL);
        poner(1); Nref = N0; esperar(UMBRAL);
        poner(0); esperar(1000); #1;
        chk("pulso generado (aceptado aunque el boton ya se solto)", npulse - n0, 1);
        chk("latencia exacta desde el inicio del nivel alto", t_pulse - Nref, LAT);
        esperar(LAT + 100);                            // se estabiliza en 0 (botonCorregido -> 0)

        // ---------------------------------------------------------------
        $display("\n[S6] Reset asincrono: borra el pulso en curso, sin esperar flanco de reloj");
        n0 = npulse;
        poner(1);
        @(posedge pulse);                              // justo cuando sube el pulso
        #2 rst = 1; #1;
        chk("pulse cae inmediatamente con rst=1 (entre flancos)", pulse, 0);
        #1; rst = 0;
        chk("el pulso se conto una vez", npulse - n0, 1);
        @(negedge clk);

        // ---------------------------------------------------------------
        $display("\n[S7] Boton mantenido a traves de un reset: genera pulso nuevo, LAT desde que se suelta rst");
        // btn sigue en 1; el reset dejo botonCorregido=0 y todos los contadores en 0
        n0 = npulse; Nref = cyc;
        esperar(LAT + 50); #1;
        chk("pulso nuevo tras el reset", npulse - n0, 1);
        // rst se suelta entre flancos (antes del siguiente posedge): equivale a una pulsacion nueva,
        // con los registros de sincronizacion, el contador y botonCorregido en 0 -> latencia = LAT
        chk("latencia desde que se libero rst (flancos)", t_pulse - Nref, LAT);

        // ---------------------------------------------------------------
        $display("\n[S8] Integridad: ninguna muestra con X/Z en pulse");
        chk("muestras con X/Z", nx, 0);

        $display("\n=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
