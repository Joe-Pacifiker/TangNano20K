// Joseph Mitchell
// 1) Restructured Verilog HDL code
// 2) Draw the FSM on paper
// 3) Make changes to FSM and evaluate FPGA response


module top (
	input 		clk,  // input clock source

	output reg WS2812 // output to the interface of WS2812
);

parameter WS2812_NUM 	= 0             ; // LED number of WS2812 (starts from 0)
parameter WS2812_WIDTH 	= 24            ; // WS2812 data bit width
parameter CLK_FRE 	 	= 27_000_000    ; // CLK frequency (mHZ)

parameter DELAY_1_HIGH 	= (CLK_FRE / 1_000_000 * 0.85 )  - 1; //≈850ns±150ns     1 high level time
parameter DELAY_1_LOW 	= (CLK_FRE / 1_000_000 * 0.40 )  - 1; //≈400ns±150ns 	 1 low level time
parameter DELAY_0_HIGH 	= (CLK_FRE / 1_000_000 * 0.40 )  - 1; //≈400ns±150ns 	 0 high level time
parameter DELAY_0_LOW 	= (CLK_FRE / 1_000_000 * 0.85 )  - 1; //≈850ns±150ns     0 low level time
parameter DELAY_RESET 	= (CLK_FRE / 10 ) - 1; //0.1s reset time ＞50us

parameter RESET 	 	= 0; //state machine statement
parameter DATA_SEND  		= 1;
parameter BIT_SEND_HIGH   	= 2;
parameter BIT_SEND_LOW   	= 3;

parameter INIT_DATA = 24'b1111; // initial pattern

reg [ 1:0] state       = 0; // synthesis preserve  - main state machine control
reg [ 8:0] bit_send    = 0; // number of bits sent - increase for larger led strips/matrix
reg [ 8:0] data_send   = 0; // number of data sent - increase for larger led strips/matrix
reg [31:0] clk_count   = 0; // delay control
reg [23:0] WS2812_data = 0; // WS2812 color data

always@(posedge clk)
begin
 case (state)
  RESET:
  begin
   WS2812 <= 0;
   if (clk_count < DELAY_RESET) 
   begin
    clk_count <= clk_count + 1;
   end
   else 
   begin
    clk_count <= 0;
    if (WS2812_data == 0)
    begin
     WS2812_data <= INIT_DATA;
    end
    else
    begin
     WS2812_data <= {WS2812_data[22:0],WS2812_data[23]}; //color shift cycle display
     state <= DATA_SEND;
    end
   end
  end

  DATA_SEND:
  begin
   if (data_send > WS2812_NUM && bit_send == WS2812_WIDTH)
   begin 
    clk_count <= 0;
    data_send <= 0;
    bit_send  <= 0;
    state <= RESET;
   end 
   else if (bit_send < WS2812_WIDTH) 
   begin
    state    <= BIT_SEND_HIGH;
   end
   else 
   begin
    data_send <= data_send + 1;
    bit_send  <= 0;
    state    <= BIT_SEND_HIGH;
   end
  end		
	
  BIT_SEND_HIGH:
  begin
   WS2812 <= 1;
   if (WS2812_data[bit_send])
   begin 
    if (clk_count < DELAY_1_HIGH)
    begin
     clk_count <= clk_count + 1;
    end
    else 
    begin
     clk_count <= 0;
     state    <= BIT_SEND_LOW;
    end
   end
   else
   begin 
    if (clk_count < DELAY_0_HIGH)
    begin
     clk_count <= clk_count + 1;
    end
    else 
    begin
     clk_count <= 0;
     state    <= BIT_SEND_LOW;
    end
   end
  end
 

  BIT_SEND_LOW:
  begin
   WS2812 <= 0;
   if (WS2812_data[bit_send])
   begin 
    if (clk_count < DELAY_1_LOW)
    begin 
     clk_count <= clk_count + 1;
    end
    else 
    begin
     clk_count <= 0;
     bit_send <= bit_send + 1;
     state    <= DATA_SEND;
    end
   end
   else
   begin 
    if (clk_count < DELAY_0_LOW)
    begin 
     clk_count <= clk_count + 1;
    end
    else 
    begin
     clk_count <= 0;			
     bit_send <= bit_send + 1;
     state    <= DATA_SEND;
    end
   end
  end
  
 endcase
end

endmodule