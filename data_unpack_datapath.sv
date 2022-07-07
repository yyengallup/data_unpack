module data_unpack_datapath(
  input wire clk,
  input wire rst,

  input wire [31:0] data_in, //32 bit word line in
  input wire data_rst, //reset data word buffer
  input wire data_load, //load data word buffer and overflow buffer
  input wire count_set, //reset counter to 6

  output logic [6:0] data_out, //packet output
  output logic [4:0] count); //counter output for state machine transitions

  logic [-1:-6] data_overflow;
  logic [31:0] data_buf;

  logic [31:-6] all_data;

  assign all_data = {data_buf, data_overflow}; //for easy addressing
  assign data_out = all_data[count-:7];

  //registers
  always_ff @(posedge clk) begin
    //overflow DFF with enable
    if (rst) data_overflow <= 6'b0;
    else     data_overflow <= data_load ? data_buf[31:26] : data_overflow;

    //data buffer DFF with enable
    if (rst | data_rst) data_buf <= 32'b0;
    else                data_buf <= data_load ? data_in : data_buf;

    //counter FF and count logic. count_set sets to 6
    if (rst) count <= 5'b0;
    else     count <= count_set ? 5'd6 : count + 5'd7;
  end
endmodule
