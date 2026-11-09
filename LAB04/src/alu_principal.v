// =====================================================================
// lab4 : top-level  (DE10-Lite)
// ALU de 4 bits + banco de registros + visualizador UART
//
// Reparto de los displays de 7 segmentos (todo en hexadecimal):
//   HEX5 HEX4 -> A          (HEX5 = 0, HEX4 = a_q)
//   HEX3 HEX2 -> B          (HEX3 = 0, HEX2 = b_q)
//   HEX1 HEX0 -> Resultado  (HEX1 = result[7:4], HEX0 = result[3:0])
// =====================================================================
module alu_principal (
    input  wire       reloj_principal,
    input  wire [1:0] KEY,        // KEY[0] = reset, KEY[1] = capturar (activo en bajo)
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire [2:0] SEL,        // código de operación
    output wire [9:0] LEDR,
    output wire       uart_tx_pin,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5
);

    // ---------------- Reset y disparo ----------------
    wire rst = ~KEY[0];
    wire start_pulse;

    button_pulse u_btn (
        .clk   (reloj_principal),
        .rst   (rst),
        .btn   (~KEY[1]),
        .pulse (start_pulse)
    );

    // ---------------- Captura de operandos ----------------
    wire [3:0] a_q, b_q;
    wire [2:0] op_q;
    wire [2:0] cap_addr;
    wire [7:0] cap_data;
    wire       cap_we;
    wire       cap_done;
    wire [7:0] alu_result;
    wire       vis_busy;

    control_captura u_cap (
        .clk        (reloj_principal),
        .rst        (rst),
        .start      (start_pulse),
        .busy_vis   (vis_busy),
        .a_sw       (A),
        .b_sw       (B),
        .op_sw      (SEL),
        .alu_result (alu_result),
        .a_q        (a_q),
        .b_q        (b_q),
        .op_q       (op_q),
        .addr       (cap_addr),
        .data_in    (cap_data),
        .write_en   (cap_we),
        .done       (cap_done)
    );

    // ---------------- ALU ----------------
    alu u_alu (
        .a      (a_q),
        .b      (b_q),
        .op     (op_q),
        .result (alu_result)
    );

    // ---------------- Banco de registros ----------------
    // Escritura: la FSM de captura (R0 = A, R1 = B, R2 = resultado)
    // Lectura  : el visualizador UART recorre las direcciones 0..7
    wire [2:0] vis_addr;
    wire       vis_read;     // la lectura es combinacional, no se usa como enable
    wire [7:0] vis_data;

    banco_registros u_banco (
        .clk      (reloj_principal),
        .rst      (rst),
        .RegWrite (cap_we),
        .addrRa   (vis_addr),
        .addrRb   (3'd0),            // segundo puerto de lectura sin usar
        .addrW    (cap_addr),
        .datW     (cap_data),
        .datOutRa (vis_data),
        .datOutRb ()                 // sin usar
    );

    // ---------------- UART ----------------
    wire       tx_start, tx_done, tx_busy;
    wire [7:0] tx_data;

    visualizador_uart u_vis (
        .clk      (reloj_principal),
        .rst      (rst),
        .start    (cap_done),
        .addr     (vis_addr),
        .read_en  (vis_read),
        .data_out (vis_data),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx_done  (tx_done),
        .busy     (vis_busy)
    );

    uart_tx u_tx (
        .clk   (reloj_principal),
        .rst   (rst),
        .start (tx_start),
        .data  (tx_data),
        .tx    (uart_tx_pin),
        .busy  (tx_busy),
        .done  (tx_done)
    );

    // ---------------- Indicadores ----------------
    assign LEDR = {2'b00, alu_result};

    // Resultado (8 bits -> 2 displays)
    decod7seg u_hex0 (.d(alu_result[3:0]), .seg(HEX0));
    decod7seg u_hex1 (.d(alu_result[7:4]), .seg(HEX1));

    // B (2 displays)
    decod7seg u_hex2 (.d(b_q),             .seg(HEX2));
    decod7seg u_hex3 (.d(4'h0),            .seg(HEX3));

    // A (2 displays)
    decod7seg u_hex4 (.d(a_q),             .seg(HEX4));
    decod7seg u_hex5 (.d(4'h0),            .seg(HEX5));

endmodule