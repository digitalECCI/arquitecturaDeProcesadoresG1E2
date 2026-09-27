// ----------------------------------------------------------------------------
// Datapath del multiplicador (registros + sumador bit a bit)
// Requiere: sumador_8bit_ripple.v, full_adder_1bit.v
// ----------------------------------------------------------------------------
module multiplicador (
    input        clk,
    input        rst_global,          // Reset general de registros
    input  [3:0] multiplicando,
    input  [3:0] multiplicador,
    input        cargaDatos,          // Señal para cargar datos iniciales
    input        suma,                // Señal para sumar
    input        despla,              // Señal para desplazar
    output       LSB_B,
    output       Z,
    output [7:0] producto
);

    reg [7:0] A;
    reg [3:0] B;
    reg [7:0] PP;

    // Resultado combinacional del sumador bit a bit: PP + A
    wire [7:0] suma_bit_a_bit;
    wire       acarreo_final;

    sumador_8bit_ripple u_sumador (
        .A    (PP),
        .B    (A),
        .cin  (1'b0),
        .suma (suma_bit_a_bit),
        .cout (acarreo_final)
    );

    // Conexiones de salida hacia el control y exterior
    assign LSB_B = B[0];
    assign Z     = (B == 4'b0);
    assign producto = PP;

    // Lógica síncrona con el reloj
    always @(posedge clk or posedge rst_global) begin
        if (rst_global) begin
            A  <= 8'b0;
            B  <= 4'b0;
            PP <= 8'b0;
        end
        else begin
            if (cargaDatos) begin
                A  <= {4'b0000, multiplicando}; // Carga inicial
                B  <= multiplicador;
                PP <= 8'b0;                     // Limpia acumulador
            end
            else begin
                if (suma) begin
                    PP <= suma_bit_a_bit; // Suma acumulada (bit a bit)
                end
                if (despla) begin
                    A <= A << 1;  // Desplazamiento izquierda
                    B <= B >> 1;  // Desplazamiento derecha
                end
            end
        end
    end
endmodule
