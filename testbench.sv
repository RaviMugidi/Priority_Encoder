// Top Module code
`include "test.sv"
module top();
  reg clk;
  
  initial clk=0;
  always@(clk) #5 clk<=~clk;
  
  encoder_if IF(clk);
  
  Priority_Encoder DUT(
    .clk(clk),
    .a(IF.data_in),
    .vin(IF.vin),
    .vout(IF.vout),
    .out(IF.out)
);
  
  test th;
  initial 
    begin
      th =new(IF,IF,IF);
      //th.build_run();
      //th.start();
      th.build();
      th.run();
      $finish;
    end
endmodule

//Interface which is used to make interconnection between the design and testbench.

interface encoder_if(input reg clk);
  reg [7:0] data_in;
  reg vin;
  logic [2:0] out;
  logic vout;
  
  clocking driver_cb@(posedge clk);
    default input #1 output#1;
    output data_in;
    output vin;
  endclocking:driver_cb
  
  clocking monitor_cb@(posedge clk);
    default input #1 output#1;
    input data_in;
    input vin;
  endclocking:monitor_cb
  
  clocking rd_monitor_cb@(posedge clk);
    default input #1 output#1;
    input out;
    input vout;
  endclocking:rd_monitor_cb
  
  modport DRIVE(clocking driver_cb);
  modport MONITOR(clocking monitor_cb);
  modport RD_MONITOR(clocking rd_monitor_cb);
endinterface:encoder_if
    
    
