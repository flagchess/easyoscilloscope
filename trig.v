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

/***************** ����Ԥ����*******************/
always @(posedge clk)
begin
	full_dly <= full;
	ready_dly <= ready;
	digital_trigged_dly<=digital_trigged;
	digital_trigged_sig_dly<=digital_trigged_sig ;//����ʹ��
	empty_dly <= empty;
	full_dly <= full;
end

/***************** ready�źŲ���*******************/
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
	else if(digital_trigged && !digital_trigged_dly) //digital_trigged�����أ�ready����
	  begin
	   ready <= 0;
	  end
end
	
/***************** Ԥ��������*******************/

always @(posedge clk )//����Ԥ�������
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
		if(pre_tri_cnt[10:0] ==  pre_tri_cnt_config)//����Ԥ������� 
		begin			
			cmp_result <= 1'b1;
		end
		else
		begin
			cmp_result <= 1'b0;			
		end			
	end
end	
/***************** �Զ���������*******************/
always @(posedge clk )//or negedge count_en)
begin
	if(empty && ~empty_dly)	//as clr
	begin
		auto_tri_cnt[15:0] <= 16'h00;
	end
	else if (ready)
	begin
		auto_tri_cnt[15:0] <= auto_tri_cnt[15:0] + 1;
		if(auto_tri_cnt[15:0] ==  10000)// ready ״̬����ʱ�䳬�� 40ns �� 10000 = 400us������2.5kHz���źŲ��ܴ���
		begin			
			auto_trig <= 1'b1;
		end
		else
		begin
			auto_trig <= 1'b0;			
		end			
	end
end	






/***************** ����״̬ *******************/
always @(posedge clk)
begin
	if((digital_trigged_sig && ~digital_trigged_sig_dly || auto_trig) && ready )//��⵽�����ź�������
	  digital_trigged <= 1;

	else if(full && !full_dly)  //fifo�����䲻���������ź�����
     digital_trigged <= 0;
end




/***************** ����fifo_rd *******************/

always @ (posedge clk)
begin
	if((empty && !empty_dly) || (digital_trigged && !digital_trigged_dly))//fifo��  ���� �����źŵ������رն�ʹ��
		fifo_rd <= 1'b0;
	else if((ready && ready_dly) || (full && ~full_dly))// ����ready״̬ ����fifo�����䲻������ʹ�ܿ���
		fifo_rd <= 1'b1;
end

/***************** ����fifo_wr*******************/
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
	
	/*********** �����һ������������FIFOдʹ�ܣ�fifo_wr_en����ʵ�ֳ�㹦��*******************/	

//��ʾ����������Χ0~	extract_num�� extract_num ֵ���ɰ�������
//��ʾ����������������Ϊ fifo_wr_cnt
// �����źţ�clk  extract_num  fifo_wr
// ����ź�: fifo_wr_en
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
/***************** ����fifo_rd_en******************/
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
