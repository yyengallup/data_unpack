module data_unpack_datapath #(
  parameter DATA_BITWIDTH = 5,
  parameter OUTPUT_SIZE = 7,

  parameter DATA_SIZE = 2 ** DATA_BITWIDTH
) (
  input wire clk,
  input wire rst,

  input wire [DATA_SIZE - 1:0] data_in, //32 bit word line in
  input wire data_rst, //reset data word buffer
  input wire data_load, //load data word buffer
  input wire data_overflow_load, //load data into overflow buffer from main data buffer
  input wire count_set, //reset counter to 6
  input wire count_en, //enable counter

  output logic [OUTPUT_SIZE - 1:0] data_out, //packet output
  output logic [DATA_BITWIDTH - 1:0] count //counter output for state machine transitions
);


  logic [-1:1 - OUTPUT_SIZE] data_overflow;
  logic [DATA_SIZE - 1:0] data_buf;

  logic [DATA_SIZE - 1:1 - OUTPUT_SIZE] all_data;

  assign all_data = {data_buf, data_overflow}; //for easy addressing
  assign data_out = all_data[count-:OUTPUT_SIZE]; //muxes/address decoders

  //registers
  always_ff @(posedge clk) begin
    //overflow DFF with enable
    if (rst) data_overflow <= 0;
    else     data_overflow <= data_overflow_load ? data_buf[DATA_SIZE - 1:DATA_SIZE - OUTPUT_SIZE - 1] : data_overflow;

    //data buffer DFF with enable
    if (rst | data_rst) data_buf <= 0;
    else                data_buf <= data_load ? data_in : data_buf;

    //counter DFF with enable and count logic. count_set sets to 6
    if (rst) count <= 0;
    else     count <= count_en ? (count_set ? OUTPUT_SIZE - 1 : count + OUTPUT_SIZE) : count;
  end
endmodule
