// Module that determines whether input on BUTTON is a valid UC
// If so, DONE and SUCCESS are raised, and the new UC is described in NEWCODE and NEWLENGTH

module enter_new_code (
  CLK,
  RST,
  GO,
  BUTTON,
  BPRESS,
  ENTER_BUTTON,
  NEWCODE,
  NEWLENGTH,
  DONE,
  SUCCESS
);

  input CLK;
  input RST;
  input GO;
  input[3:0] BUTTON;
  input BPRESS;
  input[3:0] ENTER_BUTTON;

  output SUCCESS;
  output DONE;
  output[23:0] NEWCODE;
  output[2:0] NEWLENGTH;

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

  wire shift;
  reg kvalid;
  reg lvalid;
  
  //Modules 
  newCodeReg newCodeReg_1(
    .clk(CLK),
    .rst(RST),
    .button(BUTTON),
    .shift(shift),
    .newcode(NEWCODE),
    .length(NEWLENGTH)
  );

  always @(*) begin
    kvalid = BUTTON[3:0] >= 4'd1 & BUTTON[3:0] <= 4'd6;
    lvalid = NEWLENGTH[2:0] >= 3'd4 & NEWLENGTH[2:0] <= 3'd6;
  end
  
  // Shift the NEWCODE left and add BUTTON to the end if a valid button press has occurred
  assign shift = state == ENTER & BPRESS & BUTTON[3:0] != ENTER_BUTTON[3:0];
  

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
        if (BUTTON[3:0] == ENTER_BUTTON[3:0] & BPRESS & lvalid) begin
          nextstate = CORRECT;
        end
        else if (BUTTON[3:0] != ENTER_BUTTON[3:0] & BPRESS & !kvalid) begin
          nextstate = WAIT;
        end
        else if (BUTTON[3:0] == ENTER_BUTTON[3:0] & BPRESS & !lvalid) begin
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