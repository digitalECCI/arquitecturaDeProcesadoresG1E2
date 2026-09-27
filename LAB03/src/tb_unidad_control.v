`include "unidad_control.v"
`timescale 1ns/1ps

module tb_unidad_control;

    reg  clk, rst_global, INICIO, LSB_B, Z;
    wire DONE, cargaDatos, despla, suma;

    integer errores, casos;

    unidad_control uut (
        .clk(clk),
        .rst_global(rst_global),
        .INICIO(INICIO),
        .LSB_B(LSB_B),
        .Z(Z),
        .DONE(DONE),
        .cargaDatos(cargaDatos),
        .despla(despla),
        .suma(suma)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("unidad_control.vcd");
        $dumpvars(0, tb_unidad_control);
    end

    task verificar;
        input [127:0] etiqueta;
        input esp_carga, esp_suma, esp_despla, esp_done;
        begin
            casos = casos + 1;
            if ((cargaDatos !== esp_carga) || (suma !== esp_suma) ||
                (despla !== esp_despla) || (DONE !== esp_done)) begin
                errores = errores + 1;
                $display(" [%0t ns] %0s | carga=%b suma=%b despla=%b done=%b (esperado: %b %b %b %b) | FALLO",
                          $time, etiqueta, cargaDatos, suma, despla, DONE, esp_carga, esp_suma, esp_despla, esp_done);
            end else begin
                $display(" [%0t ns] %0s | carga=%b suma=%b despla=%b done=%b | OK",
                          $time, etiqueta, cargaDatos, suma, despla, DONE);
            end
        end
    endtask

    // NOTA DE TIMING: la logica de salidas de unidad_control es combinacional
    // (Mealy: depende del estado actual, visible de inmediato). Cada salida
    // se verifica EN el instante en que el estado ya es valido, nunca antes
    // ni un ciclo despues, y cada transicion de estado se hace explicita con
    // un @(posedge clk).
    task correr_multiplicacion;
        input [3:0] bits_lsb_primero;
        integer n;
        begin
            // Estado actual: IDLE (garantizado tras el reset)
            INICIO = 1;
            #1;
            verificar("IDLE con INICIO=1 (carga datos)", 1, 0, 0, 0);

            @(posedge clk); // transicion IDLE -> CHECK
            INICIO = 0;

            for (n = 0; n < 4; n = n + 1) begin
                // Estado actual: CHECK
                LSB_B = bits_lsb_primero[0];
                bits_lsb_primero = bits_lsb_primero >> 1;
                Z = (n == 3) ? 1'b1 : 1'b0;
                #1;
                verificar("CHECK", 0, 0, 0, 0);

                if (LSB_B) begin
                    @(posedge clk); // transicion CHECK -> ADD_S
                    #1;
                    verificar("ADD_S (bit=1, debe sumar)", 0, 1, 0, 0);
                    @(posedge clk); // transicion ADD_S -> SHIFT
                    #1;
                    verificar("SHIFT", 0, 0, 1, 0);
                end else begin
                    @(posedge clk); // transicion CHECK -> SHIFT directo
                    #1;
                    verificar("SHIFT", 0, 0, 1, 0);
                end

                // Si aun quedan iteraciones, la siguiente transicion (con Z=0)
                // vuelve a CHECK; si esta era la ultima (Z=1), la transicion
                // hacia END_S se maneja despues del for.
                if (n < 3) begin
                    @(posedge clk); // transicion SHIFT -> CHECK
                end
            end

            // Tras el ultimo SHIFT con Z=1, la transicion es a END_S
            @(posedge clk);
            #1;
            verificar("END_S (DONE)", 0, 0, 0, 1);

            // Vuelve a IDLE
            @(posedge clk);
            #1;
            verificar("Regreso a IDLE", 0, 0, 0, 0);
        end
    endtask

    initial begin
        errores = 0; casos = 0;
        rst_global = 1; INICIO = 0; LSB_B = 0; Z = 0;
        @(negedge clk); @(negedge clk);
        rst_global = 0;
        @(negedge clk); // asentar el estado IDLE tras el reset

        $display("=====================================================================");
        $display(" Escenario 1: multiplicador B = 4'b1011 (bits LSB->MSB: 1,1,0,1)");
        $display("=====================================================================");
        correr_multiplicacion(4'b1011);

        $display("");
        rst_global = 1; @(negedge clk); @(negedge clk); rst_global = 0; @(negedge clk);

        $display("=====================================================================");
        $display(" Escenario 2: multiplicador B = 4'b0000 (ningun bit activa suma)");
        $display("=====================================================================");
        correr_multiplicacion(4'b0000);

        $display("=====================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================");

        $finish;
    end

endmodule
