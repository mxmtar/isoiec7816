
`timescale 1us/1ns

module isoiec7816_tb ();

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg en  = 1'b0;

    reg [7:0] card_tx_buf[0:15];
    reg [3:0] card_tx_buf_len = 4'd0;
    reg [3:0] card_tx_buf_pos = 4'd0;
    reg [7:0] card_tx_data;
    reg card_tx_load = 1'b0;

    always @ (card_tx_buf_pos or card_tx_buf_len) begin
        if (card_tx_buf_pos == card_tx_buf_len) begin
            card_tx_load = 1'b0;
        end else begin
            card_tx_load = 1'b1;
        end
    end

    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            card_tx_buf_pos <= 4'h0;
        end else begin
            if (card_char_tx_transmitted == 1'b1) begin
                card_tx_buf_pos <= card_tx_buf_pos + 1'b1;
            end
        end
    end

    always @ (posedge clk) begin
        card_tx_data <= card_tx_buf[card_tx_buf_pos];
    end

    always begin
        #1 clk = ~clk;
    end

    wire line_vcc;
    wire line_clk;
    wire line_rst;
    wire line_i_o;

    wire card_char_tx_transmitted;
    wire [7:0] card_char_rx;
    wire card_char_rx_received;

    wire [7:0] tp_dev, tp_card;

    isoiec7816_device device (
        .vcc(line_vcc),
        .clk(line_clk),
        .rst(line_rst),
        .i_o(line_i_o),
        .clock_in(clk),
        .reset_in(rst),
        .enable(en),
        .testpoint(tp_dev)
    );

    isoiec7816_card card (
        .clk(line_clk),
        .rst(line_rst),
        .i_o(line_i_o),
        .char_tx(card_tx_data),
        .char_tx_load(card_tx_load),
        .char_tx_transmitted(card_char_tx_transmitted),
        .char_rx(card_char_rx),
        .char_rx_received(card_char_rx_received),
        .enable(1'b1),
        .inverse(1'b0),
        .etu(11'd63),
        .egt(8'd0),
        .testpoint(tp_card)
    );

    initial begin
        $dumpfile("isoiec7816_tb.lxt");
        $dumpvars(0, isoiec7816_tb);

        #0 begin
            card_tx_buf[0] = 8'h3b;
            card_tx_buf[1] = 8'h10;
            card_tx_buf[2] = 8'h94;
            card_tx_buf_len = 4'd3;
        end

        #10 rst = 1'b1;
        #10 rst = 1'b0;
        #10 en  = 1'b1;

        #100000 $finish;
    end

endmodule
