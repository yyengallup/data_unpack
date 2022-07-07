module data_unpack_tb();

  logic clk, rst;
  logic test_num;
  logic [34:0] test_inputs [99:0]; //32 bit data in, sop_in, eop_in, valid_in

  logic ready_out, valid_in, sop_in, eop_in;
  logic [31:0] data_in;

  logic valid_out, sop_out, eop_out;
  logic [6:0] data_out;

  always begin
    clk = ~clk; #5;
  end

  data_unpack DUT(.*);

  assign data_in = test_inputs[test_num][31:0];
  assign sop_in = test_inputs[test_num][34];
  assign eop_in = test_inputs[test_num][33];
  assign valid_in = test_inputs[test_num][32];

  initial begin
    rst = 1'b1; #10
    rst = 1'b0;

    test_num = 0;

    $readmemb("data_unpack_testcases.mem", test_inputs);

  end

  always @(negedge clk) begin
    if(~rst) begin
      if(ready_out && valid_in) begin
        test_num = test_num + 1; //increment test number if ready out is asserted
      end
    end
  end


endmodule
