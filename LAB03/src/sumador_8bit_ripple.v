// ----------------------------------------------------------------------------
// Sumador de 8 bits "bit a bit" (ripple-carry), construido encadenando
// 8 full_adder_1bit. Sustituye al operador "+" que se usaba antes.
// Requiere: full_adder_1bit.v
// ----------------------------------------------------------------------------
module sumador_8bit_ripple (
    input  [7:0] A,
    input  [7:0] B,
    input        cin,
    output [7:0] suma,
    output       cout
);
    // Acarreos internos entre cada etapa (sin generate/for: instancias explícitas)
    wire c1, c2, c3, c4, c5, c6, c7;

    full_adder_1bit FA0 (.a(A[0]), .b(B[0]), .cin(cin), .sum(suma[0]), .cout(c1));
    full_adder_1bit FA1 (.a(A[1]), .b(B[1]), .cin(c1),  .sum(suma[1]), .cout(c2));
    full_adder_1bit FA2 (.a(A[2]), .b(B[2]), .cin(c2),  .sum(suma[2]), .cout(c3));
    full_adder_1bit FA3 (.a(A[3]), .b(B[3]), .cin(c3),  .sum(suma[3]), .cout(c4));
    full_adder_1bit FA4 (.a(A[4]), .b(B[4]), .cin(c4),  .sum(suma[4]), .cout(c5));
    full_adder_1bit FA5 (.a(A[5]), .b(B[5]), .cin(c5),  .sum(suma[5]), .cout(c6));
    full_adder_1bit FA6 (.a(A[6]), .b(B[6]), .cin(c6),  .sum(suma[6]), .cout(c7));
    full_adder_1bit FA7 (.a(A[7]), .b(B[7]), .cin(c7),  .sum(suma[7]), .cout(cout));
endmodule
