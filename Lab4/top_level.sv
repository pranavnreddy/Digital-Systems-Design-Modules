// starter code for Lab 4
// CSE140L
module top_level (
  input        clk, 
               init,
  output logic done);

// dat_mem interface
// you will need this to talk to the data memory
logic         write_en;        // data memory write enable        
logic[8-1:0]  raddr,           // read address pointer
              waddr;           // write address pointer
logic[8-1:0]  data_in;         // to dat_mem
wire [8-1:0]  data_out;        // from dat_mem
// LFSR control input and data output
logic         LFSR_en;         // 1: advance LFSR; 0: hold		
// taps, start, pre_len are constants loaded from dat_mem [61:63]
logic[   5:0] taps,            // LFSR feedback pattern temp register
              start;           // LFSR initial state temp register
logic[   7:0] pre_len;         // preamble (_____) length           
logic         taps_en,         // 1: load taps register; 0: hold
              start_en,        //   same for start temp register
              prelen_en;       //   same for preamble length temp
logic         load_LFSR;       // copy taps and start into LFSR
wire [   5:0] LFSR;            // LFSR current value            
logic[   7:0] scram;           // encrypted message
logic[   7:0] ct_inc;          // prog count step (default = +1)

// instantiate the data memory 
dat_mem dm1(.clk, .write_en, .raddr, .waddr,
            .data_in, .data_out);

// instantiate the LFSR core
// need one for Lab 4; may want 6 for Lab 5
lfsr6 l6(.clk, .en(LFSR_en), .init(load_LFSR),
         .taps, .start, .state(LFSR));

logic[7:0] ct;                  // your program counter
// this can act as a program counter
always @(posedge clk)
  if(init) begin
    ct <= 0;
  end
  else begin
    ct <= ct + ct_inc;     // default: next_ct = ct+1
  end

// control decode logic (does work of instr. mem and control decode)
always_comb begin
// list defaults here; case needs list only exceptions
  write_en  = 'b0;         // data memory write enable        
  LFSR_en   = 'b0;         // 1: advance LFSR; 0: hold		
// enables to load control constants read from dat_mem[61:63] 
  prelen_en = 'b0;         // 1: load pre_len temp register; 0: hold
  taps_en   = 'b0;         // 1: load taps temp register; 0: hold
  start_en  = 'b0;         // 1: load start temp register; 0: hold
  load_LFSR = 'b0;         // copy taps and start into LFSR
// PC normally advances by 1
// override to go back in a subroutine or forward/back in a branch 
  ct_inc    = 'b1;         // PC normally advances by 1
  data_in = data_out;
  case(ct)
    0,1: begin   
           raddr     = 'd0;         // memory read address pointer
   	   waddr     = 'd64;    	// memory write address pointer
         end       // no op to wait for things to settle from init
// first tasks to be done:
// 1) raddr = 61, prelen_en = 1
//    pre_len <= data_out  
// 2) raddr = 62, taps_en = 1
//    taps <= data_out
// 3) raddr = 63, start_en = 1
//    start <= data_out
    2:   begin             // load pre_len temp register
           raddr      = 'd61;
           waddr      = 'd64;         // memory write address pointer
           prelen_en  = 'b1;
         end
    3:   begin             // load taps temp reg
           raddr      = 'd62;   
           waddr      = 'd64;
           taps_en    = 'b1;
         end               // load LFSR start temp reg
    4:   begin
           raddr      = 'd63;
	   waddr      = 'd64;
           start_en   = 'b1;
         end
    5:   begin
	   raddr      = 'd0;
	   waddr      =	'd64;
	   load_LFSR  = 'b1;   // copy taps and start temps into LFSR
	 end
    6:   begin             
	   raddr      = 'd0;
           waddr      =	'd64;
         end       
    default: begin
/* What happens next?
   1)  for pre_len cycles, bitwise XOR ASCII _ = 0x5f with current
     LFSR state; prepend LFSR state with 2'b00 to pad to 8 bits
     write each successive result into dat_mem[64], dat_mem[65], etc.
     advance LFSR to next state while writing result  
   2) after pre_len operations, start reading data from dat_mem[0], [1], ...
     bitwise XOR each value w/ current LFLSR state
     store successively in dat_mem[64+pre_len+j], where j = 0, 1, ..., 49
     advance LFSR to next state while writing each result
     
You may want some sort of memory address counter or an adder that creates
an offset from the prog_counter.

Watch how the testbench performs Prog. 4. You will be doing the same 
operation, but at a more detailed, hardware level, instead of at the 
higher level the testbench uses.       
*/
           LFSR_en = 1;
           waddr = ct + 7'd57;
           raddr = (ct - 6 > pre_len) ? ct - pre_len - 6 : 0;
           data_in = data_out^{2'b0,LFSR};
           write_en = 1;
           

         end
  endcase
end 


// load control registers from dat_mem 
always @(posedge clk)
  if(prelen_en)
    pre_len <= data_out;      // copy from data_mem[61] to pre_len reg.
  else if(taps_en)
    taps    <= data_out;      // copy from data_mem[62] to taps reg.
  else if(start_en)
    start   <= data_out;      // copy from data_mem[63] to start reg.

/* My done flag goes high once every 64 clock cycles
   Yours should go high at the completion of your encryption operation.
   This may be more or fewer clock cycles than mine. 
   Test bench waits for a done flag, so generate one at some time.
*/
assign done = ct == 71;

endmodule