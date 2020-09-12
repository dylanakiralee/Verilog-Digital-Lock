// Controls the blinking of the LEDs
// Outputs a signal that is 0 for OFF deciseconds, 1 for ON deciseconds, and repeats that sequence REPEAT times

module blink (
  CLK,
  RST,
  GO,
  // Number of deciseconds that LED should remain on/off
  ON,
  OFF,
  // Number of times that LED should blink
  REPEAT,
  DONE,
  LED
);

  input CLK;
  input RST;
  input GO;
  input[4:0] ON;
  input[4:0] OFF;
  input[2:0] REPEAT;

  output DONE;
  output LED;
  reg C_DONE;

  // state bits
  parameter 
  START    = 2'b00, // extra=0 DONE=0 
  COMPLETE = 2'b01, // extra=0 DONE=1 
  COUNTING = 2'b10; // extra=1 DONE=0 
  parameter CLKFREQ = 24'd12000000;
  
  reg[31:0] numCyclesOn;
  reg[31:0] numCyclesOff;
  reg[31:0] counter;
  reg[3:0] numRepeats;

  reg [1:0] state;
  reg [1:0] nextstate;

  reg tempLED;
  
  // Datapath (Controls the blinking)
  always @(posedge CLK) begin
    if (state == COUNTING) begin
      numCyclesOn = CLKFREQ * ON / 10;
      numCyclesOff = CLKFREQ * OFF / 10;
      counter <= counter + 1;
      if (!LED & counter == numCyclesOff) begin
        tempLED <= 1;
        counter <= 0;
      end
      else if (counter == numCyclesOn) begin
        tempLED <= 0;
        counter <= 0;
        if (numRepeats == REPEAT - 1) begin
          numRepeats = 0;
          C_DONE = 1;
        end
        else
          numRepeats <= numRepeats + 1;
      end
    end
    else begin
      counter <= 0;
      numRepeats <= 0;
      C_DONE <= 0;
    end
  end

  // comb always block
  always @* begin
    nextstate = 2'bxx; // default to x because default_state_is_x is set
    case (state)
      START   : begin
        if (GO) begin
          nextstate = COUNTING;
        end
        else begin
          nextstate = START;
        end
      end
      COMPLETE: begin
        begin
          nextstate = START;
        end
      end
      COUNTING: begin
        if (C_DONE) begin
          nextstate = COMPLETE;
        end
        else begin
          nextstate = COUNTING;
        end
      end
    endcase
  end

  // Assign reg'd outputs to state bits
  assign DONE = state[0];
  assign LED = tempLED;

  // sequential always block
  always @(posedge CLK) begin
    if (RST)
      state <= START;
    else
      state <= nextstate;
  end

  // This code allows you to see state names in simulation
  `ifndef SYNTHESIS
  reg [63:0] statename;
  always @* begin
    case (state)
      START   :
        statename = "START";
      COMPLETE:
        statename = "COMPLETE";
      COUNTING:
        statename = "COUNTING";
      default :
        statename = "XXXXXXXX";
    endcase
  end
  `endif

endmodule