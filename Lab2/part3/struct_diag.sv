// CSE140L  
// see Structural Diagram in Lab2 assignment writeup
// fill in missing connections and parameters
module struct_diag #(parameter NS=60, NH=24, ND = 7, NM = 12)(
  input Reset,
        Timeset, 	  // manual buttons
        Alarmset,	  //	(five total)
		Minadv,
		Hrsadv,
  		Dayadv,
 		Monthadv,
  		Dateadv,
		Alarmon,
		Pulse,		  // assume 1/sec.
// 6 decimal digit display (7 segment)
  output [6:0] S1disp, S0disp, 	   // 2-digit seconds display
               M1disp, M0disp, 
               H1disp, H0disp,
               D0disp, 
  			   Month1disp, Month0disp,
  			   Date1disp, Date0disp,
  output logic Buzz);	           // alarm sounds
// internal connections (may need more)
  logic[6:0] TSec, TMin, THrs, TDays, TMonth, TDate,    // clock/time 
             AMin, AHrs;		   // alarm setting
  logic[6:0] Min, Hrs, AlarmTMin, AlarmAMin;
  logic [4:0] DateMod;
  logic Szero, Mzero, Hzero, Datezero,	   // "carry out" from sec -> min, min -> hrs, hrs -> days
        TMen, THen, TDen, TDateen, TMonthen, AMen, AHen;

  always_comb begin
    TMen = Szero | (Timeset & Minadv & !Alarmset);
    THen = (Mzero & Szero) | (Timeset & Hrsadv & !Alarmset);
    TDen = (Hzero & Mzero & Szero) | (Timeset & Dayadv & !Alarmset);
    TMonthen = (Datezero & Hzero & Mzero & Szero) | (Timeset & Monthadv & !Alarmset);
    TDateen = (Hzero & Mzero & Szero) | (Timeset & Dateadv & !Alarmset);
    
    AMen = Alarmset & Minadv & !Timeset;
    AHen = Alarmset & Hrsadv & !Timeset;
    
    Min = Alarmset ? AMin : TMin;
    Hrs = Alarmset ? AHrs : THrs;
    
    AlarmTMin = (Alarmon & TDays != 5 & TDays != 6) ? TMin : 7'd0;
    AlarmAMin = (Alarmon & TDays != 5 & TDays != 6) ? AMin : 7'd1;
    
    if(TMonth == 3 | TMonth == 5 | TMonth == 8 | TMonth == 10)
      DateMod = 5'd30;
    else if(TMonth == 1)
      DateMod = 5'd28;
    else
      DateMod = 5'd31;
  end
  
// free-running seconds counter	-- be sure to set parameters on ct_mod_N modules
  ct_mod_N #(.N(NS)) Sct(
// input ports
    .clk(Pulse), .rst(Reset), .en(!Timeset), 
// output ports    
    .ct_out(TSec), .z(Szero)
    );
// minutes counter -- runs at either 1/sec or 1/60sec
  ct_mod_N #(.N(NS)) Mct(
    .clk(Pulse), .rst(Reset), .en(TMen), .ct_out(TMin), .z(Mzero)
    );
// hours counter -- runs at either 1/sec or 1/60min
  ct_mod_N #(.N(NH)) Hct(
    .clk(Pulse), .rst(Reset), .en(THen), .ct_out(THrs), .z(Hzero)
    );
// days of week counter -- runs at either 1/sec or 1/60min
  ct_mod_N #(.N(ND)) Dct(
    .clk(Pulse), .rst(Reset), .en(TDen), .ct_out(TDays), .z()
    );
  // date counter
  ct_mod_D Datect(
    .clk(Pulse), .rst(Reset), .en(TDateen), .modulus(DateMod), .ct_out(TDate), .z(Datezero)
    );
  ct_mod_N #(.N(NM)) Monthct(
    .clk(Pulse), .rst(Reset), .en(TMonthen), .ct_out(TMonth), .z()
    );
// alarm set registers -- either hold or advance 1/sec
  ct_mod_N #(.N(NS)) Mreg(
// input ports
    .clk(Pulse), .rst(Reset), .en(AMen), 
// output ports    
    .ct_out(AMin), .z()
    ); 

  ct_mod_N #(.N(NH)) Hreg(
    .clk(Pulse), .rst(Reset), .en(AHen), .ct_out(AHrs), .z()
    ); 

// display drivers (2 digits each, 6 digits total)
  lcd_int Sdisp(
    .bin_in    (TSec)  ,
	.Segment1  (S1disp),
	.Segment0  (S0disp)
	);

  lcd_int Mdisp(
    .bin_in    (Min),
    .Segment1  (M1disp),
    .Segment0  (M0disp)
	);

  lcd_int Hdisp(
    .bin_in    (Hrs),
    .Segment1  (H1disp),
    .Segment0  (H0disp)
	);
  
  lcd_int Ddisp(
    .bin_in    (TDays),
    .Segment1  (),
    .Segment0  (D0disp)
	);
  
  lcd_int Datedisp(
    .bin_in    (TDate + 7'd1),
    .Segment1  (Date1disp),
    .Segment0  (Date0disp)
	);
  
  lcd_int Modisp(
    .bin_in    (TMonth + 7'd1),
    .Segment1  (Month1disp),
    .Segment0  (Month0disp)
	);

// buzz off :)	  make the connections
  alarm a1(
    .tmin(AlarmTMin), .amin(AlarmAMin), .thrs(THrs), .ahrs(AHrs), .buzz(Buzz)
	);

endmodule