`include "lab4/control_captura.v"
`timescale 1ms/1ms

module tb_control_captura;

    reg        clk, rst, start, busy_vis;
    reg  [3:0] a_sw, b_sw;
    reg  [2:0] op_sw;
    reg  [7:0] alu_result;
    wire [3:0] a_q, b_q;
    wire [2:0] op_q, addr;
    wire [7:0] data_in;
    wire       write_en, done;

    integer errores, casos, n, semilla;

    control_captura uut (
        .clk(clk), .rst(rst), .start(start), .busy_vis(busy_vis),
        .a_sw(a_sw), .b_sw(b_sw), .op_sw(op_sw), .alu_result(alu_result),
        .a_q(a_q), .b_q(b_q), .op_q(op_q),
        .addr(addr), .data_in(data_in), .write_en(write_en), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin $dumpfile("control_captura.vcd"); $dumpvars(0, tb_control_captura); end

    function [8*7-1:0] nombre;
        input [2:0] e;
        begin
            case (e)
                3'd0: nombre = "IDLE   ";
                3'd1: nombre = "WR_A   ";
                3'd2: nombre = "WR_B   ";
                3'd3: nombre = "WR_R   ";
                3'd4: nombre = "DONE   ";
                default: nombre = "ILEGAL ";
            endcase
        end
    endfunction

    // Un ciclo: se invoca alineado a negedge. Verifica estado y salidas (Moore) y
    // los registros de captura, deja pasar el flanco y regresa alineado al siguiente negedge.
    task paso;
        input [2:0] est;                       // estado esperado
        input [2:0] e_addr;
        input [7:0] e_data;
        input       e_we, e_done;
        input [3:0] e_a, e_b;
        input [2:0] e_op;
        begin
            #1;
            casos = casos + 1;
            if ((uut.state !== est) || (addr !== e_addr) || (data_in !== e_data) ||
                (write_en !== e_we) || (done !== e_done) ||
                (a_q !== e_a) || (b_q !== e_b) || (op_q !== e_op)) begin
                errores = errores + 1;
                $display(" [%0t ns] FALLO estado=%0s addr=%0d data=%h we=%b done=%b | a_q=%h b_q=%h op_q=%b | esperado: %0s addr=%0d data=%h we=%b done=%b a=%h b=%h op=%b",
                          $time, nombre(uut.state), addr, data_in, write_en, done, a_q, b_q, op_q,
                          nombre(est), e_addr, e_data, e_we, e_done, e_a, e_b, e_op);
            end else
                $display(" [%0t ns] %0s | addr=%0d data=%h we=%b done=%b | a_q=%h b_q=%h op_q=%b | OK",
                          $time, nombre(uut.state), addr, data_in, write_en, done, a_q, b_q, op_q);
            @(negedge clk);
        end
    endtask

    task reset_async;      // reset asincrono entre flancos
        begin
            #2 rst = 1; #1;
            casos = casos + 1;
            if ((uut.state !== 3'd0) || (a_q !== 4'd0) || (b_q !== 4'd0) || (op_q !== 3'd0) || (write_en !== 1'b0) || (done !== 1'b0)) begin
                errores = errores + 1;
                $display(" [%0t ns] FALLO: el reset asincrono no limpio estado/registros", $time);
            end else
                $display(" [%0t ns] reset asincrono sin flanco: estado=IDLE y a_q=b_q=op_q=0 | OK", $time);
            #1 rst = 0;
            @(negedge clk);
        end
    endtask

    // ---------------- Modelo de referencia para la prueba aleatoria ----------------
    reg [2:0] m_state, m_op;
    reg [3:0] m_a, m_b;
    reg [2:0] m_addr;
    reg [7:0] m_data;
    reg       m_we, m_done;

    task modelo_salidas;
        begin
            m_addr = 0; m_data = 0; m_we = 0; m_done = 0;
            case (m_state)
                3'd1: begin m_addr = 0; m_data = {4'b0, m_a}; m_we = 1; end
                3'd2: begin m_addr = 1; m_data = {4'b0, m_b}; m_we = 1; end
                3'd3: begin m_addr = 2; m_data = alu_result;  m_we = 1; end
                3'd4: m_done = 1;
                default: ;
            endcase
        end
    endtask

    integer err_rand;

    initial begin
        errores = 0; casos = 0; semilla = 32'h1AB04;
        rst = 1; start = 0; busy_vis = 0; a_sw = 0; b_sw = 0; op_sw = 0; alu_result = 8'h00;
        @(negedge clk); @(negedge clk);
        rst = 0; @(negedge clk);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 1) Reposo: sin start no hay escrituras ni cambios en los registros de captura");
        $display("=====================================================================");
        a_sw = 4'h9; b_sw = 4'h5; op_sw = 3'b010;
        //    estado addr data  we done a_q b_q op_q
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 2) start con el visualizador ocupado (busy_vis=1): se ignora");
        $display("=====================================================================");
        start = 1; busy_vis = 1;
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);
        start = 0; busy_vis = 0;

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 3) Captura completa: A=9, B=5, op=010 ; el resultado de la ALU se toma en WR_R");
        $display("=====================================================================");
        start = 1; busy_vis = 0;
        alu_result = 8'hEE;                                         // valor que NO debe aparecer en WR_A/WR_B
        // IDLE con start: aun no se ve la captura en a_q (se registra en este flanco)
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);
        start = 0;
        // los switches cambian despues de capturar: no deben afectar
        a_sw = 4'hF; b_sw = 4'hF; op_sw = 3'b111;
        paso(3'd1, 3'd0, 8'h09, 1, 0, 4'h9, 4'h5, 3'b010);        // WR_A: R0 <- A (hasta 8 bits)
        alu_result = 8'h2D;                                         // 9*5 = 45 = 0x2D
        paso(3'd2, 3'd1, 8'h05, 1, 0, 4'h9, 4'h5, 3'b010);        // WR_B: R1 <- B
        alu_result = 8'h2D;
        paso(3'd3, 3'd2, 8'h2D, 1, 0, 4'h9, 4'h5, 3'b010);        // WR_R: R2 <- resultado de la ALU (en vivo)
        alu_result = 8'h77;                                         // cambia: en DONE ya no se usa
        paso(3'd4, 3'd0, 8'h00, 0, 1, 4'h9, 4'h5, 3'b010);        // DONE: done=1, sin escritura
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h9, 4'h5, 3'b010);        // vuelve a IDLE; a_q/b_q/op_q se conservan

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 4) start durante WR_A/WR_B/WR_R/DONE se ignora (no se recaptura)");
        $display("=====================================================================");
        a_sw = 4'h3; b_sw = 4'hC; op_sw = 3'b001;
        start = 1;
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h9, 4'h5, 3'b010);        // IDLE + start: captura A=3,B=C,op=001
        paso(3'd1, 3'd0, 8'h03, 1, 0, 4'h3, 4'hC, 3'b001);        // WR_A con start=1 (ignorado)
        a_sw = 4'h1; b_sw = 4'h1; op_sw = 3'b100;                  // otros valores: no deben capturarse
        alu_result = 8'hF7;
        paso(3'd2, 3'd1, 8'h0C, 1, 0, 4'h3, 4'hC, 3'b001);        // WR_B con start=1 (ignorado)
        paso(3'd3, 3'd2, 8'hF7, 1, 0, 4'h3, 4'hC, 3'b001);        // WR_R con start=1 (ignorado)
        paso(3'd4, 3'd0, 8'h00, 0, 1, 4'h3, 4'hC, 3'b001);        // DONE con start=1: vuelve a IDLE igualmente
        // IDLE con start todavia en 1: el ciclo siguiente SI inicia una nueva captura
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h3, 4'hC, 3'b001);        // IDLE + start: recaptura A=1,B=1,op=100
        start = 0;
        paso(3'd1, 3'd0, 8'h01, 1, 0, 4'h1, 4'h1, 3'b100);
        paso(3'd2, 3'd1, 8'h01, 1, 0, 4'h1, 4'h1, 3'b100);
        paso(3'd3, 3'd2, 8'hF7, 1, 0, 4'h1, 4'h1, 3'b100);
        paso(3'd4, 3'd0, 8'h00, 0, 1, 4'h1, 4'h1, 3'b100);
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h1, 4'h1, 3'b100);

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 5) Reset asincrono en medio de la secuencia");
        $display("=====================================================================");
        start = 1; a_sw = 4'hA; b_sw = 4'hB; op_sw = 3'b110;
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h1, 4'h1, 3'b100);
        start = 0;
        paso(3'd1, 3'd0, 8'h0A, 1, 0, 4'hA, 4'hB, 3'b110);
        reset_async;                                                // se interrumpe en WR_B: debe volver a IDLE y limpiar
        paso(3'd0, 3'd0, 8'h00, 0, 0, 4'h0, 4'h0, 3'b000);        // sin escrituras residuales

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 6) Recuperacion desde estados ilegales (5,6,7): salidas en 0 y regreso a IDLE");
        $display("=====================================================================");
        for (n = 5; n <= 7; n = n + 1) begin
            uut.state = n[2:0];                                     // inyeccion de falla
            start = 1;
            #1;
            casos = casos + 1;
            if ((write_en !== 0) || (done !== 0) || (addr !== 0) || (data_in !== 0)) begin
                errores = errores + 1; $display(" estado ilegal %0d: salidas activas | FALLO", n);
            end else
                $display(" estado ilegal %0d: sin escrituras ni done | OK", n);
            @(negedge clk);
            casos = casos + 1;
            if (uut.state !== 3'd0) begin
                errores = errores + 1; $display(" estado ilegal %0d no regreso a IDLE | FALLO", n);
            end else
                $display(" estado ilegal %0d -> IDLE en el siguiente flanco | OK", n);
            start = 0;
        end

        // ------------------------------------------------------------
        $display("=====================================================================");
        $display(" 7) Aleatorio: 20000 ciclos contra modelo");
        $display("=====================================================================");
        err_rand = 0;
        rst = 1; #1; rst = 0; @(negedge clk);
        m_state = 0; m_a = 0; m_b = 0; m_op = 0;
        for (n = 0; n < 20000; n = n + 1) begin
            rst        = (($random(semilla) & 32'h7F) == 0);
            start      = (($random(semilla) & 7) < 3);
            busy_vis   = (($random(semilla) & 3) == 0);
            a_sw       = $random(semilla);
            b_sw       = $random(semilla);
            op_sw      = $random(semilla);
            alu_result = $random(semilla);
            if (rst) begin m_state = 0; m_a = 0; m_b = 0; m_op = 0; end   // reset asincrono
            #1;
            modelo_salidas;
            casos = casos + 1;
            if ((uut.state !== m_state) || (addr !== m_addr) || (data_in !== m_data) || (write_en !== m_we) ||
                (done !== m_done) || (a_q !== m_a) || (b_q !== m_b) || (op_q !== m_op)) begin
                errores = errores + 1; err_rand = err_rand + 1;
                if (err_rand <= 8)
                    $display(" [aleatorio %0d] FALLO DUT estado=%0d addr=%0d data=%h we=%b done=%b a=%h b=%h op=%b | MOD estado=%0d addr=%0d data=%h we=%b done=%b a=%h b=%h op=%b",
                              n, uut.state, addr, data_in, write_en, done, a_q, b_q, op_q, m_state, m_addr, m_data, m_we, m_done, m_a, m_b, m_op);
            end
            // avance del modelo en el flanco
            @(posedge clk);
            if (rst) begin m_state = 0; m_a = 0; m_b = 0; m_op = 0; end
            else case (m_state)
                3'd0: if (start && !busy_vis) begin m_a = a_sw; m_b = b_sw; m_op = op_sw; m_state = 3'd1; end
                3'd1: m_state = 3'd2;
                3'd2: m_state = 3'd3;
                3'd3: m_state = 3'd4;
                3'd4: m_state = 3'd0;
                default: m_state = 3'd0;
            endcase
            @(negedge clk);
        end
        rst = 0; start = 0;
        $display(" Prueba aleatoria: %0d discrepancias en 20000 ciclos", err_rand);

        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d verificaciones)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d VERIFICACIONES", errores, casos);
        $display("=====================================================================");
        $finish;
    end
endmodule
