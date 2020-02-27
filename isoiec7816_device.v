
`timescale 1us/1ns

module isoiec7816_device (
    // external interface
    vcc,
    clk,
    rst,
    i_o,
    // backplane
    clock_in,
    reset_in,
    // control
    enable,
    // auxilary
    testpoint
);

    output vcc;
    output clk;
    output rst;
    inout i_o;
    input clock_in;
    input reset_in;
    input enable;
    output [7:0] testpoint;

    reg vcc = 1'bz;
    reg clk = 1'bz;
    reg rst = 1'bz;

    reg reception = 1'b1;
    reg clk_en = 1'b0;

    reg [15:0] counter;

    reg [3:0] state, state_next;
    parameter [3:0] STATE_INACTIVE      = 4'h0;
    parameter [3:0] STATE_ACTIVATION    = 4'h1;
    parameter [3:0] STATE_WAIT_FOR_ATR  = 4'h2;
    parameter [3:0] STATE_DEACTIVATION  = 4'h3;
    parameter [3:0] STATE_COOLDOWN      = 4'h4;

    assign testpoint = 8'hzz;

    always @ (clk_en or clock_in) begin
        if (clk_en == 1'b1) begin
            clk = clock_in;
        end else begin
            clk = 1'bz;
        end
    end

    always @ (posedge clock_in) begin
        if (reset_in == 1'b1) begin
            state <= STATE_INACTIVE;
            reception <= 1'b1;
            clk_en <= 1'b0;
            counter <= 16'hffff;
        end else begin
            state <= state_next;
            case (state)
                STATE_INACTIVE: begin
                    vcc <= 1'bz;
                    clk_en <= 1'b0;
                    rst <= 1'bz;
                    reception <= 1'b1;
                    counter <= 16'hffff;
                end
                STATE_ACTIVATION: begin
                    if (counter == 16'hffff) begin
                        counter <= 16'd200;
                        vcc <= 1'b1;
                        rst <= 1'b0;
                    end else if (counter == 16'd150) begin
                        reception <= 1'b1;
                        counter <= 16'd149;
                    end else if (counter == 16'd100) begin
                        clk_en <= 1'b1;
                        counter <= 16'd99;
                    end else if (counter == 16'h0000) begin
                        rst <= 1'b1;
                        counter <= 16'hffff;
                    end else begin
                        counter <= counter - 1'b1;
                    end
                end
                STATE_WAIT_FOR_ATR: begin
                    if (counter == 16'hffff) begin
                        counter <= 16'd20000;
                    end else if (counter == 16'h0000) begin
                        counter <= 16'hffff;
                    end else begin
                        counter <= counter - 1'b1;
                    end
                end
                STATE_DEACTIVATION: begin
                    if (counter == 16'hffff) begin
                        counter <= 16'd99;
                    end else begin
                        counter <= counter - 1'b1;
                    end
                end
                STATE_COOLDOWN: begin
                    if (counter == 16'hffff) begin
                        counter <= 16'd1000;
                        vcc <= 1'b0;
                        clk_en <= 1'b0;
                        rst <= 1'b0;
                    end else begin
                        counter <= counter - 1'b1;
                    end
                end
            endcase
        end
    end

    always @ (state or enable or counter) begin
        case (state)
            STATE_INACTIVE: begin
                if (enable == 1'b1) begin
                    state_next = STATE_ACTIVATION;
                end else begin
                    state_next = STATE_INACTIVE;
                end
            end
            STATE_ACTIVATION: begin
                if (counter == 16'h0000) begin
                    state_next = STATE_WAIT_FOR_ATR;
                end else begin
                    state_next = STATE_ACTIVATION;
                end
            end
            STATE_WAIT_FOR_ATR: begin
                if (counter == 16'h0000) begin
                    state_next = STATE_DEACTIVATION;
                end else begin
                    state_next = STATE_WAIT_FOR_ATR;
                end
            end
            STATE_DEACTIVATION: begin
                if (counter == 16'h0000) begin
                    state_next = STATE_COOLDOWN;
                end else begin
                    state_next = STATE_DEACTIVATION;
                end
            end
            STATE_COOLDOWN: begin
                if (counter == 16'h0000) begin
                    state_next = STATE_INACTIVE;
                end else begin
                    state_next = STATE_COOLDOWN;
                end
            end
            default: begin
                state_next = STATE_INACTIVE;
            end
        endcase
    end

    wire bit_rx;
    wire [7:0] char_rx;
    wire char_rx_received;

    isoiec7816_receiver receiver (
        .clock(clk),
        .reset(~rst),
        .enable(1'b1),
        .serial(i_o),
        .inverse(1'b0),
        .etu(11'd63),
        .bit_value(bit_rx),
        .char(char_rx),
        .received(char_rx_received)
    );

endmodule
