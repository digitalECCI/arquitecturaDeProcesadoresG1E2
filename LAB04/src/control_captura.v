// FSM de captura: al recibir 'start' toma A, B y op de los switches, y escribe
// A -> R0, B -> R1, resultado ALU -> R2 en el banco de registros.
module control_captura (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       busy_vis,       // visualizador ocupado: se ignora start
    input  wire [3:0] a_sw,
    input  wire [3:0] b_sw,
    input  wire [2:0] op_sw,
    input  wire [7:0] alu_result,
    output reg  [3:0] a_q,
    output reg  [3:0] b_q,
    output reg  [2:0] op_q,
    output reg  [2:0] addr,
    output reg  [7:0] data_in,
    output reg        write_en,
    output reg        done
);
    localparam [2:0] S_IDLE = 3'd0, S_WR_A = 3'd1, S_WR_B = 3'd2, S_WR_R = 3'd3, S_DONE = 3'd4;
    reg [2:0] state;

    // Registro de estado y captura de operandos
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE; a_q <= 4'd0; b_q <= 4'd0; op_q <= 3'd0;
        end else begin
            case (state)
                S_IDLE: if (start && !busy_vis) begin
                            a_q <= a_sw; b_q <= b_sw; op_q <= op_sw;
                            state <= S_WR_A;
                        end
                S_WR_A: state <= S_WR_B;
                S_WR_B: state <= S_WR_R;
                S_WR_R: state <= S_DONE;
                S_DONE: state <= S_IDLE;
                default: state <= S_IDLE;
            endcase
        end
    end

    // Salidas (Moore)
    always @(*) begin
        addr = 3'd0; data_in = 8'd0; write_en = 1'b0; done = 1'b0;
        case (state)
            S_WR_A: begin addr = 3'd0; data_in = {4'b0000, a_q}; write_en = 1'b1; end
            S_WR_B: begin addr = 3'd1; data_in = {4'b0000, b_q}; write_en = 1'b1; end
            S_WR_R: begin addr = 3'd2; data_in = alu_result;     write_en = 1'b1; end
            S_DONE: done = 1'b1;
            default: ;
        endcase
    end
endmodule