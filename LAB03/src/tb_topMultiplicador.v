`include "topMultiplicador.v"
`include "debounce.v"
`include "unidad_control.v"
`include "multiplicador.v"
`include "sumador_8bit_ripple.v"
`include "full_adder_1bit.v"
`include "bin8_a_bcd.v"
`include "bcd_a_7seg_anodo_comun.v"
`timescale 1ns/1ns

module tb_topMultiplicador;
 
    reg  clk;
    reg  B_Reset, B_Inicio;
    reg  [3:0] num_A, num_B;
    wire ledDone;
    wire [7:0] ledsResultado;
    wire [6:0] HEX0, HEX1, HEX2;
 
    integer errores, casos;
    integer esperado;
    reg [3:0] cen_esp, dec_esp, uni_esp;
 
    topMultiplicador uut (
        .clk(clk),
        .B_Reset(B_Reset),
        .B_Inicio(B_Inicio),
        .num_A(num_A),
        .num_B(num_B),
        .ledDone(ledDone),
        .ledsResultado(ledsResultado),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        $dumpfile("topMultiplicador.vcd");
        $dumpvars(0, uut);
    end
 
    function [6:0] seg_esperado;
        input [3:0] b;
        begin
            case (b)
                4'd0: seg_esperado = 7'b1000000;
                4'd1: seg_esperado = 7'b1111001;
                4'd2: seg_esperado = 7'b0100100;
                4'd3: seg_esperado = 7'b0110000;
                4'd4: seg_esperado = 7'b0011001;
                4'd5: seg_esperado = 7'b0010010;
                4'd6: seg_esperado = 7'b0000010;
                4'd7: seg_esperado = 7'b1111000;
                4'd8: seg_esperado = 7'b0000000;
                4'd9: seg_esperado = 7'b0010000;
                default: seg_esperado = 7'b1111111;
            endcase
        end
    endfunction
 
    task pulso_reset_rapido;
        begin
            force uut.rstCorregido = 1'b1;
            @(posedge clk);
            force uut.rstCorregido = 1'b0;
            @(posedge clk);
            release uut.rstCorregido;
        end
    endtask
 
    task multiplicar_y_verificar;
        input [3:0] a_in, b_in;
        begin
            num_A = a_in;
            num_B = b_in;
 
            // Pulso de INICIO de un solo ciclo (equivalente al pulso ya
            // limpio que entregaria el antirrebote tras estabilizarse)
            @(negedge clk);
            force uut.InicioCorregido = 1'b1;
            @(negedge clk);
            force uut.InicioCorregido = 1'b0;
 
            wait (ledDone == 1);
            #1;
 
            esperado = a_in * b_in;
            cen_esp = esperado / 100;
            dec_esp = (esperado / 10) % 10;
            uni_esp = esperado % 10;
 
            casos = casos + 1;
 
            if ((ledsResultado !== esperado[7:0]) ||
                (HEX0 !== seg_esperado(uni_esp)) ||
                (HEX1 !== seg_esperado(dec_esp)) ||
                (HEX2 !== seg_esperado(cen_esp))) begin
                errores = errores + 1;
                $display(" %2d x %2d = %3d | ledsResultado=%3d HEX2/1/0=%b/%b/%b | esperado bin=%3d seg=%b/%b/%b | FALLO",
                          a_in, b_in, esperado, ledsResultado, HEX2, HEX1, HEX0,
                          esperado, seg_esperado(cen_esp), seg_esperado(dec_esp), seg_esperado(uni_esp));
            end else begin
                $display(" %2d x %2d = %3d | ledsResultado=%3d HEX2/1/0=%b/%b/%b | OK",
                          a_in, b_in, esperado, ledsResultado, HEX2, HEX1, HEX0);
            end
 
            release uut.InicioCorregido;
            // Dejar un par de ciclos en IDLE antes del siguiente caso
            repeat (3) @(posedge clk);
        end
    endtask
 
    integer i, j;
 
    initial begin
        errores = 0; casos = 0;
        B_Reset = 1; B_Inicio = 1; num_A = 0; num_B = 0;
 
        $display("=================================================================");
        $display(" Prueba de integracion de topMultiplicador (16x16 = 256 casos)");
        $display(" El antirrebote se bypasea con force/release (ver nota en el .v);");
        $display(" ya fue verificado de forma independiente y exhaustiva en");
        $display(" tb_debounce.v.");
        $display("=================================================================");
 
        pulso_reset_rapido;
 
        $display("");
        $display("=================================================================");
        $display(" A     B     Producto | Resultado");
        $display("=================================================================");
 
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                multiplicar_y_verificar(i[3:0], j[3:0]);
            end
        end
 
        $display("=================================================================");
        if (errores == 0)
            $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else
            $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=================================================================");
 
        $finish;
    end
 
endmodule