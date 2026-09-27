`include "debounce.v"
`timescale 1ns/1ps

module tb_debounce;

    reg  clk;
    reg  boton;
    wire botonCorregido;

    integer errores, casos;

    debounce uut (
        .clk(clk),
        .boton(boton),
        .botonCorregido(botonCorregido)
    );

    // Reloj de periodo 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("debounce.vcd");
        $dumpvars(0, tb_debounce);
    end

    // Tarea de verificacion puntual
    task verificar;
        input [127:0] etiqueta;
        input esperado;
        begin
            casos = casos + 1;
            if (botonCorregido !== esperado) begin
                errores = errores + 1;
                $display(" [%0t ns] %0s -> botonCorregido=%b (esperado=%b) | FALLO", $time, etiqueta, botonCorregido, esperado);
            end else begin
                $display(" [%0t ns] %0s -> botonCorregido=%b (esperado=%b) | OK", $time, etiqueta, botonCorregido, esperado);
            end
        end
    endtask

    initial begin
        errores = 0; casos = 0;
        boton = 0;

        $display("===================================================================");
        $display(" NOTA: en la simulacion pura, 'contador' y 'estado_previo' arrancan");
        $display(" en X (sin reset explicito en el modulo), tal como lo haria un reg");
        $display(" no inicializado. El primer cambio real en 'boton' es lo que fuerza");
        $display(" la rama 'contador <= 0' y saca al circuito del estado X. En un FPGA");
        $display(" real esto normalmente no se nota porque los registros arrancan en 0.");
        $display("===================================================================");

        // Cebado inicial: forzamos un primer cambio para sacar los registros del estado X
        @(negedge clk);
        boton = 1;
        @(negedge clk);
        boton = 0;
        #20;
        verificar("Tras el cebado inicial (boton estable en 0)", 1'bx); // aun no ha pasado el tiempo de debounce completo

        $display("");
        $display("--- Escenario 1: presionar el boton con rebote, luego soltar limpio ---");

        // Simulamos "rebote" tipico de un switch mecanico: varias transiciones
        // rapidas antes de asentarse en el nivel final (1 = presionado)
        @(negedge clk); boton = 1;
        @(negedge clk); boton = 0;
        @(negedge clk); boton = 1;
        @(negedge clk); boton = 0;
        @(negedge clk); boton = 1;  // aqui queda estable en 1

        // Durante el rebote, NO debe haberse actualizado botonCorregido a 1 todavia.
        // Como este es el primer ciclo de estabilizacion completo del testbench,
        // botonCorregido sigue en X (no ha habido reset explicito ni una primera
        // estabilizacion exitosa) -- no es un 0 valido todavia.
        #100;
        verificar("Durante/justo despues del rebote (aun no debe reflejar el 1)", 1'bx);

        // Esperamos el tiempo completo de debounce: el contador debe llegar a 16'hFFFF
        // (65535 incrementos) contados desde que boton quedo estable en 1.
        repeat (65540) @(posedge clk);
        #1;
        verificar("Despues del tiempo completo de debounce (boton estable en 1)", 1'b1);

        $display("");
        $display("--- Escenario 2: soltar el boton con rebote ---");

        @(negedge clk); boton = 0;
        @(negedge clk); boton = 1;
        @(negedge clk); boton = 0;
        @(negedge clk); boton = 1;
        @(negedge clk); boton = 0;  // aqui queda estable en 0

        #100;
        verificar("Durante/justo despues del rebote de soltado (aun debe mostrar 1)", 1'b1);

        repeat (65540) @(posedge clk);
        #1;
        verificar("Despues del tiempo completo de debounce (boton estable en 0)", 1'b0);

        $display("");
        $display("--- Escenario 3: un pulso corto (mas corto que el tiempo de debounce) debe ser ignorado ---");

        @(negedge clk); boton = 1;
        repeat (1000) @(posedge clk); // mucho menos que 65535 ciclos
        @(negedge clk); boton = 0;
        repeat (2000) @(posedge clk);
        #1;
        verificar("Pulso corto ignorado (sigue en 0)", 1'b0);

        $display("===================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("===================================================================");

        $finish;
    end

endmodule
