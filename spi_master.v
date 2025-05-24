module spi_master #(
	parameter DATA_WIDTH = 8,
	parameter FIFO_DEPTH = 16,
	parameter ADDR_WIDTH = 4
)(

   input wire clk,  //系統時脈
	input wire rst_n,  //非同步Reset(低有效)
	
	//控制訊號
	input wire start,  //開始傳輸
	output reg busy,  //傳輸進行中標誌
	
	// SPI實體介面
	output reg sclk,  //SPI時脈輸出
	output reg mosi,  //主送從收
	output reg cs_n,   //從機選擇(低有效)	
	
	
	// SPI模式選擇
	input wire cpol,
	input wire cpha,
	
	// FIFO寫入
	input wire fifo_wr_en,
	input wire [DATA_WIDTH-1:0] fifo_wr_data,
	output wire fifo_empty,
	output wire fifo_full
);

   //狀態定義
	reg [2:0] state, next_state;
	localparam IDLE = 3'd0;
	localparam LOAD = 3'd1;
	localparam TRANS = 3'd2;
	localparam DONE = 3'd3;
   
	//其他暫存變數
	reg [2:0] bit_cnt;
	reg [DATA_WIDTH-1:0] shift_reg;
	reg fifo_rd_en;
	wire [DATA_WIDTH-1:0] fifo_rd_data;
	
	// SCLK控制
	reg sclk_internal;
	
	// FIFO實例
	tx_fifo #(
		.DATA_WIDTH(DATA_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	) tx_fifo_inst (
		.clk(clk),
		.rst_n(rst_n),
		.write_en(fifo_wr_en),
		.write_data(fifo_wr_data),
		.read_en(fifo_rd_en),
		.read_data(fifo_rd_data),
		.empty(fifo_empty),
		.full(fifo_full)
	);
	
	//FSM狀態轉移
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end
	
	always @(*) begin
		case (state)
			IDLE: next_state = (!fifo_empty && start)? LOAD : IDLE;
			LOAD: next_state = TRANS;
			TRANS: next_state = (bit_cnt == 7)? DONE : TRANS;
			DONE: next_state = (!fifo_empty)? LOAD: IDLE;
			default: next_state = IDLE;
		endcase
	end

	// FSM動作
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			cs_n <= 1'b1;
			sclk_internal <= 1'b0;
			sclk <= 1'b0;
			bit_cnt <= 3'd0;
			mosi <= 1'b0;
			shift_reg <= 8'd0;
			fifo_rd_en <= 1'b0;
			busy <= 1'b0;
		end else begin
			fifo_rd_en <= 1'b0;
			
			case (state)
				IDLE: begin
					busy <= 1'b0;
					cs_n <= 1'b1;
					sclk_internal <= cpol;  //根據CPOL設定SCLK初始值
					sclk <= cpol;
				end
				
				LOAD: begin
					fifo_rd_en <= 1'b1;
					shift_reg <= fifo_rd_data;
					bit_cnt <= 3'd0;
					cs_n <= 1'b0;
					busy <= 1'b1;
				end
				
				TRANS: begin
					//CPHA = 0: 先輸出再變 SCLK
					//CPHA = 1: 先變SCLK再輸出
					if (cpha == 0) begin
						mosi <= shift_reg[7];
						sclk_internal <= ~sclk_internal;
						sclk <= sclk_internal;
						
						if (sclk_internal == ~cpol) begin
							shift_reg <= {shift_reg[6:0], 1'b0};
							bit_cnt <= bit_cnt + 1;
						end
					end else begin
						sclk_internal <= ~sclk_internal;
						sclk <= sclk_internal;
						
						if (sclk_internal == cpol) begin
							mosi <= shift_reg[7];
							shift_reg <= {shift_reg[6:0],1'b0};
							bit_cnt <= bit_cnt + 1;
						end
					end
				end
				
				DONE: begin
					cs_n <= 1'b1;
					busy <= 1'b0;
			   end
			endcase
		end
	end
endmodule

