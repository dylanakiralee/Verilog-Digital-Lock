// Gives the current_button in the index position of code, starting from 0 at the MSB

module codeReg(
  clk,
  rst,
  code,
  index,
  length,
  current_button
);

  input clk;
  input rst;
  input[23:0] code;
  input[2:0] index;
  input[2:0] length;

  output[3:0] current_button;
  
  // Shifts the code so that the current_button is the 4 most significant bits
  // Accounts for the length and 4 bit width of each button
  wire[23:0] temp = code[23:0] << 4*(index + (6-length));
  
  assign current_button = temp[23:20];
endmodule