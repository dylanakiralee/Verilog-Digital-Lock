// Pattern-matching; gets an input on BUTTON, and if BPRESS is high, it checks it against CORRECT_CODE
// If the code matches, DONE and SUCCESS will go high together
// If not, DONE will go high alone

module enter_code (
  CLK,
  RST,
  GO,
  BUTTON,
  BPRESS,
  // Code to check against and its length
  CORRECT_CODE,
  LENGTH,
  // Button that indicates the user is done inputting
  ENTER_BUTTON,
  DONE,
  SUCCESS
);

  input CLK;
  input RST;
  input GO;
  input[3:0] BUTTON;
  input BPRESS;
  input[23:0] CORRECT_CODE;
  input[2:0] LENGTH;
  input[3:0] ENTER_BUTTON;

  output DONE;
  output SUCCESS;

  // state bits
  parameter 
  START     = 4'b0000, // extra=00 SUCCESS=0 DONE=0 
  CORRECT   = 4'b0011, // extra=00 SUCCESS=1 DONE=1 
  ENTER     = 4'b0100, // extra=01 SUCCESS=0 DONE=0 
  INCORRECT = 4'b0001, // extra=00 SUCCESS=0 DONE=1 
  WAIT      = 4'b1000, // extra=10 SUCCESS=0 DONE=0 
  BUFFER    = 4'b1100; // extra=11 SUCCESS=0 DONE=0

  reg [3:0] state;
  reg [3:0] nextstate;

  //
  wire inc;
  wire[2:0] index;
  // Button to check against
  wire[3:0] current_button;
  wire kmatch;
  wire lmatch;
  
  // Modules
  // Keeps track of the length of the inputted code
  counter counter_1(
    .clk(CLK),
    .rst(RST),
    .inc(inc),
    .index(index)
  );
  
  // Based on the current index, gives the rquired button to check against
  codeReg codeReg_1(
    .clk(CLK),
    .rst(RST),
    .code(CORRECT_CODE),
    .index(index),
    .length(LENGTH),
    .current_button(current_button)
  );
  
  // Determines whether to access the next button 
  assign inc = (state == ENTER) & BPRESS & BUTTON[3:0] != ENTER_BUTTON[3:0];
  assign kmatch = BUTTON[3:0] == current_button[3:0];
  assign lmatch = index[2:0] == LENGTH[2:0];

  // comb always block
  always @* begin
    nextstate = 4'bxxxx; // default to x because default_state_is_x is set
    case (state)
      START    : begin
        if (GO) begin
          nextstate = BUFFER;
        end
        else begin
          nextstate = START;
        end
      end
      BUFFER   : begin
        begin
          nextstate = ENTER;
        end
      end
      CORRECT  : begin
        begin
          nextstate = START;
        end
      end
      ENTER    : begin
        if (BUTTON[3:0] == ENTER_BUTTON[3:0] & BPRESS & lmatch) begin
          nextstate = CORRECT;
        end
        else if (BUTTON[3:0] != ENTER_BUTTON[3:0] & BPRESS & !kmatch) begin
          nextstate = WAIT;
        end
        else if (BUTTON[3:0] == ENTER_BUTTON[3:0] & BPRESS & !lmatch) begin
          nextstate = INCORRECT;
        end
        else begin
          nextstate = ENTER;
        end
      end
      INCORRECT: begin
        begin
          nextstate = START;
        end
      end
      WAIT     : begin
        if (BUTTON[3:0] == ENTER_BUTTON[3:0] & BPRESS) begin
          nextstate = INCORRECT;
        end
        else begin
          nextstate = WAIT;
        end
      end
    endcase
  end

  // Assign reg'd outputs to state bits
  assign DONE = state[0];
  assign SUCCESS = state[1];

  // sequential always block
  always @(posedge CLK) begin
    if (RST)
      state <= START;
    else
      state <= nextstate;
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [71:0] statename;
  always @* begin
    case (state)
      START    :
        statename = "START";
      BUFFER   :
        statename = "BUFFER";
      CORRECT  :
        statename = "CORRECT";
      ENTER    :
        statename = "ENTER";
      INCORRECT:
        statename = "INCORRECT";
      WAIT     :
        statename = "WAIT";
      default  :
        statename = "XXXXXXXXX";
    endcase
  end
  `endif

endmodule