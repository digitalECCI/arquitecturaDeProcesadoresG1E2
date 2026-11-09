module alu(
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [7:0] result
);
    // Salidas de cada operación
    wire [7:0] r_add, r_sub, r_mul, r_des, r_and, r_xnor, r_not;

    // Comparador
    wire w_Iab, w_Ma, w_Mb;

    wire [4:0] s_as;           // {Co, S} del sumador-restador

    // op[0] = 0 → suma, op[0] = 1 → resta
    sumador_restador4b u_as (.A(a), .B(b), .sub(op[0]), .R(s_as));

    assign r_add = {3'b000, s_as};
    // En resta, Co = 1 indica A >= B; Co = 0 indica un resultado negativo.
    assign r_sub = s_as[4] ? {4'b0000, s_as[3:0]}
                           : {4'b1111, s_as[3:0]};

    multiplicador4b u_mul (.A(a), .B(b), .R_Producto(r_mul));
    comparador4b    u_comp (.A(a), .B(b), .Ma(w_Ma), .Mb(w_Mb), .Iab(w_Iab));
    des_izq         u_des  (.a(a), .b(b), .R_des_izq(r_des));
    op_and          u_and  (.a(a), .b(b), .y(r_and));
    op_xnor         u_xnor (.a(a), .b(b), .y(r_xnor));
    op_not          u_not  (.a(a), .b(b), .y(r_not));

    // Multiplexor de selección
    always @(*) begin
        case (op)
            3'b000: result = r_add;
            3'b001: result = r_sub;
            3'b010: result = r_mul;
            3'b011: result = {5'b00000, w_Mb, w_Ma, w_Iab};
            3'b100: result = r_des;
            3'b101: result = r_and;
            3'b110: result = r_xnor;
            3'b111: result = r_not;
            default: result = 8'h00;
        endcase
    end
endmodule
