module button_pulse (
    input  wire clk,
    input  wire rst,
    input  wire btn,
    output reg  pulse
);

    reg [18:0] contador;

    reg btn_sync_0;
    reg btn_sync_1;

    reg estado_previo;
    reg botonCorregido;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync_0      <= 1'b0;
            btn_sync_1      <= 1'b0;
            estado_previo   <= 1'b0;
            botonCorregido  <= 1'b0;
            contador        <= 19'd0;
            pulse           <= 1'b0;
        end else begin
            // Sincronización del botón físico
            btn_sync_0 <= btn;
            btn_sync_1 <= btn_sync_0;

            // Por defecto no hay pulso
            pulse <= 1'b0;

            // Estado anterior del botón sincronizado
            estado_previo <= btn_sync_1;

            // Si el botón cambió de estado, reiniciamos contador
            if (btn_sync_1 != estado_previo) begin
                contador <= 19'd0;
            end 
            // Si el botón se mantiene igual, el contador avanza
            else if (contador < 19'd499999) begin
                contador <= contador + 19'd1;
            end

            // Cuando el contador llega al valor definido,
            // el botón se considera estable
            if (contador == 19'd499999) begin

                // Detectar cambio estable hacia 1
                if (botonCorregido == 1'b0 && estado_previo == 1'b1) begin
                    pulse <= 1'b1;
                end

                botonCorregido <= estado_previo;
            end
        end
    end

endmodule