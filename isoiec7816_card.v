
`timescale 1us/1ns

module isoiec7816_card (
    // external interface
    clk,
    rst,
    i_o,
    // backplane
    char_tx,
    char_tx_load,
    char_tx_transmitted,
    char_rx,
    char_rx_received,
    // control
    enable,
    inverse,
    etu,
    egt,
    // auxilary
    reset_buffered,
    testpoint
);

    input clk;
    input rst;
    inout i_o;
    input [7:0] char_tx;
    input char_tx_load;
    output char_tx_transmitted;
    output [7:0] char_rx;
    output char_rx_received;
    input enable;
    input inverse;
    input [10:0] etu;
    input [7:0] egt;
    output reset_buffered;
    output [7:0] testpoint;

    reg [3:0] reset_sample;
    reg reset_buffered;

    tri1 i_o_out;

    reg [15:0] counter;

    reg [3:0] state, state_next;
    parameter [3:0] STATE_INACTIVE      = 4'h0;
    parameter [3:0] STATE_ACTIVATION    = 4'h1;
    parameter [3:0] STATE_COLD_RESET    = 4'h2;
    parameter [3:0] STATE_RUN           = 4'h3;

    assign testpoint[0] = clk;
    assign testpoint[1] = rst;
    assign testpoint[2] = i_o;
    assign testpoint[3] = xmit_load;
    assign testpoint[4] = xmit_oe;
    assign testpoint[5] = char_tx_transmitted;
    assign testpoint[6] = bit_rx;
    assign testpoint[7] = char_rx_received;

    wire xmit_oe;
    wire xmit_out;
    wire xmit_load;

    wire bit_rx;

    assign xmit_load = (state == STATE_RUN) ? char_tx_load : 1'b0;

    assign i_o_out = ((enable == 1'b1) && (xmit_oe == 1'b1)) ? xmit_out : 1'bz;

    assign i_o = i_o_out;

    always @ (reset_sample) begin
        if (reset_sample == 4'b0000) begin
            reset_buffered = 1'b1;
        end else begin
            reset_buffered = 1'b0;
        end
    end

    always @ (posedge clk) begin
        reset_sample <= {reset_sample[2:0], rst};
        state <= state_next;
        case (state)
            STATE_ACTIVATION: begin
                counter <= 16'hffff;
            end
            STATE_COLD_RESET: begin
                if (counter == 16'hffff) begin
                    counter <= 16'd499;
                end else begin
                    counter <= counter - 1'b1;
                end
            end
        endcase
    end

    always @ (state or enable or reset_buffered or counter) begin
        case (state)
            STATE_INACTIVE: begin
                if (enable == 1'b1) begin
                    state_next = STATE_ACTIVATION;
                end else begin
                    state_next = STATE_INACTIVE;
                end
            end
            STATE_ACTIVATION: begin
                if (reset_buffered == 1'b0) begin
                    state_next = STATE_COLD_RESET;
                end else begin
                    state_next = STATE_ACTIVATION;
                end
            end
            STATE_COLD_RESET: begin
                if (counter == 16'h0000) begin
                    state_next = STATE_RUN;
                end else begin
                    state_next = STATE_COLD_RESET;
                end
            end
            STATE_RUN: begin
                if (reset_buffered == 1'b1) begin
                    state_next = STATE_INACTIVE;
                end else begin
                    state_next = STATE_RUN;
                end
            end
            default: begin
                state_next = STATE_INACTIVE;
            end
        endcase
    end

    isoiec7816_transmitter transmitter (
        .clock(clk),
        .reset(reset_buffered),
        .serial(xmit_out),
        .oe(xmit_oe),
        .inverse(inverse),
        .etu(etu),
        .egt(egt),
        .char(char_tx),
        .load(xmit_load),
        .transmitted(char_tx_transmitted),
        .error(1'b0)
    );

    isoiec7816_receiver receiver (
        .clock(clk),
        .reset(reset_buffered),
        .enable(~xmit_oe & (state == STATE_RUN)),
        .serial(i_o),
        .inverse(inverse),
        .etu(etu),
        .bit_value(bit_rx),
        .char(char_rx),
        .received(char_rx_received)
    );

endmodule
