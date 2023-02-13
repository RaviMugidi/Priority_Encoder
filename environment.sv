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


class transaction;
  rand bit [7:0]a;
  logic [2:0]out;
  rand bit vin;
  logic vout;
  
  static int trans_id;
  
  constraint valid_a{ a inside {1,2,4,9,17,35,68,129};}
  constraint valid_vin{vin==1;}
  
  function void post_randomize();
    trans_id++;
    this.display("Random Data");
  endfunction:post_randomize
  
  function void display(input string str);
    $display("%s",str);
    if(str=="Random Data")
      begin
        $display("------------------------------------------------");
        $display("\t Transaction No:%0d",trans_id);
      end
    
    $display("a=%b\tvin=%b\nout=%d\tvout=%b",a,vin,out,vout);
    $display("----------------------------------------------------");
  endfunction:display
  
    function bit compare(input transaction rcd_data,output string message);
      //compare ='1;
      begin
        if(this.out != rcd_data.out)
          begin
            message = "OUTPUT MISMATCH,INVALID BINARY CODE GENERATED";
            return(0);
          end
        else if(this.vout!=rcd_data.vout)
          begin
            message ="OUTPUT ENABLE MISMATCH";
            return(0);
          end
        else
          return(1);
        begin
          message="SUCCESSFULLY VERIFIED";
        end
      end
    endfunction:compare  
endclass:transaction


