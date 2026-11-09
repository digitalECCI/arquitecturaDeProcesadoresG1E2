module visualizador_uart (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,

    output reg  [2:0] addr,
    output reg        read_en,
    input  wire [7:0] data_out,

    output reg        tx_start,
    output reg  [7:0] tx_data,
    input  wire       tx_done,

    output reg        busy
);

    localparam IDLE       = 3'd0;
    localparam READ       = 3'd1;
    localparam WAIT_READ  = 3'd2;
    localparam SEND       = 3'd3;
    localparam WAIT_TX    = 3'd4;
    localparam NEXT_ADDR  = 3'd5;

    reg [2:0] state;
    reg [2:0] index;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= IDLE;
            index    <= 3'd0;
            addr     <= 3'd0;
            read_en  <= 1'b0;
            tx_start <= 1'b0;
            tx_data  <= 8'd0;
            busy     <= 1'b0;
        end else begin
            read_en  <= 1'b0;
            tx_start <= 1'b0;

            case (state)

                IDLE: begin
                    busy  <= 1'b0;
                    index <= 3'd0;
                    addr  <= 3'd0;

                    if (start) begin
                        busy  <= 1'b1;
                        state <= READ;
                    end
                end

                READ: begin
                    addr    <= index;
                    read_en <= 1'b1;
                    state   <= WAIT_READ;
                end

                WAIT_READ: begin
                    state <= SEND;
                end

                SEND: begin
                    tx_data  <= data_out;
                    tx_start <= 1'b1;
                    state    <= WAIT_TX;
                end

                WAIT_TX: begin
                    if (tx_done) begin
                        state <= NEXT_ADDR;
                    end
                end

                NEXT_ADDR: begin
                    if (index == 3'd7) begin
                        state <= IDLE;
                    end else begin
                        index <= index + 3'd1;
                        state <= READ;
                    end
                end

                default: begin
                    state    <= IDLE;
                    index    <= 3'd0;
                    addr     <= 3'd0;
                    read_en  <= 1'b0;
                    tx_start <= 1'b0;
                    tx_data  <= 8'd0;
                    busy     <= 1'b0;
                end

            endcase
        end
    end

endmodule
