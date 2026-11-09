module comparador1b(
    input  A,
    input  B,
    output I,   // Igual (A == B)
    output MA,  // Mayor (A > B)
    output MB   // Menor (A < B)
);
    assign MA = (A & ~B);
    assign I  = (~A & ~B) | (A & B); // Equivalente a ~(A ^ B)
    assign MB = (~A & B);
endmodule