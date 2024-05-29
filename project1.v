module DSP48A1 (A,B,D,C,clk,CARRYIN,OPMODE,BCIN,PCIN,
RSTA,RSTB,RSTM,RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,
CEA,CEB,CEM,CEP,CEC,CED,CECARRYIN,CEOPMODE,
BCOUT,PCOUT,P,M,CARRYOUT,CARRYOUTF);

//handle parameter in design
parameter  A0REG = 0, A1REG = 1,B0REG = 0, B1REG = 1 ;
parameter CREG = 1, DREG = 1, MREG = 1, PREG = 1, CARRYINREG = 1, CARRYOUTREG = 1, OPMODEREG = 1;
parameter CARRYINSEL = "OPMODE5" ;
parameter B_INPUT  = "DIRECT";
parameter RSTTYPE = "SYNC";
parameter NumberofDSPs=1; //default value equal to 1 as we have one dsp only
//handle input ports 

input [17:0] A, B, D, BCIN; 
input [47 : 0] PCIN, C;
input [7:0] OPMODE; 
input clk,CARRYIN; 
// handle input reset ports

input RSTA,RSTB,RSTM,RSTP,RSTC,RSTD,RSTCARRYIN,RSTOPMODE;

// handle clock enable input ports

input CEA,CEB,CEM,CEP,CEC,CED,CECARRYIN,CEOPMODE;

//handle output ports 

output [17 : 0 ]BCOUT;
output [47 : 0]PCOUT,P;
output [35 : 0]M;
output  reg CARRYOUT,CARRYOUTF ;

//handle clock enable 
wire clock_en_A,clock_en_B,clock_en_C,clock_en_CARRYIN,clock_en_D,clock_en_M,clock_en_OPMODE,clock_en_P;
assign clock_en_A = CEA & clk ;
assign clock_en_B = CEB & clk ;
assign clock_en_C = CEC & clk ;
assign clock_en_CARRYIN = CECARRYIN & clk ;
assign clock_en_D = CED & clk ;
assign clock_en_M = CEM & clk ;
assign clock_en_OPMODE = CEOPMODE & clk ;
assign clock_en_P = CEP & clk ;


//design 

// handle opmode register 

wire [7:0] OPMODE_reg;
REG #(8) OPMODEreg (clock_en_OPMODE, RSTOPMODE, OPMODE, OPMODE_reg);

wire [17:0] D_reg;
REG #(18) Dreg (clock_en_D, RSTD, D, D_reg);
// mux_D_reg_out
wire  [17:0] mux_D_reg_out ;
assign mux_D_reg_out = (DREG) ? D_reg : D;  

//mux_B/BCIN
wire [17:0] mux_B_BCIN_out;


                                                
   generate
if (B_INPUT == "DIRECT") begin
            assign mux_B_BCIN_out = B;
        end
        else if (B_INPUT == "CASCADE") begin
            assign mux_B_BCIN_out = BCIN;
        end
        else begin
            assign mux_B_BCIN_out = 0;
        end
    endgenerate

wire [17:0] B0_reg;
REG #(18,RSTTYPE ) Breg0 (clock_en_B, RSTB, mux_B_BCIN_out, B0_reg);

// mux_B0_reg_out
wire  [17:0] mux_B0_reg_out ;
assign mux_B0_reg_out = (B0REG) ? B0_reg : mux_B_BCIN_out ;

// mux_3
wire [17:0] A0_reg;
REG #(18,RSTTYPE) A0reg (clock_en_A, RSTA, A, A0_reg);
wire  [17:0] mux_A0_reg_out ;
assign mux_A0_reg_out = (A0REG) ? A0_reg : A;

// mux_4
wire [47:0] C_reg;
REG #(48,RSTTYPE) Creg (clock_en_C, RSTC, C, C_reg);
wire  [47:0] mux_C_reg_out ;
assign mux_C_reg_out = (CREG) ? C_reg : C ;



// handle pre-adder/subtracter_mux
wire [17:0] mux_preadder_or_subtracter_out;
assign mux_preadder_or_subtracter_out = (OPMODE_reg[6]==0) ? (mux_D_reg_out+mux_B0_reg_out): (mux_D_reg_out-mux_B0_reg_out) ;

