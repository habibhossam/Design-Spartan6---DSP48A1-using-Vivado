module REG (clk, rst, d_input, q_output);
parameter REG_WIDTH = 1 ;
parameter RSTTYPE = "SYNC" ;
input clk , rst ;
input [REG_WIDTH-1: 0 ] d_input;
output reg  [REG_WIDTH-1: 0 ] q_output;   
wire  rst_aSYNC ;
reg  rst_SYNC ; 
 assign rst_aSYNC = rst ;
always @(*) begin
   rst_SYNC = rst ;  
end
generate 
if (RSTTYPE == "SYNC") begin
    always @( posedge clk ) begin
    if (rst_SYNC) begin
       q_output<= 0 ;    
    end  
    else begin
        q_output <= d_input ; 
    end
end    
end else if (RSTTYPE == "ASYNC")begin
    always @( posedge clk or posedge rst_aSYNC ) begin
    if (rst_aSYNC) begin
       q_output<= 0 ;    
    end  
    else begin
        q_output <= d_input ; 
    end
end    
end  
endgenerate
endmodule