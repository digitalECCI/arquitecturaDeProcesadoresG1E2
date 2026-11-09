module comparador4b(
    input  [3:0] A,
    input  [3:0] B,
    output       Iab,   // Salida Final: A es Igual a B
    output       Ma,  // Salida Final: A es Mayor que B
    output       Mb   // Salida Final: A es Menor que B
);

    // Cables internos para capturar las comparaciones bit a bit
    wire i3, ma3, mb3;
    wire i2, ma2, mb2;
    wire i1, ma1, mb1;
    wire i0, ma0, mb0;

    // Instancia para el Bit 3 (MSB - El que tiene más prioridad)
    comparador1b c3 (.A(A[3]), .B(B[3]), .I(i3), .MA(ma3), .MB(mb3));

    // Instancia para el Bit 2
    comparador1b c2 (.A(A[2]), .B(B[2]), .I(i2), .MA(ma2), .MB(mb2));

    // Instancia para el Bit 1
    comparador1b c1 (.A(A[1]), .B(B[1]), .I(i1), .MA(ma1), .MB(mb1));

    // Instancia para el Bit 0 (LSB - El que tiene menos prioridad)
    comparador1b c0 (.A(A[0]), .B(B[0]), .I(i0), .MA(ma0), .MB(mb0));

    // --- LÓGICA DE SALIDA COMBINACIONAL ---

    // 1. IGUALDAD (I): Todos los bits individuales deben ser iguales
    assign Iab = i3 & i2 & i1 & i0;

    // 2. MAYOR QUE (MA): 
    // A es mayor si el Bit 3 es mayor, 
    // O si el Bit 3 es igual y el Bit 2 es mayor, 
    // O si los Bits 3 y 2 son iguales y el Bit 1 es mayor, etc.
    assign Ma = ma3 | 
                (i3 & ma2) | 
                (i3 & i2 & ma1) | 
                (i3 & i2 & i1 & ma0);

    // 3. MENOR QUE (MB): 
    // Lógica idéntica a la anterior pero evaluando las señales de menor (mb)
    assign Mb = mb3 | 
                (i3 & mb2) | 
                (i3 & i2 & mb1) | 
                (i3 & i2 & i1 & mb0);

endmodule