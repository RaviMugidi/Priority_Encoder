class environment;
  virtual encoder_if.DRIVE dr;
  virtual encoder_if.MONITOR mon;
  virtual encoder_if.RD_MONITOR rdmon_if;
  
  mailbox #(transaction) gen2dr=new();
  //mailbox #(transaction) dr2mon=new();
  mailbox #(transaction) mon2rm=new();
  mailbox #(transaction) mon2sb=new();
  mailbox #(transaction) rm2sb=new();
  
  generator gen_h;
  driver dri_h;
  monitor mon_h;
  read_monitor rdmon_h;
  model model_h;
  scoreboard sb_h;
  
  function new(virtual encoder_if.DRIVE dr,
               virtual encoder_if.MONITOR mon,
               virtual encoder_if.RD_MONITOR rdmon_if   
                    );
    this.dr = dr;
    this.mon = mon;
    this.rdmon_if=rdmon_if;
  endfunction:new
  
  task build();
    begin
    gen_h =new(gen2dr);
    dri_h =new(gen2dr,dr);
    mon_h =new(mon2rm,mon);
    rdmon_h =new(mon2sb,rdmon_if);
    model_h =new(mon2rm,rm2sb);
    sb_h =new(mon2sb,rm2sb);
    end
  endtask:build
  
   task start();
     fork
    gen_h.start();
    dri_h.start();
    mon_h.start();
    rdmon_h.start();
    model_h.start();
    sb_h.start();
     join
  endtask:start
  
  task stop();
    wait(sb_h.DONE.triggered);
  endtask:stop
  
  task run();
    begin
      this.start();
      this.stop();
      this.sb_h.report();
    end
  endtask:run
  
endclass
