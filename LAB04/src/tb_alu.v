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
`timescale 1ns/1ns

module tb_alu;
    // VERBOSO = 1 imprime los 2048 casos; 0 imprime solo fallos y un resumen por operacion
    localparam VERBOSO = 0;

    reg  [3:0] a, b;
    reg  [2:0] op;
    wire [7:0] result;

    integer i, j, o, errores, casos;
    integer err_op [0:7];
    reg [7:0] esperado;

    alu uut (.a(a), .b(b), .op(op), .result(result));

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, uut);
    end

    // Modelo de referencia INDEPENDIENTE (operadores aritmeticos/logicos de Verilog)
    function [7:0] alu_ref;
        input [3:0] x, y;
        input [2:0] codigo;
        begin
            case (codigo)
                3'b000: alu_ref = x + y;                              // suma (0..30)
                3'b001: alu_ref = x - y;                              // resta en complemento a 2 de 8 bits (negativos = 0xF1..0xFF)
                3'b010: alu_ref = x * y;                              // producto (0..225)
                3'b011: alu_ref = {5'b00000, (x < y), (x > y), (x == y)};  // {Mb, Ma, Iab}
                3'b100: alu_ref = (x << 1) & 8'h0F;                   // desplazamiento a la izquierda (4 bits)
                3'b101: alu_ref = x & y;                              // AND
                3'b110: alu_ref = ~(x ^ y) & 8'h0F;                   // XNOR
                3'b111: alu_ref = ~x & 8'h0F;                         // NOT de A
            endcase
        end
    endfunction

    function [8*5-1:0] nombre_op;
        input [2:0] c;
        begin
            case (c)
                3'b000: nombre_op = "ADD  ";
                3'b001: nombre_op = "SUB  ";
                3'b010: nombre_op = "MUL  ";
                3'b011: nombre_op = "CMP  ";
                3'b100: nombre_op = "SHL  ";
                3'b101: nombre_op = "AND  ";
                3'b110: nombre_op = "XNOR ";
                3'b111: nombre_op = "NOT  ";
            endcase
        end
    endfunction

    initial begin
        errores = 0; casos = 0;
        for (o = 0; o < 8; o = o + 1) err_op[o] = 0;

        $display("=====================================================================");
        $display(" Barrido exhaustivo de la ALU: 8 operaciones x 16 x 16 = 2048 casos");
        $display("=====================================================================");

        for (o = 0; o < 8; o = o + 1) begin
            for (i = 0; i < 16; i = i + 1)
                for (j = 0; j < 16; j = j + 1) begin
                    a = i[3:0]; b = j[3:0]; op = o[2:0];
                    #10;
                    esperado = alu_ref(a, b, op);
                    casos = casos + 1;
                    if (result !== esperado) begin
                        errores = errores + 1; err_op[o] = err_op[o] + 1;
                        $display(" FALLO %0s a=%2d b=%2d -> result=%3d (%b) esperado=%3d (%b)",
                                  nombre_op(op), a, b, result, result, esperado, esperado);
                    end else if (VERBOSO)
                        $display(" OK    %0s a=%2d b=%2d -> result=%3d (%b)", nombre_op(op), a, b, result, result);
                end
            $display(" Operacion %0s (op=%b): %0d/256 correctos", nombre_op(o[2:0]), o[2:0], 256 - err_op[o]);
        end

        $display("=====================================================================");
        if (errores == 0) $display("TODAS LAS PRUEBAS PASARON CORRECTAMENTE (%0d/%0d casos)", casos, casos);
        else              $display("SE ENCONTRARON %0d ERRORES DE %0d CASOS", errores, casos);
        $display("=====================================================================");

        // Casos de ejemplo
        $display("");
        $display("Casos de ejemplo:");
        a = 4'd9;  b = 4'd5;  op = 3'b000; #10; $display("  9 +  5 = %0d", result);
        a = 4'd9;  b = 4'd5;  op = 3'b001; #10; $display("  9 -  5 = %0d", result);
        a = 4'd3;  b = 4'd9;  op = 3'b001; #10; $display("  3 -  9 = 0x%h (= -6 en complemento a 2 de 8 bits)", result);
        a = 4'd13; b = 4'd11; op = 3'b010; #10; $display(" 13 x 11 = %0d", result);
        a = 4'd7;  b = 4'd7;  op = 3'b011; #10; $display("  cmp(7,7)  = %b  ({Mb,Ma,Iab}: igual)", result[2:0]);
        a = 4'd9;  b = 4'd5;  op = 3'b011; #10; $display("  cmp(9,5)  = %b  ({Mb,Ma,Iab}: A mayor)", result[2:0]);
        a = 4'd2;  b = 4'd5;  op = 3'b011; #10; $display("  cmp(2,5)  = %b  ({Mb,Ma,Iab}: A menor)", result[2:0]);
        $finish;
    end
endmodule
