// Banco de registros 8x8, 2 puertos de lectura combinacional, 1 de escritura síncrona
// Reset síncrono activo en alto. Usa always pero NO usa for ni generate.
//
// Parámetros opcionales (por defecto el comportamiento es igual al original):
//   ZERO_R0       = 1 -> r0 siempre vale 0 (estilo MIPS / RISC-V)
//   WRITE_THROUGH = 1 -> si lees la misma dirección que escribes en el mismo
//                        ciclo, obtienes datW (forwarding interno)
module banco_registros #(
    parameter ZERO_R0       = 0,
    parameter WRITE_THROUGH = 0
)(
    input  wire       clk,
    input  wire       rst,          // activo en alto, síncrono
    input  wire       RegWrite,
    input  wire [2:0] addrRa,
    input  wire [2:0] addrRb,
    input  wire [2:0] addrW,
    input  wire [7:0] datW,
    output wire [7:0] datOutRa,
    output wire [7:0] datOutRb
);
    // Habilitación de escritura por registro (r0 se bloquea si ZERO_R0 = 1)
    wire we0 = RegWrite & (addrW == 3'd0) & (ZERO_R0 == 0);
    wire we1 = RegWrite & (addrW == 3'd1);
    wire we2 = RegWrite & (addrW == 3'd2);
    wire we3 = RegWrite & (addrW == 3'd3);
    wire we4 = RegWrite & (addrW == 3'd4);
    wire we5 = RegWrite & (addrW == 3'd5);
    wire we6 = RegWrite & (addrW == 3'd6);
    wire we7 = RegWrite & (addrW == 3'd7);

    // Registros con valor inicial en 0: evita 'X' en simulación
    reg [7:0] r0 = 8'b0, r1 = 8'b0, r2 = 8'b0, r3 = 8'b0,
              r4 = 8'b0, r5 = 8'b0, r6 = 8'b0, r7 = 8'b0;

    always @(posedge clk) r0 <= rst ? 8'b0 : (we0 ? datW : r0);
    always @(posedge clk) r1 <= rst ? 8'b0 : (we1 ? datW : r1);
    always @(posedge clk) r2 <= rst ? 8'b0 : (we2 ? datW : r2);
    always @(posedge clk) r3 <= rst ? 8'b0 : (we3 ? datW : r3);
    always @(posedge clk) r4 <= rst ? 8'b0 : (we4 ? datW : r4);
    always @(posedge clk) r5 <= rst ? 8'b0 : (we5 ? datW : r5);
    always @(posedge clk) r6 <= rst ? 8'b0 : (we6 ? datW : r6);
    always @(posedge clk) r7 <= rst ? 8'b0 : (we7 ? datW : r7);

    // Lectura combinacional (multiplexores de 8 entradas)
    wire [7:0] rawA = (addrRa == 3'd0) ? r0 :
                      (addrRa == 3'd1) ? r1 :
                      (addrRa == 3'd2) ? r2 :
                      (addrRa == 3'd3) ? r3 :
                      (addrRa == 3'd4) ? r4 :
                      (addrRa == 3'd5) ? r5 :
                      (addrRa == 3'd6) ? r6 : r7;

    wire [7:0] rawB = (addrRb == 3'd0) ? r0 :
                      (addrRb == 3'd1) ? r1 :
                      (addrRb == 3'd2) ? r2 :
                      (addrRb == 3'd3) ? r3 :
                      (addrRb == 3'd4) ? r4 :
                      (addrRb == 3'd5) ? r5 :
                      (addrRb == 3'd6) ? r6 : r7;

    // r0 = 0 opcional y forwarding opcional (desactivado durante el reset)
    wire zeroA = (ZERO_R0 != 0) & (addrRa == 3'd0);
    wire zeroB = (ZERO_R0 != 0) & (addrRb == 3'd0);
    wire fwdA  = (WRITE_THROUGH != 0) & RegWrite & ~rst & (addrRa == addrW);
    wire fwdB  = (WRITE_THROUGH != 0) & RegWrite & ~rst & (addrRb == addrW);

    assign datOutRa = zeroA ? 8'b0 : (fwdA ? datW : rawA);
    assign datOutRb = zeroB ? 8'b0 : (fwdB ? datW : rawB);

endmodule 