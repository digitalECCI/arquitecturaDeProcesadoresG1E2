module unidad_control (
    input      clk,
    input      rst_global,  // Botón físico de RESET (limpia todo)
    input      INICIO,      // Botón físico de INICIO (arranca el proceso)
    input      LSB_B,       // Bit de control de multiplicador
    input      Z,           // ¿B llegó a 0?
    output reg DONE,
    output reg cargaDatos,
    output reg despla,
    output reg suma         // Acumula producto parcial en PP
);

    localparam IDLE   = 3'b000,
               CHECK   = 3'b001,
               ADD_S   = 3'b010,
               SHIFT   = 3'b011,
               END_S   = 3'b100;

    reg [2:0] estado_actual, estado_siguiente;

    // 1. Registro de estado (secuencial)
    always @(posedge clk or posedge rst_global) begin
        if (rst_global)
            estado_actual <= IDLE;
        else
            estado_actual <= estado_siguiente;
    end

    // 2. Lógica de transición (combinacional)
    always @(*) begin
        case (estado_actual)
            IDLE:    estado_siguiente = INICIO ? CHECK : IDLE;
            CHECK:   estado_siguiente = LSB_B ? ADD_S : SHIFT;
            ADD_S:   estado_siguiente = SHIFT;
            SHIFT:   estado_siguiente = Z ? END_S : CHECK;
            END_S:   estado_siguiente = IDLE;
            default: estado_siguiente = IDLE;
        endcase
    end

    // 3. Lógica de salidas de control
    always @(*) begin
        DONE = 1'b0; cargaDatos = 1'b0; despla = 1'b0; suma = 1'b0;

        case (estado_actual)
            IDLE:   cargaDatos = INICIO; // carga en el mismo ciclo que arranca
            CHECK:  ; // evaluando bits
            ADD_S:  suma  = 1'b1;
            SHIFT:  despla = 1'b1;
            END_S:  DONE = 1'b1;
        endcase
    end
endmodule
