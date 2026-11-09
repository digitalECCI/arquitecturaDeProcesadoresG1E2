`include "lab4/alu_principal.v"
`include "lab4/button_pulse.v"
`include "lab4/control_captura.v"
`include "lab4/banco_registros.v"
`include "lab4/visualizador_uart.v"
`include "lab4/uart_tx.v"
`include "lab4/decod7seg.v"
`include "lab4/alu.v"
`include "lab4/comparador4b.v"
`include "lab4/comparador1b.v"
`include "lab4/sumador4b.v"
`include "lab4/sumador.v"
`include "lab4/sumador_restador4b.v"
`include "lab4/multiplicador4b.v"
`include "lab4/des_izq.v"
`include "lab4/op_and.v"
`include "lab4/op_xnor.v"
`include "lab4/op_not.v"
`timescale 1ms/1ms

// Prueba de integracion del top lab4 (ALU + banco de registros + captura + UART + displays).
//   TRAMO A: boton KEY[1] REAL con antirrebote real (10 ms) y UART real: temporizacion de extremo a extremo.
//   TRAMO B: barrido exhaustivo 8 operaciones x 16 x 16 = 2048 capturas (boton bypaseado con force).
//   TRAMO C: salida serie completa (8 bytes por captura) para las 8 operaciones, 2 vectores cada una.
//   TRAMO D: reset (KEY[0]) a mitad de una transmision.
module tb_alu_principal;

    reg        reloj_principal;
    reg  [1:0] KEY;
    reg  [3:0] A, B;
    reg  [2:0] SEL;
    wire [9:0] LEDR;
    wire       uart_tx_pin;
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    integer errores, casos, cyc, nx;
    integer N0, t_start, t_start0, t_capdone, t_vbusy, t_fall, ncap;
    reg     armado, buscando_fall;
    integer i, j, o, b, q, bad;
    reg [7:0] rx, esp_byte [0:7];
    reg       ok;
    reg [7:0] resultado;

    localparam integer BIT = 434;
    localparam integer LAT_BTN = 500003;      // flancos desde que se presiona KEY[1] hasta start_pulse (ver tb_button_pulse)

    alu_principal uut (
        .reloj_principal(reloj_principal), .KEY(KEY), .A(A), .B(B), .SEL(SEL),
        .LEDR(LEDR), .uart_tx_pin(uart_tx_pin),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
    );

    initial reloj_principal = 0;
    always #10 reloj_principal = ~reloj_principal;     // 50 MHz

    initial begin
        // Solo señales de la interfaz (sin reloj ni jerarquia interna) para mantener el .vcd manejable
        $dumpfile("alu_principal.vcd");
        $dumpvars(0, uut);
        
    end

    // Perro guardian: si algo se cuelga, termina con un mensaje claro
    initial begin
        #600_000_000;
        $display("   FALLO: tiempo maximo de simulacion excedido (posible bloqueo)");
        $finish;
    end

    always @(posedge reloj_principal) cyc <= cyc + 1;
    always @(posedge uut.start_pulse) if (armado) t_start   = cyc;
    always @(posedge uut.cap_done)    if (armado) begin t_capdone = cyc; ncap = ncap + 1; end
    always @(posedge uut.vis_busy)    if (armado) t_vbusy   = cyc;
    always @(negedge uart_tx_pin)     if (armado && buscando_fall) begin t_fall = cyc; buscando_fall = 0; end
    always @(negedge reloj_principal) if (armado) begin
        if ((^{uart_tx_pin, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR}) === 1'bx) nx = nx + 1;
    end

    // ---------------- Modelos de referencia (independientes del DUT) ----------------
    function [6:0] seg_ref;       // codigo ANODO COMUN a partir de los segmentos encendidos
        input [3:0] d;
        reg [6:0] e;
        begin
            case (d)
                4'h0: e = 7'b0111111;  4'h1: e = 7'b0000110;  4'h2: e = 7'b1011011;  4'h3: e = 7'b1001111;
                4'h4: e = 7'b1100110;  4'h5: e = 7'b1101101;  4'h6: e = 7'b1111101;  4'h7: e = 7'b0000111;
                4'h8: e = 7'b1111111;  4'h9: e = 7'b1101111;  4'hA: e = 7'b1110111;  4'hB: e = 7'b1111100;
                4'hC: e = 7'b0111001;  4'hD: e = 7'b1011110;  4'hE: e = 7'b1111001;  4'hF: e = 7'b1110001;
            endcase
            seg_ref = ~e;
        end
    endfunction

    function [7:0] alu_ref;
        input [3:0] x, y;
        input [2:0] codigo;
        begin
            case (codigo)
                3'b000: alu_ref = x + y;
                3'b001: alu_ref = x - y;
                3'b010: alu_ref = x * y;
                3'b011: alu_ref = {5'b00000, (x < y), (x > y), (x == y)};
                3'b100: alu_ref = (x << 1) & 8'h0F;
                3'b101: alu_ref = x & y;
                3'b110: alu_ref = ~(x ^ y) & 8'h0F;
                3'b111: alu_ref = ~x & 8'h0F;
            endcase
        end
    endfunction

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

    task chkq;     // solo imprime si falla
        input [8*66-1:0] que;
        input integer obtenido;
        input integer esperado;
        begin
            casos = casos + 1;
            if (obtenido !== esperado) begin
                errores = errores + 1;
                $display("   FALLO [A=%0d B=%0d SEL=%b]: %0s -> obtenido=%0d esperado=%0d", A, B, SEL, que, obtenido, esperado);
            end
        end
    endtask

    task esperar; input integer n; begin repeat (n) @(negedge reloj_principal); end endtask

    // Receptor serie de referencia: muestrea en el centro de cada bit (8N1, LSB primero)
    task capturar;
        output [7:0] r;
        output       valido;
        integer bb;
        begin
            valido = 1'b1;
            @(negedge uart_tx_pin);
            repeat (BIT/2) @(posedge reloj_principal);
            if (uart_tx_pin !== 1'b0) valido = 1'b0;
            for (bb = 0; bb < 8; bb = bb + 1) begin
                repeat (BIT) @(posedge reloj_principal);
                r[bb] = uart_tx_pin;
            end
            repeat (BIT) @(posedge reloj_principal);
            if (uart_tx_pin !== 1'b1) valido = 1'b0;
        end
    endtask

    // Verifica registros, displays y LEDs tras una captura (estado DONE de la FSM)
    task verificar_captura;
        input [3:0] a_in, b_in;
        input [2:0] s_in;
        input       verboso;
        reg [7:0] res;
        begin
            res = alu_ref(a_in, b_in, s_in);
            if (verboso) begin
                chk("R0 = A", uut.u_banco.r0, {4'b0, a_in});
                chk("R1 = B", uut.u_banco.r1, {4'b0, b_in});
                chk("R2 = resultado de la ALU", uut.u_banco.r2, res);
                chk("R3..R7 sin escribir (R3|R4|R5|R6|R7 = 0)", uut.u_banco.r3 | uut.u_banco.r4 | uut.u_banco.r5 | uut.u_banco.r6 | uut.u_banco.r7, 0);
                chk("HEX4 = codigo de A", HEX4, seg_ref(a_in));
                chk("HEX5 = codigo de 0", HEX5, seg_ref(4'h0));
                chk("HEX2 = codigo de B", HEX2, seg_ref(b_in));
                chk("HEX3 = codigo de 0", HEX3, seg_ref(4'h0));
                chk("HEX0 = codigo de resultado[3:0]", HEX0, seg_ref(res[3:0]));
                chk("HEX1 = codigo de resultado[7:4]", HEX1, seg_ref(res[7:4]));
                chk("LEDR = {00, resultado}", LEDR, {2'b00, res});
            end else begin
                chkq("R0 = A", uut.u_banco.r0, {4'b0, a_in});
                chkq("R1 = B", uut.u_banco.r1, {4'b0, b_in});
                chkq("R2 = resultado de la ALU", uut.u_banco.r2, res);
                chkq("R3..R7 = 0", uut.u_banco.r3 | uut.u_banco.r4 | uut.u_banco.r5 | uut.u_banco.r6 | uut.u_banco.r7, 0);
                chkq("a_q", uut.a_q, a_in);
                chkq("b_q", uut.b_q, b_in);
                chkq("op_q", uut.op_q, s_in);
                chkq("HEX4", HEX4, seg_ref(a_in));
                chkq("HEX5", HEX5, seg_ref(4'h0));
                chkq("HEX2", HEX2, seg_ref(b_in));
                chkq("HEX3", HEX3, seg_ref(4'h0));
                chkq("HEX0", HEX0, seg_ref(res[3:0]));
                chkq("HEX1", HEX1, seg_ref(res[7:4]));
                chkq("LEDR", LEDR, {2'b00, res});
            end
        end
    endtask

    task reset_corto;     // KEY[0] activo en bajo
        begin
            KEY[0] = 0; esperar(3);
            KEY[0] = 1; esperar(1);
        end
    endtask

    // Captura rapida: el boton se bypasea con force sobre uut.start_pulso (un ciclo)
    task captura_rapida;
        input [3:0] a_in, b_in;
        input [2:0] s_in;
        begin
            A = a_in; B = b_in; SEL = s_in;
            force uut.start_pulse = 1'b1;
            @(negedge reloj_principal);
            force uut.start_pulse = 1'b0;
            esperar(3);
        end
    endtask

    // Esperados de la trama completa: [A, B, resultado, 0, 0, 0, 0, 0]
    task cargar_esperados;
        input [3:0] a_in, b_in;
        input [2:0] s_in;
        begin
            esp_byte[0] = {4'b0, a_in}; esp_byte[1] = {4'b0, b_in}; esp_byte[2] = alu_ref(a_in, b_in, s_in);
            for (q = 3; q < 8; q = q + 1) esp_byte[q] = 8'h00;
        end
    endtask

    integer sem;
    reg [3:0] va, vb;

    initial begin
        errores = 0; casos = 0; cyc = 0; nx = 0; ncap = 0; armado = 0; buscando_fall = 0;
        t_start = 0; t_capdone = 0; t_vbusy = 0; t_fall = 0; sem = 32'h7A8B9C;
        KEY = 2'b11; A = 4'd9; B = 4'd5; SEL = 3'b000;

        // Reset inicial (KEY[0] activo en bajo)
        KEY[0] = 0; esperar(5); KEY[0] = 1; esperar(5);
        armado = 1;

        // ============================================================
        $display("=====================================================================");
        $display(" TRAMO A: boton KEY[1] real (antirrebote 10 ms) + UART real a 115200 baudios");
        $display("=====================================================================");

        $display("\n[A1] Captura real: A=9, B=5, SEL=000 (suma)");
        #1;
        chk("UART en reposo (tx=1)", uart_tx_pin, 1);
        esperar(1);
        N0 = cyc; buscando_fall = 1;
        KEY[1] = 0;                                          // se presiona KEY[1]
        @(posedge uut.cap_done);
        #1;
        chk("latencia pulsacion -> start_pulse (flancos)", t_start - N0, LAT_BTN);
        chk("start_pulse -> cap_done (WR_A, WR_B, WR_R, DONE) (flancos)", t_capdone - t_start, 4);
        verificar_captura(4'd9, 4'd5, 3'b000, 1);
        // El boton sigue presionado: no debe haber una segunda captura. Los switches cambian: no deben afectar
        A = 4'hF; B = 4'hF; SEL = 3'b111;

        // 8 bytes por la UART: R0..R7 = [A, B, resultado, 0,0,0,0,0]
        cargar_esperados(4'd9, 4'd5, 3'b000);
        bad = 0;
        for (b = 0; b < 8; b = b + 1) begin
            if (b == 0) buscando_fall = 1;
            capturar(rx, ok);
            casos = casos + 1;
            if (!ok || (rx !== esp_byte[b])) begin
                bad = bad + 1; errores = errores + 1;
                $display("   FALLO: byte %0d recibido=0x%h esperado=0x%h valido=%b", b, rx, esp_byte[b], ok);
            end else
                $display("   OK   : byte %0d (R%0d) recibido por UART = 0x%h", b, b, rx);
            if (b == 0) begin
                // durante la transmision: start espurio y cambio de switches -> se ignora (visualizador ocupado)
                chk("busy_vis = 1 durante la transmision", uut.vis_busy, 1);
                t_start0 = t_start;                      // el start espurio de abajo sobrescribe t_start
                force uut.start_pulse = 1'b1; @(negedge reloj_principal); release uut.start_pulse;
                esperar(2);
                chk("FSM de captura ignora start con busy_vis=1 (estado IDLE)", uut.u_cap.state, 0);
                chk("a_q no cambio por el start espurio", uut.a_q, 9);
                chk("HEX4 sigue mostrando A capturado, no los switches", HEX4, seg_ref(4'd9));
                chk("primera caida de tx respecto de start_pulse (flancos)", t_fall - t_start0, 10);
            end
        end
        chk("una sola captura aun con el boton mantenido", ncap, 1);
        esperar(2 * BIT);
        chk("busy_vis = 0 al terminar los 8 bytes", uut.vis_busy, 0);
        chk("UART de nuevo en reposo (tx=1)", uart_tx_pin, 1);

        $display("\n[A2] Soltar el boton y recaptura REAL con rebote: A=3, B=9, SEL=001 (resta -> negativo)");
        KEY[1] = 1;
        esperar(LAT_BTN + 100);                              // el antirrebote tarda 10 ms en ver el soltado
        A = 4'd3; B = 4'd9; SEL = 3'b001;
        KEY[1] = 0; esperar(5);
        KEY[1] = 1; esperar(11);
        KEY[1] = 0; esperar(400);
        KEY[1] = 1; esperar(20);
        KEY[1] = 0; N0 = cyc;                                // nivel final estable
        @(posedge uut.cap_done);
        #1;
        chk("latencia desde el ultimo rebote (flancos)", t_start - N0, LAT_BTN);
        chk("el rebote produjo UNA captura mas (total)", ncap, 2);
        verificar_captura(4'd3, 4'd9, 3'b001, 1);
        cargar_esperados(4'd3, 4'd9, 3'b001);
        chk("resultado esperado de 3-9 en R2 = 0xFA (-6 en complemento a 2)", esp_byte[2], 8'hFA);
        bad = 0;
        for (b = 0; b < 8; b = b + 1) begin
            capturar(rx, ok);
            casos = casos + 1;
            if (!ok || (rx !== esp_byte[b])) begin
                bad = bad + 1; errores = errores + 1;
                $display("   FALLO: byte %0d recibido=0x%h esperado=0x%h valido=%b", b, rx, esp_byte[b], ok);
            end
        end
        if (bad == 0) $display("   OK   : 8 bytes por UART = 03 09 FA 00 00 00 00 00");
        esperar(2 * BIT);
        KEY[1] = 1;
        esperar(LAT_BTN + 100);

        // ============================================================
        $display("\n=====================================================================");
        $display(" TRAMO B: barrido exhaustivo 8 operaciones x 16 x 16 = 2048 capturas");
        $display("          (boton bypaseado con force; se verifica R0..R7, displays y LEDs)");
        $display("=====================================================================");
        force uut.start_pulse = 1'b0;
        for (o = 0; o < 8; o = o + 1) begin
            bad = errores;
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    reset_corto;
                    captura_rapida(i[3:0], j[3:0], o[2:0]);
                    chkq("FSM de captura en DONE", uut.u_cap.state, 4);
                    verificar_captura(i[3:0], j[3:0], o[2:0], 0);
                end
            $display(" Operacion SEL=%b: %0d fallos en 256 capturas", o[2:0], errores - bad);
        end

        // ============================================================
        $display("\n=====================================================================");
        $display(" TRAMO C: salida serie completa (8 bytes) para las 8 operaciones, 2 vectores cada una");
        $display("=====================================================================");
        for (o = 0; o < 8; o = o + 1)
            for (i = 0; i < 2; i = i + 1) begin
                case (o)
                    0: begin va = (i == 0) ? 4'd15 : 4'd7;  vb = (i == 0) ? 4'd15 : 4'd1;  end
                    1: begin va = (i == 0) ? 4'd3  : 4'd12; vb = (i == 0) ? 4'd9  : 4'd5;   end
                    2: begin va = (i == 0) ? 4'd13 : 4'd15; vb = (i == 0) ? 4'd11 : 4'd15;  end
                    3: begin va = (i == 0) ? 4'd7  : 4'd2;  vb = (i == 0) ? 4'd7  : 4'd14;  end
                    4: begin va = (i == 0) ? 4'd13 : 4'd8;  vb = (i == 0) ? 4'd0  : 4'd3;   end
                    5: begin va = (i == 0) ? 4'd12 : 4'd15; vb = (i == 0) ? 4'd10 : 4'd9;   end
                    6: begin va = (i == 0) ? 4'd12 : 4'd0;  vb = (i == 0) ? 4'd10 : 4'd15;  end
                    7: begin va = (i == 0) ? 4'd5  : 4'd15; vb = (i == 0) ? 4'd0  : 4'd6;   end
                endcase
                reset_corto;
                captura_rapida(va, vb, o[2:0]);
                cargar_esperados(va, vb, o[2:0]);
                bad = 0;
                for (b = 0; b < 8; b = b + 1) begin
                    capturar(rx, ok);
                    casos = casos + 1;
                    if (!ok || (rx !== esp_byte[b])) begin
                        bad = bad + 1; errores = errores + 1;
                        $display("   FALLO: SEL=%b A=%0d B=%0d byte %0d recibido=0x%h esperado=0x%h valido=%b", o[2:0], va, vb, b, rx, esp_byte[b], ok);
                    end
                end
                esperar(2 * BIT);
                casos = casos + 1;
                if (uut.vis_busy !== 1'b0) begin errores = errores + 1; $display("   FALLO: busy_vis no bajo tras los 8 bytes"); bad = bad + 1; end
                if (bad == 0)
                    $display("   OK   : SEL=%b A=%2d B=%2d -> UART: %h %h %h 00 00 00 00 00", o[2:0], va, vb, esp_byte[0], esp_byte[1], esp_byte[2]);
            end

        // ============================================================
        $display("\n=====================================================================");
        $display(" TRAMO D: reset (KEY[0]) a mitad de una transmision");
        $display("=====================================================================");
        reset_corto;
        captura_rapida(4'd11, 4'd6, 3'b010);
        capturar(rx, ok);                                    // primer byte completo
        esperar(BIT * 3);                                    // en pleno 2o byte
        #2 KEY[0] = 0; #1;
        chk("tx vuelve a 1 de inmediato (reset asincrono)", uart_tx_pin, 1);
        chk("busy_vis = 0 de inmediato", uut.vis_busy, 0);
        esperar(3);
        chk("HEX0..HEX5 muestran 0 tras el reset (HEX0)", HEX0, seg_ref(4'h0));
        chk("HEX1", HEX1, seg_ref(4'h0));
        chk("HEX2", HEX2, seg_ref(4'h0));
        chk("HEX3", HEX3, seg_ref(4'h0));
        chk("HEX4", HEX4, seg_ref(4'h0));
        chk("HEX5", HEX5, seg_ref(4'h0));
        chk("LEDR = 0", LEDR, 0);
        chk("R0..R2 borrados por el reset", uut.u_banco.r0 | uut.u_banco.r1 | uut.u_banco.r2, 0);
        KEY[0] = 1;
        esperar(3 * BIT);
        chk("sin tramas residuales: tx en 1", uart_tx_pin, 1);

        // ============================================================
        release uut.start_pulse;
        $display("\n[Integridad] muestras con X/Z en salidas: %0d", nx);
        casos = casos + 1;
        if (nx != 0) errores = errores + 1;

        $display("\n=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
