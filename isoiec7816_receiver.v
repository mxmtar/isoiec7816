
`timescale 1us/1ns

module isoiec7816_receiver (
    clock,
    reset,
    enable,
    serial,
    inverse,
    etu,
    bit_value,
    char,
    received
);

    input clock;
    input reset;
    input enable;
    input serial;
    input inverse;
    input [10:0] etu;
    output bit_value;
    output [7:0] char;
    output received;

    reg [1:0] serial_sample;
    reg [10:0] etu_counter;
    reg bit_received;
    reg bit_value;
    reg [7:0] char;
    reg received;
    reg parity;
    reg [11:0] data_internal;

    reg [3:0] state, state_next;

    parameter [3:0] IDLE        = 4'h0;
    parameter [3:0] START_BIT   = 4'h1;
    parameter [3:0] BIT_0       = 4'h2;
    parameter [3:0] BIT_1       = 4'h3;
    parameter [3:0] BIT_2       = 4'h4;
    parameter [3:0] BIT_3       = 4'h5;
    parameter [3:0] BIT_4       = 4'h6;
    parameter [3:0] BIT_5       = 4'h7;
    parameter [3:0] BIT_6       = 4'h8;
    parameter [3:0] BIT_7       = 4'h9;
    parameter [3:0] PARITY_BIT  = 4'ha;
    parameter [3:0] STOP_BIT0   = 4'hb;
    parameter [3:0] STOP_BIT1   = 4'hc;
    parameter [3:0] ERROR       = 4'hf;

    always @ (data_internal) begin
        parity = (data_internal[3] ^ data_internal[4] ^ data_internal[5] ^ data_internal[6] ^ data_internal[7] ^ data_internal[8] ^ data_internal[9] ^ data_internal[10]);
    end

    always @ (negedge clock) begin
        if (reset == 1'b1) begin
            received <= 1'b0;
        end else begin
            if ((state == START_BIT)
                    && (((inverse == 1'b1) && (data_internal[11] == 1'b0)) || ((inverse == 1'b0) && (data_internal[0] == 1'b0)))
                    && (received == 1'b0)) begin
                received <= 1'b1;
            end else begin
                received <= 1'b0;
            end
        end
    end

    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            serial_sample <= 2'b11;
            etu_counter <= 11'h000;
            bit_received <= 1'b0;
            bit_value <= 1'b0;
            data_internal <= 12'hfff;
            state <= IDLE;
        end else begin
             if (enable == 1'b1) begin
                serial_sample <= {serial_sample[0], serial};
                if ((state == START_BIT) && (serial_sample[1] == 1'b1) && (serial_sample[0] == 1'b0)) begin
                    etu_counter <= {1'b0, etu[10:1]};
                end else if (etu_counter == 11'h000) begin
                    bit_received <= 1'b1;
                    bit_value <= serial_sample[1];
                    if (inverse == 1'b1) begin
                        data_internal <= {data_internal[10:0], ~serial_sample[1]};
                        char <= data_internal[11:4];
                    end else begin
                        data_internal <= {serial_sample[1], data_internal[11:1]};
                        char <= data_internal[9:2];
                    end
                    etu_counter <= etu;
                end else begin
                    etu_counter <= etu_counter - 1'b1;
                    bit_received <= 1'b0;
                end
                state <= state_next;
                case (state)
                    IDLE: begin
                        data_internal <= 12'hfff;
                    end
                    START_BIT: begin
                        if (((inverse == 1'b1) && (data_internal[11] == 1'b0)) || ((inverse == 1'b0) && (data_internal[0] == 1'b0))) begin
                            data_internal <= 12'hfff;
                        end
                    end
                endcase
            end
        end
    end

    always @ (state or bit_received or bit_value or parity) begin
        case (state)
            IDLE: if ((bit_received == 1'b1) && (bit_value == 1'b1)) begin
                state_next = START_BIT;
            end else begin
                state_next = IDLE;
            end
            START_BIT: if ((bit_received == 1'b1) && (bit_value == 1'b0)) begin
                state_next = BIT_0;
            end else begin
                state_next = START_BIT;
            end
            BIT_0: if (bit_received == 1'b1) begin
                state_next = BIT_1;
            end else begin
                state_next = BIT_0;
            end
            BIT_1: if (bit_received == 1'b1) begin
                state_next = BIT_2;
            end else begin
                state_next = BIT_1;
            end
            BIT_2: if (bit_received == 1'b1) begin
                state_next = BIT_3;
            end else begin
                state_next = BIT_2;
            end
            BIT_3: if (bit_received == 1'b1) begin
                state_next = BIT_4;
            end else begin
                state_next = BIT_3;
            end
            BIT_4: if (bit_received == 1'b1) begin
                state_next = BIT_5;
            end else begin
                state_next = BIT_4;
            end
            BIT_5: if (bit_received == 1'b1) begin
                state_next = BIT_6;
            end else begin
                state_next = BIT_5;
            end
            BIT_6: if (bit_received == 1'b1) begin
                state_next = BIT_7;
            end else begin
                state_next = BIT_6;
            end
            BIT_7: if (bit_received == 1'b1) begin
                state_next = PARITY_BIT;
            end else begin
                state_next = BIT_7;
            end
            PARITY_BIT: if (bit_received == 1'b1) begin
                if (bit_value == parity) begin
                    state_next = STOP_BIT0;
                end else begin
                    state_next = ERROR;
                end
            end else begin
                state_next = PARITY_BIT;
            end
            STOP_BIT0: if (bit_received == 1'b1) begin
                if (bit_value == 1'b1) begin
                    state_next = STOP_BIT1;
                end else begin
                    state_next = IDLE;
                end
            end else begin
                state_next = STOP_BIT0;
            end
            STOP_BIT1: if (bit_received == 1'b1) begin
                if (bit_value == 1'b1) begin
                    state_next = START_BIT;
                end else begin
                    state_next = IDLE;
                end
            end else begin
                state_next = STOP_BIT1;
            end
            ERROR: begin
                state_next = IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
