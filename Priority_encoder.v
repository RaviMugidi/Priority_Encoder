module Priority_Encoder(a,clk,vin,vout,out);
  input clk;
  input vin;
  input [7:0] a;
  output[2:0] out;
  output vout;
  reg[2:0] out;
  reg vout;
  always@(posedge clk)
    begin
      if(!vin)
        begin
          out = 3'b000;
          vout = 1'b1;
        end
      else
        begin
          vout =1'b0;
          if(a[7])
            out = 3'b111;
          else if(a[6])
            out = 3'b110;
          else if(a[5])
            out = 3'b101;
          else if(a[4])
            out = 3'b100;
          else if(a[3])
            out = 3'b011;
          else if(a[2])
            out = 3'b010;
          else if(a[1])
            out = 3'b001;
          else 
            out =3'b000; 
        end         
    end
endmodule
