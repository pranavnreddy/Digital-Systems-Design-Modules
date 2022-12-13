module ct_mod_D(
  input             clk, 
                    rst, 
                    en,
  logic [4:0] modulus,
  output logic[6:0] ct_out,
  output logic      z);

  logic [6:0] next_ct;
  
  always_ff @(posedge clk)
     ct_out <= next_ct;    

   always_comb
     if(rst) 
	   next_ct = 0;
	 else if(en)
       next_ct = (ct_out + 1) % modulus;
	 else 
	   next_ct = ct_out; 
  always_comb z = ct_out==(modulus-1);
endmodule