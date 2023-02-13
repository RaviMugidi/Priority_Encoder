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
