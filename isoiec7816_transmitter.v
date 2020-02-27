
`timescale 1us/1ns

module isoiec7816_transmitter (
    clock,
    reset,
    serial,
    oe,
    inverse,
    etu,
    egt,
    char,
    load,
    transmitted,
    error
);

    input clock;
    input reset;
    output serial;
    output oe;
    input inverse;
    input [10:0] etu;
    input [7:0] egt;
    input [7:0] char;
    input load;
    output transmitted;
    input error;

    reg serial;
    reg oe;
    reg done;
    reg transmitted;
    reg [7:0] char_internal;
    reg [11:0] serializer;
    reg [10:0] etu_counter;
    reg [7:0] egt_counter;
    reg parity;

    always @ (char_internal) begin
        parity = (char_internal[0] ^ char_internal[1] ^ char_internal[2] ^ char_internal[3] ^ char_internal[4] ^ char_internal[5] ^ char_internal[6] ^ char_internal[7]);
    end

    always @ (posedge clock) begin
        if (reset == 1'b1) begin
            serial <= 1'b1;
            oe <= 1'b0;
            done <= 1'b1;
            char_internal <= 8'h00;
            serializer <= 12'h000;
            etu_counter <= 11'h7ff;
            egt_counter <= 8'd0;
        end else begin
            char_internal <= char;
            if (done == 1'b1) begin
                if (load == 1'b1) begin
                    if (inverse == 1'b1) begin
                        serializer <= {1'b0, ~char_internal, ~parity, 2'b11};
                    end else begin
                        serializer <= {2'b11, parity, char_internal, 1'b0};
                    end
                    etu_counter <= 11'h000;
                    egt_counter <= egt;
                    done <= 1'b0;
                    serial <= 1'b1;
                    oe <= 1'b1;
                end
            end else if (etu_counter == 11'h000) begin
                etu_counter <= etu;
                if (((inverse == 1'b0) && (serializer == 12'b0000_0000_0011)) || ((inverse == 1'b1) && (serializer == 12'b1100_0000_0000))) begin
                    oe <= 1'b0;
                end
                if (serializer == 12'b0000_0000_0000) begin
                    if (egt_counter == 8'h00) begin
                        done <= 1'b1;
                    end else begin
                        egt_counter <= egt_counter - 1'b1;
                    end
                end else begin
                    if (inverse == 1'b1) begin
                        serial <= serializer[11];
                        serializer <= {serializer[10:0], 1'b0};
                    end else begin
                        serial <= serializer[0];
                        serializer <= {1'b0, serializer[11:1]};
                    end
                end
            end else begin
                etu_counter <= etu_counter - 1'b1;
            end

        end
    end

    always @ (negedge clock) begin
        if (reset == 1'b1) begin
            transmitted <= 1'b0;
        end else begin
            if ((etu_counter == 11'h001) && (egt_counter == 8'h00) && (transmitted == 1'b0) && (done == 1'b0)
                    && (((inverse == 1'b0) && (serializer == 12'h001)) || ((inverse == 1'b1) && (serializer == 12'h100)))) begin
                transmitted <= 1'b1;
            end else begin
                transmitted <= 1'b0;
            end
        end
    end

endmodule
