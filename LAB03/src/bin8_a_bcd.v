module bin8_a_bcd (
    input      [7:0] binario,
    output reg [3:0] centenas,
    output reg [3:0] decenas,
    output reg [3:0] unidades
);
    integer i;
    reg [19:0] despl; // [19:16]=centenas [15:12]=decenas [11:8]=unidades [7:0]=binario

    always @(*) begin
        despl = 20'b0;
        despl[7:0] = binario;

        for (i = 0; i < 8; i = i + 1) begin
            if (despl[11:8]  >= 5) despl[11:8]  = despl[11:8]  + 3;
            if (despl[15:12] >= 5) despl[15:12] = despl[15:12] + 3;
            if (despl[19:16] >= 5) despl[19:16] = despl[19:16] + 3;
            despl = despl << 1;
        end

        unidades = despl[11:8];
        decenas  = despl[15:12];
        centenas = despl[19:16];
    end
endmodule