// mux_5
wire [17:0] mux_pradder_or_sub_out ;
assign mux_pradder_or_sub_out = (OPMODE_reg[4]==0) ? mux_preadder_or_subtracter_out: mux_B0_reg_out ;


// handle B1REG resister
// mux_B1_reg
wire [17:0] B1_reg;
REG #(18,RSTTYPE) B1reg (clock_en_B, RSTB, mux_pradder_or_sub_out, B1_reg);
wire  [17:0] mux_B1_reg_out ;
assign mux_B1_reg_out = (B1REG) ? B1_reg : mux_pradder_or_sub_out ;
assign BCOUT=mux_B1_reg_out;

// mux_A1_reg
wire [17:0] A1_reg;
REG #(18,RSTTYPE) A1reg (clock_en_A, RSTA, mux_A0_reg_out, A1_reg);
wire  [17:0] mux_A1_reg_out ;
assign mux_A1_reg_out = (A1REG) ? A1_reg : mux_A0_reg_out ;

// handle multiplier register
wire  [35:0] multiplier ;
assign multiplier = mux_B1_reg_out * mux_A1_reg_out ;
wire [35:0] M_reg;
REG #(36,RSTTYPE) Mreg (clock_en_M, RSTM,multiplier, M_reg);
wire  [35:0] M_out ;
assign M_out = (MREG) ? M_reg : multiplier;
assign M = M_out;

 

// handle carry cascade input

wire carryin_cascade_mux_out;
 generate
if (CARRYINSEL == "OPMODE5") begin
            assign carryin_cascade_mux_out = OPMODE_reg[5];
        end
        else if (CARRYINSEL == "CARRYIN") begin
            assign carryin_cascade_mux_out = CARRYIN;
        end
        else begin
            assign carryin_cascade_mux_out = 0;
        end
    endgenerate

wire  CYI_reg;
REG #(1,RSTTYPE) CYIreg (clock_en_CARRYIN, RSTCARRYIN,carryin_cascade_mux_out , CYI_reg);
wire CIN ;
assign CIN = (CARRYINREG) ? CYI_reg : carryin_cascade_mux_out ;
wire  [48:0] mux_postadder_or_sub_out ;
wire  [47:0] mux_P_reg_input ;
wire  [47:0] mux_P_reg_out ;
wire Cout ;


// handle mux_x

wire [47:0] mux_x_out ;
assign mux_x_out = (OPMODE_reg[1:0]==2'b00) ? {mux_D_reg_out[11:0], mux_A1_reg_out[17:0],mux_B1_reg_out[17:0]}:
                   (OPMODE_reg[1:0]==2'b01) ?  mux_P_reg_out                                       :         
                   (OPMODE_reg[1:0]==2'b10) ?  M_out                                            :
                                            0                                               ;


// handle mux_Z

wire [47:0] mux_z_out;
assign mux_z_out = (OPMODE_reg[3:2]==2'b00) ?   mux_C_reg_out               :
                   (OPMODE_reg[3:2]==2'b01) ?   mux_P_reg_out               :        
                   (OPMODE_reg[3:2]==2'b10) ?   PCIN                    :
                                             0                      ;



//handle mux_8


assign mux_postadder_or_sub_out = (OPMODE_reg[7]==0) ? (mux_z_out+mux_x_out+CIN) : (mux_z_out-(mux_x_out+CIN)) ;
assign {Cout,mux_P_reg_input} = mux_postadder_or_sub_out ; 

// handle carryout register 

wire  CYO_reg;
REG #(1,RSTTYPE) CYOreg (clock_en_CARRYIN, RSTCARRYIN, Cout ,CYO_reg);




generate
    always @(*) begin
   if(NumberofDSPs!=1)begin
       CARRYOUT=CIN;
   end
   else if (CARRYOUTREG == 1) begin
             CARRYOUT = CYO_reg;
        end
   else if (CARRYOUTREG == 0) begin
             CARRYOUT = Cout;
        end
    end
endgenerate
always @(*) begin
   CARRYOUTF  = CARRYOUT ;
   
end
                                                                   
 




//  handle mux_9
wire  [47:0] P_reg ;
REG #(48,RSTTYPE) Preg (clock_en_P, RSTP,mux_P_reg_input,P_reg);


assign mux_P_reg_out = (PREG) ? P_reg : mux_P_reg_input ;
assign  P = mux_P_reg_out  ;
assign PCOUT=mux_P_reg_out;
endmodule