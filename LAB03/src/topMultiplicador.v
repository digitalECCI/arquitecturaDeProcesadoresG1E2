module topMultiplicador (
    input        clk,
    input        B_Reset,
    input        B_Inicio,
    input  [3:0] num_A,
    input  [3:0] num_B,
    output       ledDone,
    output [7:0] ledsResultado,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2
);

    wire rstCorregido;
    wire InicioCorregido;

    wire ctrl_load, ctrl_add, ctrl_sh;
    wire dp_lsb, dp_z;
    wire [7:0] producto_w;

    debounce u_debounce_rst (
        .clk            (clk),
        .boton          (~B_Reset),
        .botonCorregido (rstCorregido)
    );

    debounce u_debounce_start (
        .clk            (clk),
        .boton          (~B_Inicio),
        .botonCorregido (InicioCorregido)
    );

    unidad_control u_control (
        .clk        (clk),
        .rst_global (rstCorregido),
        .INICIO     (InicioCorregido),
        .LSB_B      (dp_lsb),
        .Z          (dp_z),
        .DONE       (ledDone),
        .cargaDatos (ctrl_load),
        .suma       (ctrl_add),
        .despla     (ctrl_sh)
    );

    multiplicador u_datapath (
        .clk           (clk),
        .rst_global    (rstCorregido),
        .multiplicando (num_A),
        .multiplicador (num_B),
        .cargaDatos    (ctrl_load),
        .suma          (ctrl_add),
        .despla        (ctrl_sh),
        .LSB_B         (dp_lsb),
        .Z             (dp_z),
        .producto      (producto_w)
    );

    assign ledsResultado = producto_w;

    // --- Conversión binario -> BCD (double dabble) ---
    wire [3:0] centenas_w, decenas_w, unidades_w;

    bin8_a_bcd u_bin2bcd (
        .binario  (producto_w),
        .centenas (centenas_w),
        .decenas  (decenas_w),
        .unidades (unidades_w)
    );

    // --- Cada dígito BCD (0-9) al decodificador de 7 segmentos ---
    bcd_a_7seg_anodo_comun u_hex0 (
        .bcd (unidades_w),
        .seg (HEX0)
    );

    bcd_a_7seg_anodo_comun u_hex1 (
        .bcd (decenas_w),
        .seg (HEX1)
    );

    bcd_a_7seg_anodo_comun u_hex2 (
        .bcd (centenas_w),
        .seg (HEX2)
    );

endmodule