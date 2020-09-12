// Blink an LED provided an input clock
/* module */
module top (
        // input hardware clock (12 MHz)
    hwclk, 
    // LED
    led1,
    led2,
    led3,
    led4,
    led5,
    led6,
    led7,
    led8,
    // Keypad lines
    keypad_r1,
    keypad_r2,
    keypad_r3,
    keypad_c1,
    keypad_c2,
    keypad_c3,
    );
    /* I/O */
    input hwclk;

    output led1;
    output led2;
    output led3;
    output led4;
    output led5;
    output led6;
    output led7;
    output led8 = 0;


    output keypad_r1;
    output keypad_r2;
    output keypad_r3;

    input keypad_c1;
    input keypad_c2;
    input keypad_c3;

    reg [3:0] ledvals;
    reg [2:0] row_outputs;


    /* Button Modules */
    wire press1, press2, press3;
    button button1 (
        .clk (hwclk),
        .pin_in (keypad_c1),
        .press (press1),
    );
    button button2 (
        .clk (hwclk),
        .pin_in (keypad_c2),
        .press (press2),
    );
    button button3 (
        .clk (hwclk),
        .pin_in (keypad_c3),
        .press (press3),
    );
    assign led1 = press1;
    assign led2 = press2;
    assign led3 = press3;

    reg [31:0] row_timer = 32'b0;
    wire button_pressed = press1 | press2 | press3;
    parameter ROW_PERIOD = 32'd130000;
    parameter STATE_ROW1    = 4'd0;
    parameter STATE_ROW2   = 4'd1;
    parameter STATE_ROW3    = 4'd2;
    reg [1:0] state = STATE_ROW1;

    
    assign led4 = ledvals[3];
    assign led5 = ledvals[2];
    assign led6 = ledvals[1];
    assign led7 = ledvals[0];

    assign keypad_r1 = row_outputs[0];
    assign keypad_r2 = row_outputs[1];
    assign keypad_r3 = row_outputs[2];

    always @ (posedge hwclk) begin
        if (row_timer < ROW_PERIOD) begin
           row_timer <= row_timer + 1; 
        end else begin
            row_timer = 32'b0;
            case (state)
                STATE_ROW1 : begin
                    state <= STATE_ROW2;
                    row_outputs <= 3'b101;
                end
                STATE_ROW2 : begin
                    state <= STATE_ROW3;
                    row_outputs <= 3'b011;
                end
                STATE_ROW3 : begin
                    state <= STATE_ROW1;
                    row_outputs <= 3'b110;
                end                  
            endcase
        end
    end

    always @ (posedge button_pressed) begin
        if (press1) begin
            ledvals <= state * 3 + 4'd1;
        end else if (press2) begin
            ledvals <= state * 3 + 4'd2;
        end else if (press3) begin
            ledvals <= state * 3 + 4'd3;
        end         
    end

endmodule
