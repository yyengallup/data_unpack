module data_unpack_tb();

  logic clk, rst;
  logic [6:0] test_num;
  logic [34:0] test_inputs [127:0]; //32 bit data in, sop_in, eop_in, valid_in
  logic [8:0] output_num;
  logic [8:0] test_outputs [511:0];

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
    clk = 1'b0;

    $readmemb("data_unpack_test_inputs.mem", test_inputs);
    $readmemb("data_unpack_test_outputs.mem", test_outputs);

    $monitor("[Test Case] #%d : %b", test_num, test_inputs[test_num]);

    rst = 1'b1; #10
    rst = 1'b0;
    #10
    {test_num, output_num} = 0;
  end

  always @(posedge clk) begin
    if(~rst) begin
      if(ready_out) begin
        test_num = test_num + 1; //increment test number if ready out is asserted
      end

      if (valid_out) begin
        assert ({sop_out, eop_out, data_out} == test_outputs[output_num])
        else $error("Incorrect output, packet #%d. Was %b should have been %b", output_num, {sop_out, eop_out, data_out}, test_outputs[output_num]);

        output_num = output_num + 1;
      end
    end
  end

  always_comb begin
    if (test_num == 30) $stop;
  end

endmodule
