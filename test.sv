`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "read_monitor.sv"
`include "model.sv"
`include "scoreboard.sv"
`include "environment.sv"

class test;
  virtual encoder_if.DRIVE dr;
  virtual encoder_if.MONITOR mon;
  virtual encoder_if.RD_MONITOR rdmon_if;
  
  environment env;
  
  //transaction data_h1;
  
  function new(virtual encoder_if.DRIVE dr,
               virtual encoder_if.MONITOR mon,
               virtual encoder_if.RD_MONITOR rdmon_if);
    this.dr=dr;
    this.mon=mon;
    this.rdmon_if=rdmon_if;
    env=new(dr,mon,rdmon_if);
  endfunction:new
  
  /*task build_run();
    begin
      env.build();
      env.run();
      $finish;
    end
  endtask*/

  virtual task build();
    env.build();
  endtask
  virtual task run();
    env.run();
  endtask
endclass:test
