module op_not(
    input  wire [3:0] a,
    input  wire [3:0] b, // Se mantiene en la declaración para conservar la estructura fija de la ALU
    output wire [7:0] y
);
    // El operador ~ realiza la negación bit a bit de A
    assign y = {4'b0000, ~a};
endmodule
