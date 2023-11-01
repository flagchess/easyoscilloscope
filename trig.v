module trig(
input [7:0] datain,
input clk,
input rst,
input empty,
input full,
input	digital_trigged_sig,
input	[15:0] extract_num,

output reg fifo_rd_en,
output reg fifo_wr_en
    );
	 
reg [10:0] pre_tri_cnt;
reg [10:0] pre_tri_cnt_config;

reg	fifo_rd;
reg	fifo_wr;

reg cmp_result;
reg ready;
reg ready_dly;
reg digital_trigged;
reg digital_trigged_dly;
reg full_dly;
reg digital_trigged_sig_dly;
//reg digital_trigged_sig;
reg [15:0]auto_tri_cnt;
reg auto_trig;
reg empty_dly;

/***************** 数据预处理*******************/
always @(posedge clk)
begin
	full_dly <= full;
	ready_dly <= ready;
	digital_trigged_dly<=digital_trigged;
	digital_trigged_sig_dly<=digital_trigged_sig ;//触发使能
	empty_dly <= empty;
	full_dly <= full;
end

/***************** ready信号产生*******************/
always @(posedge clk )//or negedge count_en)
begin
	if(empty && ~empty_dly)	
	  begin
		ready <= 0;
	  end
	else if (cmp_result)
	  begin
	   ready <= 1;
	  end	
	else if(digital_trigged && !digital_trigged_dly) //digital_trigged上升沿，ready拉低
	  begin
	   ready <= 0;
	  end
end
	
/***************** 预触发计数*******************/

always @(posedge clk )//设置预触发深度
begin
	pre_tri_cnt_config <= 500;
end

always @(posedge clk )//or negedge count_en)
begin
	if(empty && ~empty_dly)	//as clr
	begin
		pre_tri_cnt[10:0] <= 11'h00;
	end
	else if (fifo_wr && !digital_trigged && !ready)
	begin
		pre_tri_cnt[10:0] <= pre_tri_cnt[10:0] + 1;
		if(pre_tri_cnt[10:0] ==  pre_tri_cnt_config)//到达预触发深度 
		begin			
			cmp_result <= 1'b1;
		end
		else
		begin
			cmp_result <= 1'b0;			
		end			
	end
end	
/***************** 自动触发计数*******************/
always @(posedge clk )//or negedge count_en)
begin
	if(empty && ~empty_dly)	//as clr
	begin
		auto_tri_cnt[15:0] <= 16'h00;
	end
	else if (ready)
	begin
		auto_tri_cnt[15:0] <= auto_tri_cnt[15:0] + 1;
		if(auto_tri_cnt[15:0] ==  10000)// ready 状态持续时间超过 40ns × 10000 = 400us，低于2.5kHz的信号不能触发
		begin			
			auto_trig <= 1'b1;
		end
		else
		begin
			auto_trig <= 1'b0;			
		end			
	end
end	






/***************** 触发状态 *******************/
always @(posedge clk)
begin
	if((digital_trigged_sig && ~digital_trigged_sig_dly || auto_trig) && ready )//检测到触发信号上升沿
	  digital_trigged <= 1;

	else if(full && !full_dly)  //fifo由满变不满，触发信号清零
     digital_trigged <= 0;
end




/***************** 产生fifo_rd *******************/

always @ (posedge clk)
begin
	if((empty && !empty_dly) || (digital_trigged && !digital_trigged_dly))//fifo空  或者 触发信号到来，关闭读使能
		fifo_rd <= 1'b0;
	else if((ready && ready_dly) || (full && ~full_dly))// 进入ready状态 或者fifo由满变不满，读使能开启
		fifo_rd <= 1'b1;
end

/***************** 产生fifo_wr*******************/
always @ (posedge clk)
begin	
   if(empty && !empty_dly)
	begin
		fifo_wr <= 1'b1;
	end
	else if(full && !full_dly)
	begin
	   fifo_wr <= 1'b0;
	end
end
	
	/*********** 请设计一个计数器产生FIFO写使能：fifo_wr_en，以实现抽点功能*******************/	

//提示：计数器范围0~	extract_num， extract_num 值可由按键更改
//提示：计数器变量命名为 fifo_wr_cnt
// 输入信号：clk  extract_num  fifo_wr
// 输出信号: fifo_wr_en
(* keep="true" *)reg	[15:0]	fifo_wr_cnt/*syn_keep=true*/;

always @ (posedge clk)
begin	
	if(fifo_wr==1)
		begin
			if(fifo_wr_cnt == extract_num)
				begin
					fifo_wr_cnt <= 16'h00;
				end
			else
				begin
					fifo_wr_cnt <= fifo_wr_cnt + 1;
				end
		end
	else
		begin
			fifo_wr_cnt <= 16'h00;
		end
end

always @ (posedge clk)
begin	
	if( fifo_wr  &&  (fifo_wr_cnt == extract_num))
		begin
			fifo_wr_en <= 1;
		end
	
	else
		begin
			fifo_wr_en <= 0;
		end
	
	
end


//////////////////////////////////////////////////////////////////////////////////////
/***************** 抽点后fifo_rd_en******************/
(* keep="true" *)reg full_flag_reg/*syn_keep=true*/;
always@(posedge clk)	
begin
if(empty && !empty_dly)
	full_flag_reg<=0;
else if(full && !full_dly)		
	full_flag_reg<=1;
end

always@(posedge clk)	
begin
if(full_flag_reg==0)
	begin
		if(fifo_rd)
		fifo_rd_en<=fifo_wr_en;
		else
		fifo_rd_en<=0;
		end
else
		fifo_rd_en<=fifo_rd;
end
//////////////////////////////////////////////////////
	
	
endmodule
