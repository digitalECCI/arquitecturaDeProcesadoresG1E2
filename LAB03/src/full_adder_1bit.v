// ----------------------------------------------------------------------------
// Full adder de 1 bit (celda basica del sumador bit a bit)
// Modelado ESTRUCTURAL a nivel de compuertas (primitivas de Verilog),
// en vez de usar los operadores ^, &, | en un assign.
//
// Ecuaciones:
//   sum  = a XOR b XOR cin
//   cout = (a AND b) OR (cin AND (a XOR b))
// ----------------------------------------------------------------------------
module full_adder_1bit (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    wire a_xor_b;   // resultado de a XOR b (se reutiliza para sum y para cout)
    wire and1;      // a AND b
    wire and2;      // cin AND (a XOR b)

    // --- Suma ---
    xor (a_xor_b, a, b);     // a_xor_b = a ^ b
    xor (sum,     a_xor_b, cin); // sum = (a ^ b) ^ cin

    // --- Acarreo ---
    and (and1, a, b);            // and1 = a & b
    and (and2, cin, a_xor_b);    // and2 = cin & (a ^ b)
    or  (cout, and1, and2);      // cout = and1 | and2
endmodule
