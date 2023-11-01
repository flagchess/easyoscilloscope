`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module adda_test(
		input crystal_clk,    //crystal clock
		input key4,						//SFRE:change DAC frequence
		input key3,       			//
		input key2,						//
		input key1,						//rst
		
		input [7:0] addata_in,    //ADC data
		
		output [7:0] dadata,  //DAC data
		output  daclk,				//DAC clock
		output adclk,					//ADC clock
		output LED0,				//PLL LOCKED，LED为低电平有效
		output LED1,					//fifo full，LED为低电平有效
		output LED2,					//WEN，LED为低电平有效
		output LED3,					//REN，LED为低电平有效
		output status_test
    );

////寄存器定义
reg [8:0] rom_addr;

reg [8:0] rom_sin_addr;
reg [8:0] rom_squar_addr;
reg [8:0] rom_triang_addr;

reg [23:0] accumulator;
reg [7:0] ad_data;
reg [2:0] cnt;
reg [19:0] count;
reg key_scan4; //按键扫描值KEY4
reg key_scan3; //按键扫描值KEY3
reg key_scan2; //按键扫描值KEY2
reg key_scan1; //按键扫描值KEY1
reg key_scan_dly4;
reg key_scan_dly3;
reg key_scan_dly2;
reg key_scan_dly1;
reg flag_key4;
reg flag_key3;
reg flag_key2;
reg flag_key1;
reg fifo_rst;

wire wr_en;
wire rd_en;

reg [23:0]step;
(*KEEP = "TRUE" *)

wire [7:0] fifo_out;
reg [7:0] rom_data;

wire [7:0] rom_sin_data;
wire [7:0] rom_squar_data;
wire [7:0] rom_triang_data;

reg [7:0] dadata;
//(*KEEP = "TRUE" *)
wire clk_25;
wire clk_50;
wire clk_40;
wire clk_30;
wire clk_20;
wire clk_10;

reg LED1;
reg LED2;
reg LED3;

wire	fifo_wr_en;
wire	fifo_rd_en;

//////时钟产生模块//////////////////////////
//////由外部晶振50MHz产生出两路内部工作时钟，50MHz和25MHz，分别用于DAC和ADC的工作时钟
///需要添加PLL模块，接口定义如下
PLL PLL_inst
   (// Clock in ports
    .CLK_IN1(crystal_clk),      // IN
    // Clock out ports
    .CLK_OUT1(daclk),     // OUT 50MHz
    .CLK_OUT2(clk_25),     // OUT 25MHz
    // Status and control signals
    .RESET(0),// IN
    .LOCKED(LOCKED));      // OUTA

///输出PLL的锁定标志至LED0
assign LED0 = LOCKED;
//assign daclk=clk_50;
assign adclk=clk_25;

////////////按键消抖检测模块////////////////////////
//===========================================================================
// 采样按键值，20ms扫描一次,采样频率小于按键毛刺频率，相当于滤除掉了高频毛刺信号。
//===========================================================================
always @(posedge adclk)     //检测时钟的上升沿
begin
	 if(count ==20'd499_999)   //20ms扫描一次按键,20ms计数(25M/50-1=499_999)
			begin
				count <= 20'b0;      //计数器计到20ms，计数器清零
				key_scan4 <= key4;   //频率修改按键
				key_scan3 <= key3;   //读使能按键
				key_scan2 <= key2;   //写使能按键
				key_scan1 <= key1;   //FIFO复位按键
			end
	 else
			count <= count + 20'b1; //计数器加1
end

always @(posedge adclk)
    begin
		key_scan_dly4 <= key_scan4;  
		key_scan_dly3 <= key_scan3;	
		key_scan_dly2 <= key_scan2;
		key_scan_dly1 <= key_scan1;
		//当检测到按键有下降沿变化时，代表该按键被按下，按键有效
		flag_key4 <= key_scan_dly4 & (~key_scan4);  
		flag_key3 <= key_scan_dly3 & (~key_scan3);
		flag_key2 <= key_scan_dly2 & (~key_scan2);
		flag_key1 <= key_scan_dly1 & (~key_scan1);
	 end

////信号产生模块/////////////////////////
////设置5种读取ROM的步进，调节输出信号频率，输出频率Fo=(50M/512)*step Hz
always @(posedge adclk)  
begin
	if(flag_key4)
	begin
//		if(cnt==4)
//			cnt<=0;
//		else
			cnt<=cnt+3'b1;	
	end
end

always@(posedge adclk)
begin
	case(cnt)
			3'd0:  step <= 336; 		//1 kHz
			3'd1:  step <= 6710;	   //33 kHz
			3'd2:  step <= 10066;   //333 kHz
			3'd3:  step <= 13421;   //666 kHz
			3'd4:  step <= 16777;  //1100 kHz
			3'd5:  step <= 33554;  //3300 kHz
			3'd6:  step <= 100663; //6600 kHz
			3'd7:  step <= 167772; //10000 kHz
		default:  step <= 336;
	endcase
end

//DA output sin waveform
always @(posedge daclk)
begin
     accumulator[23:0] <= accumulator[23:0] + step ; 
end 


always @(posedge daclk)
begin
     rom_addr[8:0] <= accumulator[23:15] ; 
end 

always @(posedge daclk)
begin
     rom_sin_addr[8:0] <= rom_addr[8:0]; 
	  rom_squar_addr[8:0] <= rom_addr[8:0]; 
	  rom_triang_addr[8:0] <= rom_addr[8:0]; 
end 

ROM_WAVE ROM_inst (	//sin
  .clka(daclk), // input clka
  .addra(rom_sin_addr), // input [8 : 0] addra
  
  .douta(rom_sin_data) // output rom_data [7 : 0] douta 
);


ROM_square ROM_square_inst (	//sin
  .clka(daclk), // input clka
  .addra(rom_squar_addr), // input [8 : 0] addra
  
  .douta(rom_squar_data) // output rom_data [7 : 0] douta 
);

ROM_TRIANG ROM_TRIANG_inst (	//sin
  .clka(daclk), // input clka
  .addra(rom_triang_addr), // input [8 : 0] addra
  
  .douta(rom_triang_data) // output rom_data [7 : 0] douta 
);

reg	[1:0]	which_wave_cnt;

always @(posedge adclk)//切换DDS输出波形
begin
	if(flag_key2&flag_key3)//同时按下按键2和按键3，切换波形
		which_wave_cnt <= which_wave_cnt +1;
end

always @(posedge daclk)
begin
	case (which_wave_cnt)
		2'b00:
			rom_data <= rom_sin_data ; //选择正弦波形输出
		2'b01:
			rom_data <= rom_squar_data ; //选择方波形输出
		2'b10:
			rom_data <= rom_triang_data ; //选择三角波形输出
		default: rom_data <= rom_sin_data ;    
   endcase
end 

always @(posedge daclk)
begin
     dadata <= rom_data ; 
end 
//assign dadata=rom_data;

////////// 信号产生模块结束 /////////////

/////信号采样存储模块/////////////////////
///ADC数据接收与存储模块////////////////////////
//
always @(posedge adclk)
begin
      ad_data <= addata_in;  
		
end

/////FIFO复位
always @(posedge adclk)  
begin
	if(flag_key1)
		fifo_rst <=1;////有按键按下，则产生一次FIFO的复位信号
	else
		fifo_rst <=0;///
end



//adfifo
adc_fifo ad_fifo_inst (
  .clk(adclk), // input clk
  .rst(fifo_rst), // input rst
  .din(ad_data), // input [7 : 0] din
  .wr_en(fifo_wr_en), // input wr_en
  .rd_en(fifo_rd_en), // input rd_en
  
  .dout(fifo_out), // output [7 : 0] dout
  .full(fifo_full), // output full
  .empty(fifo_empty) // output empty
);

/***********   按键寄存器设置 ***************/ 
reg	[2:0]	trig_hysteresis;
always @(posedge adclk)  
begin
	  trig_hysteresis <=4;////设置迟滞电压
end

reg	[6:0]	trig_level_inc;
always @(posedge adclk)  
begin
	  trig_level_inc <=4;////设置比较电平增量电压
end

//////////////  触发功能代码  ///////////////

/***************比较整形模块，产生触发脉冲（信号同步脉冲）信号****************/
reg	[7:0]	ad_data_trig;
reg			digital_trigged_sig;

reg 	[7:0] trig_level;

always @(posedge adclk)
begin
	trig_level <= 120 + trig_level_inc;   //形成触发电平
end

always @(posedge adclk)
begin
	ad_data_trig <= ad_data;
end

always @(posedge adclk)//比较产生同步脉冲
begin
	if(trig_en&(ad_data_trig>=trig_level) )
		digital_trigged_sig <= 1;
	if(trig_en&(ad_data_trig<trig_level-trig_hysteresis) ) //设置触发迟滞电压trig_hysteresis
		digital_trigged_sig <= 0;
end

/***************比较整形模块end****************/

reg trig_en;
always @(posedge adclk)  
begin
	if(flag_key1)
		trig_en <=~trig_en;////设置触发使能信号

end
///********************************************
reg	[3:0]		extract_cnt;
reg	[15:0]	extract_num;

always @(posedge daclk)  
begin
	begin
	if(flag_key2)
		if(extract_cnt==6)
			extract_cnt<=0;
		else
			extract_cnt<=extract_cnt+3'b1;		
	end
end

always@(posedge daclk)
begin
  case(extract_cnt)
   0:extract_num<=0;	 	//不抽点
   1:extract_num<=1; 	//2抽1
   2:extract_num<=4; 	//5抽1
	3:extract_num<=9; 	//10抽1
	4:extract_num<=19;	//20抽1
   5:extract_num<=49;	//50抽1
   6:extract_num<=99;	//100抽1
   default:extract_num<=0;
	endcase
end




///********************************************


//触发模块
trig trig_ins (
  .clk(adclk),
  .empty(fifo_empty),
  .full(fifo_full),
  .datain(ad_data),
  .digital_trigged_sig(digital_trigged_sig),
  .extract_num(extract_num),
  
  .fifo_wr_en(fifo_wr_en),
  .fifo_rd_en(fifo_rd_en)
  );







always @(posedge adclk)  
begin
	LED1 <= fifo_full;  	//输出FIFO的满标志至LED2
	LED2 <= digital_trigged_sig;			//输出FIFO的写使能至LED3
	LED3 <= trig_en;			//输出FIFO的读使能至LED4
end


/// 仅仅测试用
reg status_test;
always @(posedge adclk)  
begin
	if(fifo_out>127)
		status_test <= fifo_empty;  	//防止部分网络被优化删除
	else
		status_test <= ~fifo_empty; 

end

////////////////////////////


endmodule
