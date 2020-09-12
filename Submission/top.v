// Controls the digital lock; brings everything together

module top (
  hwclk,
  keypad_r1,
  keypad_r2,
  keypad_r3,
  keypad_c1,
  keypad_c2,
  keypad_c3,
  led1,
  led2,
  led3
);

  input hwclk;

  output keypad_r1;
  output keypad_r2;
  output keypad_r3;
  input keypad_c1;
  input keypad_c2;
  input keypad_c3;

  output led1;
  output led2;
  output led3;

  // Input PC and PC_LENGTH here, using 4'd# for each digit of PC and 3'd# for PC_LENGTH
  parameter PC = { 4'd5, 4'd4, 4'd4, 4'd4, 4'd1, 4'd2 },
            PC_LENGTH = 3'd6;

  // state bits
  parameter 
  FAIL          = 8'b00000001, // extra=0 led3=0 led2=0 led1=0 RST=0 REPROGRAM_GO=0 LOCK_GO=0 BLINK_GO=1 
  IDLE          = 8'b00001000, // extra=0 led3=0 led2=0 led1=0 RST=1 REPROGRAM_GO=0 LOCK_GO=0 BLINK_GO=0 
  LOCK_UNLOCK   = 8'b00100010, // extra=0 led3=0 led2=1 led1=0 RST=0 REPROGRAM_GO=0 LOCK_GO=1 BLINK_GO=0 
  LOCK_UNLOCKED = 8'b00000000, // extra=0 led3=0 led2=0 led1=0 RST=0 REPROGRAM_GO=0 LOCK_GO=0 BLINK_GO=0 
  REPROGRAM     = 8'b01000100, // extra=0 led3=1 led2=0 led1=0 RST=0 REPROGRAM_GO=1 LOCK_GO=0 BLINK_GO=0 
  REPROGRAMMED  = 8'b10000001, // extra=1 led3=0 led2=0 led1=0 RST=0 REPROGRAM_GO=0 LOCK_GO=0 BLINK_GO=1 
  START         = 8'b00011000; // extra=0 led3=0 led2=0 led1=1 RST=1 REPROGRAM_GO=0 LOCK_GO=0 BLINK_GO=0 

  reg [7:0] state = START;
  reg [7:0] nextstate;

  // Stores the current UC
  reg[23:0] UC;
  reg[2:0] UC_LENGTH;
  // Stores the new code, that, depending on conditions, may replace the current UC
  reg[23:0] NEWCODE;
  reg[2:0] NEWLENGTH;

  wire[3:0] BUTTON;
  wire BPRESS;
  wire BSTATE;

  // Checks for the falling edge of bstate(BSTATE), that signals when a button is released
  reg r1 = 0, r2 = 0, r3 = 0;
  always @(posedge hwclk) begin
    r1 <= BSTATE;
    r2 <= r1;
    r3 <= r2;
  end
  assign BPRESS = r3 & !r2;

  // Control inputs and outputs between modules
  wire RST;
  wire BLINK_GO;
  wire BLINK_DONE;
  wire LOCK_GO;
  wire LDONE;
  wire LSUCCESS;
  wire REPROGRAM_GO;
  wire PDONE;
  wire PSUCCESS;
  reg[4:0] ON;
  reg[4:0] OFF;
  reg[2:0] REPEAT;
  wire LED;
  reg toggle_led1;

  // Modules
  // Captures keypresses (provided)
  enterDigit keypad(
    .hwclk(hwclk),
    .keypad_r1(keypad_r1),
    .keypad_r2(keypad_r2),
    .keypad_r3(keypad_r3),
    .keypad_c1(keypad_c1),
    .keypad_c2(keypad_c2),
    .keypad_c3(keypad_c3),
    .button(BUTTON),
    .bstate(BSTATE)
  );

  // Performs all blinking of the LEDs
  blink blinky (
    .CLK(hwclk),
    .RST(RST),
    .GO(BLINK_GO),
    .ON(ON),
    .OFF(OFF),
    .REPEAT(REPEAT),
    .DONE(BLINK_DONE),
    .LED(LED)
  );

  // Checks an inputted code vs the current UC (format: 9+UC+9)
  enter_code UC_LOCK_UNLOCK(
    .CLK(hwclk),
    .RST(RST),
    .GO(LOCK_GO),
    .BUTTON(BUTTON),
    .BPRESS(BPRESS),
    .CORRECT_CODE(UC),
    .LENGTH(UC_LENGTH),
    .ENTER_BUTTON(4'd9),
    .DONE(LDONE),
    .SUCCESS(LSUCCESS)
  );

  // Reprograms the UC, requires inputting PC (format: 8+PC+8+NEW_UC+8+NEW_UC+8)
  reprogram UC_REPROGRAM(
    .CLK(hwclk),
    .RST(RST),
    .GO(REPROGRAM_GO),
    .PC(PC),
    .PC_LENGTH(PC_LENGTH),
    .UC(UC),
    .UC_LENGTH(UC_LENGTH),
    .BUTTON(BUTTON),
    .BPRESS(BPRESS),
    .DONE(PDONE),
    .SUCCESS(PSUCCESS),
    .NEWCODE(NEWCODE),
    .NEWLENGTH(NEWLENGTH)
  );

  // Determines which LED blinks
  reg[1:0] ledsel;

  // comb always block
  always @* begin
    nextstate = 8'bxxxxxxxx; // default to x because default_state_is_x is set
    toggle_led1 = 0; // default
    case (state)
      FAIL         : begin
        OFF[4:0] = 5'd5;
        ON[4:0] = 5'd10;
        REPEAT[2:0] = 5'd3;
        if (BLINK_DONE) begin
          nextstate = IDLE;
        end
        else begin
          nextstate = FAIL;
        end
      end
      IDLE         : begin
        if (BPRESS & BUTTON[3:0]==4'd9) begin
          nextstate  = LOCK_UNLOCK;
        end
        else if (BPRESS & BUTTON[3:0]==4'd8) begin
          nextstate = REPROGRAM;
        end
        else begin
          nextstate = IDLE;
        end
      end
      LOCK_UNLOCK  : begin
        ledsel = 2'b01;
        if ((BPRESS & BUTTON[3:0]==4'd7) | (LDONE & !LSUCCESS)) begin
          nextstate = FAIL;
        end
        else if (LDONE & LSUCCESS) begin
          nextstate = LOCK_UNLOCKED;
        end
        else begin
          nextstate = LOCK_UNLOCK;
        end
      end
      LOCK_UNLOCKED: begin
        toggle_led1 = 1;
        begin
          nextstate = IDLE;
        end
      end
      REPROGRAM    : begin
        ledsel = 2'b10;
        if ((BPRESS & BUTTON[3:0]==4'd7) | (PDONE & !PSUCCESS)) begin
          nextstate = FAIL;
        end
        else if (PDONE & PSUCCESS) begin
          nextstate = REPROGRAMMED;
        end
        else begin
          nextstate = REPROGRAM;
        end
      end
      REPROGRAMMED : begin
        UC[23:0] = NEWCODE[23:0];
        UC_LENGTH[2:0] = NEWLENGTH[2:0];
        OFF[4:0] = 5'd2;
        ON[4:0] = 5'd2;
        REPEAT[2:0] = 3'd5;
        if (BLINK_DONE) begin
          nextstate = IDLE;
        end
        else begin
          nextstate = REPROGRAMMED;
        end
      end
      START        : begin
        // Default value for UC
        UC = { 4'd6, 4'd6, 4'd6, 4'd6, 4'd6, 4'd6 };
        UC_LENGTH = 3'd6;
        begin
          nextstate = IDLE;
        end
      end
      default      : begin
        begin
          nextstate = START;
        end
      end
    endcase
  end

  // Assign reg'd outputs to state bits
  assign BLINK_GO = state[0];
  assign LOCK_GO = state[1];
  assign REPROGRAM_GO = state[2];
  assign RST = state[3];
  // Controls the three LEDs
  assign led1 = state[4] | led1reg;
  assign led2 = (ledsel == 2'b01 & BLINK_GO) ? LED : state[5];
  assign led3 = (ledsel == 2'b10 & BLINK_GO) ? LED : state[6];

  // Toggles the first LED when the system is locked/unlocked
  reg led1reg;
  always @(posedge hwclk) begin
    if (state == START)
      led1reg = 1;
    if (toggle_led1) begin
      led1reg = !led1reg;
    end else
      led1reg = led1reg;
  end

  // sequential always block
  always @(posedge hwclk) begin
      state <= nextstate;
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [103:0] statename;
  always @* begin
    case (state)
      FAIL         :
        statename = "FAIL";
      IDLE         :
        statename = "IDLE";
      LOCK_UNLOCK  :
        statename = "LOCK_UNLOCK";
      LOCK_UNLOCKED:
        statename = "LOCK_UNLOCKED";
      REPROGRAM    :
        statename = "REPROGRAM";
      REPROGRAMMED :
        statename = "REPROGRAMMED";
      START        :
        statename = "START";
      default      :
        statename = "XXXXXXXXXXXXX";
    endcase
  end
  `endif

endmodule