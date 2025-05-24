`timescale 1ns/1ps
module spi_master_tb;

	parameter DATA_WIDTH = 8;
	parameter FIFO_DEPTH = 16;
	
	reg clk;
	reg rst_n;
	reg start;
	wire busy;
	
	wire sclk;
	wire mosi;
	wire cs_n;
	
	reg fifo_wr_en;
	reg [DATA_WIDTH-1:0] fifo_wr_data;
	wire fifo_empty;
	wire fifo_full;
	
	// CPOL / CPHA測試參數
	reg cpol;
	reg cpha;
	
	//=== DUT ===
	spi_master #(
		.DATA_WIDTH(DATA_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.ADDR_WIDTH(4)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.start(start),
		.busy(busy),
		.sclk(sclk),
		.mosi(mosi),
		.cs_n(cs_n),
		.cpol(cpol),
		.cpha(cpha),
		.fifo_wr_en(fifo_wr_en),
		.fifo_wr_data(fifo_wr_data),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full)
	
	);
	
	//時脈產生器
	always #5 clk = ~clk;  //100MHz
	
	//主測試流程
	initial begin
		$display("=== SPI Master CPOL/CPHA模式測試===");
		clk = 0;
		rst_n = 0;
		start = 0;
		fifo_wr_en = 0;
		fifo_wr_data = 8'h00;
		cpol = 0;
		cpha = 0;
		
		#20; rst_n = 1;
		
		//測試Mode 0~3
		test_mode(0,0);  //Mode 0
		test_mode(0,1);  //Mode 1
		test_mode(1,0);  //Mode 2
		test_mode(1,1);  //Mode 3
		
		$display("===測試結束===");
		$finish;
	end
	
	//===測試子程序:測試單一模式===
	task test_mode(input reg mode_cpol, input reg mode_cpha);
		begin
			$display("---測試 CPOL=%0d, CPHA=%0d---", mode_cpol, mode_cpha);
			cpol = mode_cpol;
			cpha = mode_cpha;
			
			//初始化
			fifo_wr_en = 0;
			start = 0;
			#20;
			
			//寫入資料
			fifo_wr_data = 8'hA5;
			fifo_wr_en = 1;
			#10;
			fifo_wr_en = 0;
			
			//啟動傳輸
			#20
			start = 1;
			#10;
			start = 0;
			
			//等待busy結束
			wait (busy == 0);
			#30;
			
		end
	endtask
endmodule
		
