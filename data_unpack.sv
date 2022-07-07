//
// Input interface:
// ================
// ready_out Output; Set ready_out to true when there is room to accept a new word, else false.
// valid_in Input; When true AND ready_out is true, a word is deemed received by this module
// data_in[31:0] Input; LSB-aligned 32-bit data word
// sop_in Input; True when this is the first data word for a packet
// eop_in Input; True when this is the last data word for a packet
//
// Output interface:
// =================
// valid_out Output; True for each cycle where a value is presented
// data_out Output; Output value, only valid when valid_out == 1
// sop_out Output; Present along with the first valid value for a packet
// eop_out Output; Present along with the last valid value for a packet
//
// Requirements:
// =============
// 1) Values extracted from data_in are LSB-first.
// 2) Valid Packets start with start of packet (sop_in) flag and end with an end of packet flag (eop_in).
// Values received after an eop_in but before sop_in should be discarded.
// 3) When eop_in is received, residual state should be cleared after the last output value is presented
// so the next packet can be processed cleanly.
// 4) The general use case would be expected to have a packet length which is a multiple of 7-bit output
// words. The upper bits of the last sample should be zeroed out if the packet is not a multiple of
// 7-bit words.
// 5) If valid data is ready at the input there must be a continuous stream of output values (no gaps).
// Some latency between the first word in and the first value out is to be expected.
// 6) If the Input stream is sending data, minimize the # of dead cycles (ideally 0) between packets
// on the output.
//
// Example:
// ========
// sop_in eop_in value_in data_out sop_out eop_out
// 0: 1 0 32'b1111_0000_0000_1100_1100_0000_0101_1010
// 7'b101_1010 1 0
// 7'b000_0000 0 0

// 7'b011_0011 0 0
// 7'b000_0000 0 0
// 1: 0 0 32'b0111_1101_0000_0000_0000_0000_0000_0111
// 7'b111_1111 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b111_1101 0 0
// 2: 0 0 32'b0000_0000_0000_0000_0000_0000_0010_0000
// 7'b100_0000 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// ..... ..... ..... ..... ..... ..... ..... ..... .....
// 6: 0 1 32'b1111_1110_0000_0000_0000_0000_0000_0000
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b000_0000 0 0
// 7'b111_1111 0 1
//
module data_unpack (
  input wire clk,
  input wire rst,

  output logic ready_out, // Can be used to back pressure the input data stream
  input wire valid_in,
  input wire [31:0] data_in,
  input wire sop_in,
  input wire eop_in,

  output logic valid_out,
  output logic [6:0] data_out,
  output logic sop_out,
  output logic eop_out);

  enum {IDLE, SOP, LD, INC, WAIT, LD_FINAL, EOP, ERROR} state, next_state;

  logic data_rst, data_load, data_overflow_load, count_set, eop_in_buf;
  logic [4:0] count;

  data_unpack_datapath datapath(.*);

  always_ff @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      eop_in_buf <= 1'b1;
    end else begin
      state <= next_state;
      eop_in_buf <= data_load ? eop_in : eop_in_buf; //enable eop_in_buf load with data_load
    end
  end

  always_comb begin
    next_state = ERROR; //for debug, if missing next_state definition
    {sop_out, count_set, data_load, ready_out, valid_out, data_rst, eop_out} = 'b0;

    case(state)
      IDLE: begin
        if (sop_in & valid_in) next_state = SOP;//transition out of IDLE on sop_in
        else        next_state = IDLE;

        count_set = 1'b1;
        data_load = 1'b1;
        ready_out = 1'b1;
      end
      SOP: begin
        next_state = INC;

        valid_out = 1'b1;
        sop_out = 1'b1;
      end
      LD: begin
        if (valid_in) next_state = INC; //load state is always one cycle then back to INC
        else          next_state = WAIT;

        //load data and assert ready for new data.
        data_load = 1'b1;
        data_overflow_load = 1'b1;
        ready_out = 1'b1;

        valid_out = 1'b1; //data is still valid during load operation
      end
      WAIT: begin
        if (valid_in) next_state = INC;
        else          next_state = WAIT;

        data_load = 1'b1;//only load main data register, not overflow
        ready_out = 1'b1;
        //data is not valid while waiting
      end
      INC: begin
        //two cycles from overflowing, need to be in LD one cycle before count overflow
        //if final word of packet and packets aligned go to EOP otherwise go to LD_FINAL first to fill 0's in MSB's
        //this comparison can be LUT for speed, 7 values of interest, plus check eop_in_buf for 14 possible values
        if (count >= 18) next_state = eop_in_buf ? (count == 24 ? EOP : LD_FINAL) : LD;
        else             next_state = INC;

        valid_out = 1'b1;
      end
      LD_FINAL: begin
        next_state = EOP;

        data_rst = 1'b1;
        data_overflow_load = 1'b1; //only care about loading overflow data, main data is reset
        valid_out = 1'b1;
      end
      EOP: begin
        if (sop_in & valid_in) next_state = SOP; //if next packet is ready jump straight in
        else        next_state = IDLE;

        eop_out = 1'b1;
        valid_out = 1'b1;

        count_set = 1'b1; //reset count in case we go directly into next packet
        data_load = 1'b1;
        ready_out = 1'b1;
      end
    endcase
  end
endmodule
