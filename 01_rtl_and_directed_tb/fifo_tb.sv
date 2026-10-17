module tb;
//declaring ths signals
parameter depth = 16;
parameter data_width = 8;
 logic clk, rst_n, rd_en, wr_en;
 logic [data_width-1 : 0]data_in;
 logic [data_width-1:0] data_out;
 logic overflow, underflow, full, empty;
 localparam int count_width = (depth < 2) ? 1 : $clog2(depth + 1);
 logic [count_width-1 : 0] count;

// instentiating the fifo
sync_fifo  dut (.*);


// declaring the clock
initial begin

	clk = 0;
	forever #5 clk = ~clk;
end


// defining the test cases
initial begin
$monitor("\nwr_en= 0x%0b | rd_en = %0b | data_in = %0h | data_out= 0x%0h \n| overflow = %0b | underflow = %0b | full = %0b | empty = %0b | count = %0d ", wr_en, rd_en, data_in, data_out, overflow, underflow, full, empty, count );

//$monitor("\ndata_out= 0x%0h | overflow = %0b | underflow = %0b | full = %0b | empty = %0b | count = %0d ", data_out, overflow, underflow, full, empty, count);

$display("=========Reset=========");
	rst_n = 1'b0; rd_en = 1'b0; wr_en = 1'b0; data_in = 8'hff;
	#10;
// deasserting the rst and writing
$display("=========Writing 0xFF=========");
	rst_n = 1'b1; rd_en = 1'b0; wr_en = 1'b1; data_in = 8'hff;
	#10;
// reading the value
$display("=========Reading 0xFF=========");
	rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b0; data_in = 8'h00;
	#10;
// writing and checking the overflow
$display("=========Overflow and full=========");
	for(int i = 0; i<16; i++) begin
	rst_n = 1'b1; rd_en = 1'b0; wr_en = 1'b1; data_in = i;
	#10;
	end



// checking the underflow
$display("=========UNderflow and empty=========");
	for(int i = 0; i<15; i++) begin
	rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b0; data_in = i;
	#10;
	end
	rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b0; data_in = 8'h00;
	#10;
	rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b0; data_in = 8'h00;
	#10;
		rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b0; data_in = 8'h00;
	#10;

// now fifo is full it should show overflow
$display("=========Simultaneous read write=========");
	rst_n = 1'b1; rd_en = 1'b0; wr_en = 1'b1; data_in = 8'h01; #10;
	rst_n = 1'b1; rd_en = 1'b0; wr_en = 1'b1; data_in = 8'h01; #10;
	rst_n = 1'b1; rd_en = 1'b1; wr_en = 1'b1; data_in = 8'hff; #10;
	rst_n = 1'b1; rd_en = 1'b0; wr_en = 1'b1; data_in = 8'h01; 

	#100;

$finish;
end



endmodule
