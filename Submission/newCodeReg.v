// Takes input on button and constructs newcode, keeping track of its length

module newCodeReg(
  clk,
  rst,
  button,
  shift,
  newcode,
  length
);

  input clk;
  input rst;
  input[3:0] button;
  input shift;

  output[23:0] newcode;
  output[2:0] length;
  
  reg[23:0] next;
  reg[2:0] nextindex;
  always @(*) begin
    if (rst) begin
      next = 24'b0;
      nextindex = 3'b0;
    end else if (shift) begin
      next = codereg << 4;
      next[3:0] = button[3:0];
      nextindex = index + 1;
    end else if (index == 3'd7) begin
      next = codereg;
      nextindex = 3'd7;
    end else begin
      next = codereg;
      nextindex = index;
    end   
  end
  
  reg[23:0] codereg;
  reg[2:0] index;
  // Update the new and length(index) on the positive clock edge
  always @(posedge clk) begin
    codereg <= next;
    index <= nextindex;
  end
  
  assign newcode[23:0] = codereg[23:0];
  assign length[2:0] = index[2:0];
     
endmodule