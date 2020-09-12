// Module to reprogram the UC of the digital lock.
// Outputs the NEWCODE, and NEWLENGTH if the PC is input correctly and the two UCs are valid and match

module reprogram (
  CLK,
  RST,
  GO,
  PC,
  PC_LENGTH,
  UC,
  UC_LENGTH,
  BUTTON,
  BPRESS,
  DONE,
  SUCCESS,
  NEWCODE,
  NEWLENGTH
);

  input CLK;
  input RST;
  input GO;
  input[23:0] PC;
  input[2:0] PC_LENGTH;
  input[23:0] UC;
  input[2:0] UC_LENGTH;
  input[3:0] BUTTON;
  input BPRESS;

  output DONE;
  output SUCCESS;
  output[23:0] NEWCODE;
  output[2:0] NEWLENGTH;  

  // state bits
  parameter 
  START     = 5'b00000, // extra=0 SUCCESS=0 NEW_GO=0 DONE=0 CODE_GO=0 
  ENTER_PC  = 5'b00001, // extra=0 SUCCESS=0 NEW_GO=0 DONE=0 CODE_GO=1 
  ENTER_UC1 = 5'b00100, // extra=0 SUCCESS=0 NEW_GO=1 DONE=0 CODE_GO=0 
  ENTER_UC2 = 5'b10001, // extra=1 SUCCESS=0 NEW_GO=0 DONE=0 CODE_GO=1 
  FAILURE   = 5'b00010, // extra=0 SUCCESS=0 NEW_GO=0 DONE=1 CODE_GO=0 
  COMPLETE  = 5'b01010; // extra=0 SUCCESS=1 NEW_GO=0 DONE=1 CODE_GO=0 

  reg [4:0] state;
  reg [4:0] nextstate;

  reg[23:0] CODE;
  reg[2:0] LENGTH;

  // Control signals for the pattern-matching and input modules
  wire CODE_GO;
  wire NEW_GO;
  wire CODE_DONE;
  wire CODE_SUCCESS;
  wire NEW_DONE;
  wire NEW_SUCCESS;
  wire CODE_RST;

  // Modules
  // Checks input vs. the PC or the new UC (reused in those two steps)
  enter_code pattern_matching(
    .CLK(CLK),
    .RST(CODE_RST),
    .GO(CODE_GO),
    .BUTTON(BUTTON),
    .BPRESS(BPRESS),
    .CORRECT_CODE(CODE),
    .LENGTH(LENGTH),
    .ENTER_BUTTON(4'd8),
    .DONE(CODE_DONE),
    .SUCCESS(CODE_SUCCESS)
  );

  // Checks to see whether input is a valid UC
  enter_new_code input_new_UC(
    .CLK(CLK),
    .RST(RST),
    .GO(NEW_GO),
    .BUTTON(BUTTON),
    .BPRESS(BPRESS),
    .ENTER_BUTTON(4'd8),
    .NEWCODE(NEWCODE),
    .NEWLENGTH(NEWLENGTH),
    .DONE(NEW_DONE),
    .SUCCESS(NEW_SUCCESS)
  );

  // Resets the pattern_matching module halfway through the FSM to be reused for the second new UC step
  assign CODE_RST = state == ENTER_UC1 | RST;

  // comb always block
  always @* begin
    nextstate = 5'bxxxxx; // default to x because default_state_is_x is set
    case (state)
      START    : begin
        if (GO) begin
            nextstate = ENTER_PC;
          end
          else begin
            nextstate = START;
          end
      end
      ENTER_PC : begin
        CODE = PC;
        LENGTH = PC_LENGTH;
        if (CODE_DONE & CODE_SUCCESS) begin
          nextstate = ENTER_UC1;
        end
        else if (CODE_DONE & !CODE_SUCCESS) begin
          nextstate = FAILURE;
        end
        else begin
          nextstate = ENTER_PC;
        end
      end
      ENTER_UC1: begin
        if (NEW_DONE & NEW_SUCCESS) begin
          nextstate = ENTER_UC2;
        end
        else if (NEW_DONE & !NEW_SUCCESS) begin
          nextstate = FAILURE;
        end
        else begin
          nextstate = ENTER_UC1;
        end
      end
      ENTER_UC2: begin
        CODE = NEWCODE;
        LENGTH = NEWLENGTH;
        if (CODE_DONE & CODE_SUCCESS) begin
          nextstate = COMPLETE;
        end
        else if (CODE_DONE & !CODE_SUCCESS) begin
          nextstate = FAILURE;
        end
        else begin
          nextstate = ENTER_UC2;
        end
      end
      FAILURE  : begin
        begin
          nextstate = START;
        end
      end
      COMPLETE  : begin
        begin
          nextstate = START;
        end
      end
    endcase
  end

  // Assign reg'd outputs to state bits
  assign CODE_GO = state[0];
  assign DONE = state[1];
  assign NEW_GO = state[2];
  assign SUCCESS = state[3];

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
      ENTER_PC :
        statename = "ENTER_PC";
      ENTER_UC1:
        statename = "ENTER_UC1";
      ENTER_UC2:
        statename = "ENTER_UC2";
      FAILURE  :
        statename = "FAILURE";
      SUCCESS  :
        statename = "COMPLETE";
      default  :
        statename = "XXXXXXXXX";
    endcase
  end
  `endif

endmodule