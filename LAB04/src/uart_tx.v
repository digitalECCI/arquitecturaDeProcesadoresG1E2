module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output wire       busy,
    output reg        done
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [15:0] clk_cnt;
    reg [2:0] bit_idx;
    reg [7:0] shreg;

    assign busy = (state != IDLE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1'b1;
            done    <= 1'b0;
            clk_cnt <= 16'd0;
            bit_idx <= 3'd0;
            shreg   <= 8'd0;
        end else begin
            done <= 1'b0;

            case (state)

                IDLE: begin
                    tx      <= 1'b1;
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;

                    if (start) begin
                        shreg <= data;
                        state <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (clk_cnt == 16'd433) begin
                        clk_cnt <= 16'd0;
                        state   <= DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 16'd1;
                    end
                end

                DATA: begin
                    tx <= shreg[bit_idx];

                    if (clk_cnt == 16'd433) begin
                        clk_cnt <= 16'd0;

                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 16'd1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (clk_cnt == 16'd433) begin
                        clk_cnt <= 16'd0;
                        state   <= IDLE;
                        done    <= 1'b1;
                    end else begin
                        clk_cnt <= clk_cnt + 16'd1;
                    end
                end

                default: begin
                    state   <= IDLE;
                    tx      <= 1'b1;
                    done    <= 1'b0;
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    shreg   <= 8'd0;
                end

            endcase
        end
    end

endmodule
