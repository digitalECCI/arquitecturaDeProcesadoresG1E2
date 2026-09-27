// ----------------------------------------------------------------------------
// Antirrebote (debounce) — sin cambios respecto al original
// ----------------------------------------------------------------------------
module debounce (
    input      clk,
    input      boton,
    output reg botonCorregido
);

    reg [15:0] contador;
    reg        estado_previo;

    always @(posedge clk) begin
        estado_previo <= boton;

        if (boton != estado_previo) begin
            contador <= 0;
        end
        else if (contador < 16'hFFFF) begin
            contador <= contador + 1;
        end

        if (contador == 16'hFFFF) begin
            botonCorregido <= estado_previo;
        end
    end
endmodule
