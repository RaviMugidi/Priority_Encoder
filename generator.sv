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
