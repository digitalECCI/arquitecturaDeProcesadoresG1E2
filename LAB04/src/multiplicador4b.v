module multiplicador4b (
    input  [3:0] A,        // Multiplicando
    input  [3:0] B,        // Multiplicador
    output [7:0] R_Producto  // Resultado final de 8 bits
);

    // 1. GENERACIÓN DE PRODUCTOS PARCIALES (Filas de compuertas AND)
    // Cada bit de B se multiplica (AND) por todos los bits de A
    wire [3:0] P0 = A & {4{B[0]}};
    wire [3:0] P1 = A & {4{B[1]}};
    wire [3:0] P2 = A & {4{B[2]}};
    wire [3:0] P3 = A & {4{B[3]}};

    // 2. ETAPAS DE SUMA EN CASCADA (Usando tu estructura sumador4b)
    // Almacenarán los resultados de las sumas parciales [Cout, S] de 5 bits
    wire [4:0] suma_etapa1;
    wire [4:0] suma_etapa2;
    wire [4:0] suma_etapa3;

    // --- Primera Etapa de Suma ---
    // Suma el producto parcial 0 (desplazado 1 bit a la derecha) con el producto parcial 1
    sumador4b sum1 (
        .A  ({1'b0, P0[3:1]}), // Desplazamos el remanente de P0
        .B  (P1),
        .Ci (1'b0),
        .R_suma(suma_etapa1)   // Salida de 5 bits: {Co, S}
    );

    // --- Segunda Etapa de Suma ---
    // Suma el resultado acumulado anterior (desplazado) con el producto parcial 2
    sumador4b sum2 (
        .A  ({1'b0, suma_etapa1[4:1]}), 
        .B  (P2),
        .Ci (1'b0),
        .R_suma(suma_etapa2)
    );

    // --- Tercera Etapa de Suma ---
    // Suma el resultado acumulado anterior (desplazado) con el producto parcial 3
    sumador4b sum3 (
        .A  ({1'b0, suma_etapa2[4:1]}),
        .B  (P3),
        .Ci (1'b0),
        .R_suma(suma_etapa3)
    );

    // 3. CONCATENACIÓN DEL PRODUCTO FINAL DE 8 BITS
    // Recolectamos los bits menos significativos que fueron quedando libres en cada etapa
    assign R_Producto = {
        suma_etapa3,       // Bits 7 al 3 (Resultado final del último sumador)
        suma_etapa2[0],       // Bit 2
        suma_etapa1[0],       // Bit 1
        P0[0]                 // Bit 0 (Directo del primer producto parcial)
    };

endmodule