class generator;
  int number_of_transactions=5;
  transaction packet1,packet2;
  mailbox #(transaction) gen2dr;
  
  function new(mailbox #(transaction) gen2dr);
    this.gen2dr=gen2dr;
  endfunction:new
  
  task start();
    fork
      repeat(number_of_transactions)
        begin
          packet1=new();
          assert(packet1.randomize());
          packet2=new packet1;
          gen2dr.put(packet2);
        end
    join_none
  endtask:start
endclass:generator


class driver;
  transaction dr_data;
  mailbox #(transaction) gen2dr;
  virtual encoder_if.DRIVE dr;
  
  function new(mailbox #(transaction) gen2dr,
               virtual encoder_if.DRIVE dr);
    this.gen2dr=gen2dr;
    this.dr= dr;
    //dr_data=new();
  endfunction:new
  
  task Drive();
    begin
      @(dr.driver_cb);
      dr.driver_cb.data_in <= dr_data.a;
      dr.driver_cb.vin <= dr_data.vin;
    end  
  endtask
  
  task start();
    fork
      forever
        begin
          gen2dr.get(dr_data);
          this.Drive();
        end
    join_none
  endtask:start
endclass:driver


class monitor;
  transaction data2rm,wr_data;
  mailbox #(transaction) mon2rm;
  //mailbox #(transaction) mon2sb;
  
  virtual encoder_if.MONITOR mon;
  
  function new(mailbox #(transaction) mon2rm,
                    virtual encoder_if.MONITOR mon);
    this.mon2rm=mon2rm;
    this.mon=mon;
    this.wr_data=new();
  endfunction:new
  
  virtual task Monitor();
    begin
      wait(mon.monitor_cb.vin==1'b1);
      repeat(1)
        @(mon.monitor_cb);
    begin
      wr_data.a <= mon.monitor_cb.data_in;
      wr_data.vin <= mon.monitor_cb.vin;
      
      wr_data.display("MONITOR DATA");
    end
      
   end
  endtask:Monitor
  
 virtual task start();
    fork
      forever
        begin
          Monitor(); 
          data2rm= new wr_data;
          mon2rm.put(data2rm);
        end
    join_none
  endtask
endclass

class read_monitor;
  transaction data2sb,rd_data;
  mailbox #(transaction) mon2sb;
  //mailbox #(transaction) mon2sb;
  
  virtual encoder_if.RD_MONITOR rdmon_if;
  
  function new(mailbox #(transaction) mon2sb,
                    virtual encoder_if.RD_MONITOR rdmon_if);
    this.mon2sb=mon2sb;
    this.rdmon_if=rdmon_if;
    this.rd_data=new();
  endfunction:new
  
  virtual task Monitor();
   begin
     repeat(3)
     @(rdmon_if.rd_monitor_cb);
    begin
      rd_data.out = rdmon_if.rd_monitor_cb.out;
      rd_data.vout = rdmon_if.rd_monitor_cb.vout;
      rd_data.display("READ MONITOR DATA");
    end
   end
  endtask:Monitor
  
 virtual task start();
    fork
      forever
        begin
          Monitor(); 
          data2sb= new rd_data;
          mon2sb.put(data2sb);
        end
    join_none
  endtask
endclass:read_monitor


class model;
  transaction mon_data1;
  transaction mon_data2;
  
  mailbox #(transaction) mon2rm;
  mailbox #(transaction) rm2sb;
  
  static logic[2:0] en_out;
  static logic en_vout;
  
  function new(mailbox #(transaction) mon2rm,
                    mailbox #(transaction) rm2sb);
    this.mon2rm=mon2rm;
    this.rm2sb=rm2sb;
    //mon_data1=new();
  endfunction:new
  
  task ref_model(transaction mon_data1);
    begin
      if(!mon_data1.vin)
        begin
          en_vout=1'b1;
          en_out = 3'b000;
        end
      else
        begin
          //mon_data1.vout = 1'b0;
          en_vout = 1'b0;
          if(mon_data1.a[7])
            //mon_data1.out = 3'b111;
            en_out = 3'b111;
          else if(mon_data1.a[6])
            //mon_data1.out = 3'b110;
            en_out = 3'b110;
          else if(mon_data1.a[5])
           // mon_data1.out = 3'b101;
            en_out = 3'b101;
          else if(mon_data1.a[4])
            //mon_data1.out = 3'b100;
            en_out = 3'b100;
          else if(mon_data1.a[3])
            //mon_data1.out = 3'b011;
            en_out = 3'b011;
          else if(mon_data1.a[2])
            //mon_data1.out = 3'b010;
            en_out = 3'b010;
          else if(mon_data1.a[1])
            //mon_data1.out = 3'b001;
            en_out =3'b001;
          else 
            //mon_data1.out =3'b000;
            en_vout =3'b000;
        end
    end
  endtask:ref_model
  
  task start();
    fork
      forever
        begin
          mon2rm.get(mon_data1);
          mon_data2=new mon_data1;
          this.ref_model(mon_data2);
          //mon_data2=new mon_data1;
          mon_data2.out = en_out;
          mon_data2.vout =en_vout;
          rm2sb.put(mon_data2);
        end
    join_none
  endtask
endclass:model


class scoreboard;
  
  int number_of_transactions=5;
  mailbox #(transaction) mon2sb;
  mailbox #(transaction) rm2sb;
  
  event DONE;
  
  transaction rcvd_data,sb_data;
  transaction rm_data;
  
  int mon_data_count=0;
  int rm_data_count=0;
  int data_verified=0;
  
  function new(mailbox #(transaction) mon2sb,
                    mailbox #(transaction) rm2sb);
    this.mon2sb=mon2sb;
    this.rm2sb=rm2sb;
  endfunction:new
  
  task start();
    fork 
      forever
        begin
          rm2sb.get(rm_data);
          rm_data_count++;
          mon2sb.get(rcvd_data);
          mon_data_count++;
          sb_data=new rcvd_data;
          check(sb_data);
        end
    join_none
  endtask:start
   
  function void check(transaction rc_data);
          begin
            string diff;
            if(!(rm_data.compare(rc_data,diff)))
              begin:failed_compare
                rc_data.display("SB:Received data");
                rm_data.display("SB: Data sent to DUV");
                $display("%s",diff);
                $finish;
              end:failed_compare
            data_verified++;
            if(data_verified==(number_of_transactions))
              begin
               ->DONE;
              end
          end
  endfunction:check
  
  task report();
    $display("Read Data Generated =%0p\t Received Data=%0p\tData Verified=%0p",rm_data_count,mon_data_count,data_verified);
  endtask
endclass:scoreboard
