module tx_fifo #(
	parameter DATA_WIDTH = 8,
	parameter FIFO_DEPTH = 16,
	parameter ADDR_WIDTH = 4   // log2(FIFO_EDPTH)
	
)(
	input clk,
	input rst_n,
	
	//寫入介面
	input write_en,
	input [DATA_WIDTH-1:0] write_data,
	
	//讀出介面
	input read_en,
	output [DATA_WIDTH-1:0] read_data,
	
	//狀態訊號
	output empty,
	output full
);
	
	// FIFO記憶體
	reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
	
	// 指標與計數器
	reg [ADDR_WIDTH-1:0] wr_ptr;
	reg [ADDR_WIDTH-1:0] rd_ptr;
	reg [ADDR_WIDTH:0] fifo_count;
	
	//初始化
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			wr_ptr <= 0;
	   end else if (write_en && !full) begin
			fifo_mem[wr_ptr] <= write_data;
			wr_ptr <= wr_ptr + 1;
		end
	end
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			rd_ptr <= 0;
		end else if (read_en && !empty) begin
			rd_ptr <= rd_ptr + 1;
		end
	end
	
	//計數器邏輯
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			fifo_count <= 0;
				fifo_count <= 0;
		end else begin
			case({write_en && !full, read_en && !empty})
				2'b10: fifo_count <= fifo_count + 1;
				2'b01: fifo_count <= fifo_count - 1;
				default: fifo_count <= fifo_count;
			endcase
		end
	end
	
	//資料讀出
	assign read_data = fifo_mem[rd_ptr];
	
	//狀態訊號
	assign empty = (fifo_count == 0);
	assign full = (fifo_count == FIFO_DEPTH);
endmodule
	