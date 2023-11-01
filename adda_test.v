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
		output LED0,				//PLL LOCKED��LEDΪ�͵�ƽ��Ч
		output LED1,					//fifo full��LEDΪ�͵�ƽ��Ч
		output LED2,					//WEN��LEDΪ�͵�ƽ��Ч
		output LED3,					//REN��LEDΪ�͵�ƽ��Ч
		output status_test
    );

////�Ĵ�������
reg [8:0] rom_addr;

reg [8:0] rom_sin_addr;
reg [8:0] rom_squar_addr;
reg [8:0] rom_triang_addr;

reg [23:0] accumulator;
reg [7:0] ad_data;
reg [2:0] cnt;
reg [19:0] count;
reg key_scan4; //����ɨ��ֵKEY4
reg key_scan3; //����ɨ��ֵKEY3
reg key_scan2; //����ɨ��ֵKEY2
reg key_scan1; //����ɨ��ֵKEY1
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

//////ʱ�Ӳ���ģ��//////////////////////////
//////���ⲿ����50MHz��������·�ڲ�����ʱ�ӣ�50MHz��25MHz���ֱ�����DAC��ADC�Ĺ���ʱ��
///��Ҫ���PLLģ�飬�ӿڶ�������
PLL PLL_inst
   (// Clock in ports
    .CLK_IN1(crystal_clk),      // IN
    // Clock out ports
    .CLK_OUT1(daclk),     // OUT 50MHz
    .CLK_OUT2(clk_25),     // OUT 25MHz
    // Status and control signals
    .RESET(0),// IN
    .LOCKED(LOCKED));      // OUTA

///���PLL��������־��LED0
assign LED0 = LOCKED;
//assign daclk=clk_50;
assign adclk=clk_25;

////////////�����������ģ��////////////////////////
//===========================================================================
// ��������ֵ��20msɨ��һ��,����Ƶ��С�ڰ���ë��Ƶ�ʣ��൱���˳����˸�Ƶë���źš�
//===========================================================================
always @(posedge adclk)     //���ʱ�ӵ�������
begin
	 if(count ==20'd499_999)   //20msɨ��һ�ΰ���,20ms����(25M/50-1=499_999)
			begin
				count <= 20'b0;      //�������Ƶ�20ms������������
				key_scan4 <= key4;   //Ƶ���޸İ���
				key_scan3 <= key3;   //��ʹ�ܰ���
				key_scan2 <= key2;   //дʹ�ܰ���
				key_scan1 <= key1;   //FIFO��λ����
			end
	 else
			count <= count + 20'b1; //��������1
end

always @(posedge adclk)
    begin
		key_scan_dly4 <= key_scan4;  
		key_scan_dly3 <= key_scan3;	
		key_scan_dly2 <= key_scan2;
		key_scan_dly1 <= key_scan1;
		//����⵽�������½��ر仯ʱ������ð��������£�������Ч
		flag_key4 <= key_scan_dly4 & (~key_scan4);  
		flag_key3 <= key_scan_dly3 & (~key_scan3);
		flag_key2 <= key_scan_dly2 & (~key_scan2);
		flag_key1 <= key_scan_dly1 & (~key_scan1);
	 end

////�źŲ���ģ��/////////////////////////
////����5�ֶ�ȡROM�Ĳ�������������ź�Ƶ�ʣ����Ƶ��Fo=(50M/512)*step Hz
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

always @(posedge adclk)//�л�DDS�������
begin
	if(flag_key2&flag_key3)//ͬʱ���°���2�Ͱ���3���л�����
		which_wave_cnt <= which_wave_cnt +1;
end

always @(posedge daclk)
begin
	case (which_wave_cnt)
		2'b00:
			rom_data <= rom_sin_data ; //ѡ�����Ҳ������
		2'b01:
			rom_data <= rom_squar_data ; //ѡ�񷽲������
		2'b10:
			rom_data <= rom_triang_data ; //ѡ�����ǲ������
		default: rom_data <= rom_sin_data ;    
   endcase
end 

always @(posedge daclk)
begin
     dadata <= rom_data ; 
end 
//assign dadata=rom_data;

////////// �źŲ���ģ����� /////////////

/////�źŲ����洢ģ��/////////////////////
///ADC���ݽ�����洢ģ��////////////////////////
//
always @(posedge adclk)
begin
      ad_data <= addata_in;  
		
end

/////FIFO��λ
always @(posedge adclk)  
begin
	if(flag_key1)
		fifo_rst <=1;////�а������£������һ��FIFO�ĸ�λ�ź�
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

/***********   �����Ĵ������� ***************/ 
reg	[2:0]	trig_hysteresis;
always @(posedge adclk)  
begin
	  trig_hysteresis <=4;////���ó��͵�ѹ
end

reg	[6:0]	trig_level_inc;
always @(posedge adclk)  
begin
	  trig_level_inc <=4;////���ñȽϵ�ƽ������ѹ
end

//////////////  �������ܴ���  ///////////////

/***************�Ƚ�����ģ�飬�����������壨�ź�ͬ�����壩�ź�****************/
reg	[7:0]	ad_data_trig;
reg			digital_trigged_sig;

reg 	[7:0] trig_level;

always @(posedge adclk)
begin
	trig_level <= 120 + trig_level_inc;   //�γɴ�����ƽ
end

always @(posedge adclk)
begin
	ad_data_trig <= ad_data;
end

always @(posedge adclk)//�Ƚϲ���ͬ������
begin
	if(trig_en&(ad_data_trig>=trig_level) )
		digital_trigged_sig <= 1;
	if(trig_en&(ad_data_trig<trig_level-trig_hysteresis) ) //���ô������͵�ѹtrig_hysteresis
		digital_trigged_sig <= 0;
end

/***************�Ƚ�����ģ��end****************/

reg trig_en;
always @(posedge adclk)  
begin
	if(flag_key1)
		trig_en <=~trig_en;////���ô���ʹ���ź�

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
   0:extract_num<=0;	 	//�����
   1:extract_num<=1; 	//2��1
   2:extract_num<=4; 	//5��1
	3:extract_num<=9; 	//10��1
	4:extract_num<=19;	//20��1
   5:extract_num<=49;	//50��1
   6:extract_num<=99;	//100��1
   default:extract_num<=0;
	endcase
end




///********************************************


//����ģ��
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
	LED1 <= fifo_full;  	//���FIFO������־��LED2
	LED2 <= digital_trigged_sig;			//���FIFO��дʹ����LED3
	LED3 <= trig_en;			//���FIFO�Ķ�ʹ����LED4
end


/// ����������
reg status_test;
always @(posedge adclk)  
begin
	if(fifo_out>127)
		status_test <= fifo_empty;  	//��ֹ�������类�Ż�ɾ��
	else
		status_test <= ~fifo_empty; 

end

////////////////////////////


endmodule
