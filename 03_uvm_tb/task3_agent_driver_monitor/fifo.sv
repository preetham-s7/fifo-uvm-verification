timeunit 1ns;
timeprecision 1ns;

module sync_fifo #(parameter depth = 4, parameter data_width = 8)
(fifo_if #(depth, data_width) bus);


localparam int ptr_width = (depth < 2) ? 1 : $clog2(depth);
logic [ptr_width-1 : 0] rd_ptr, wr_ptr;
logic [data_width-1 : 0]fifo [ 0 : depth-1]; 

//status & error flags
assign bus.full  = (bus.count == depth);
assign bus.empty = (bus.count == 0);

function automatic logic [ptr_width-1:0] advance_ptr(input logic [ptr_width-1:0] ptr);
    if (ptr == depth - 1)
        advance_ptr = '0;
    else
        advance_ptr = ptr + 1'b1;
endfunction


always_ff @(posedge bus.clk or negedge bus.rst_n) begin
if(!bus.rst_n) begin

// resetting the fifo
	for(int i = 0 ; i < depth ; i = i+1) begin
		fifo[i] <= '0;
	end
	
	rd_ptr <= '0;
	wr_ptr <= '0;
	bus.data_out <= '0;
	bus.count <= '0;
	bus.overflow <= 1'b0;
	bus.underflow <= 1'b0;
end

else begin
bus.overflow <= bus.wr_en && bus.full;
bus.underflow <= bus.rd_en && bus.empty;

// Simultaneous read/write allowed when FIFO is neither bus.full nor bus.empty  
if((bus.wr_en && !bus.full) && (bus.rd_en && !bus.empty)) begin

	fifo[wr_ptr] <= bus.data_in;
	wr_ptr <= advance_ptr(wr_ptr);

	bus.data_out <= fifo[rd_ptr] ;
	rd_ptr <= advance_ptr(rd_ptr);
	bus.count <= bus.count;

end

// Write accepted only if FIFO not bus.full
else if(bus.wr_en && !bus.full) begin
	fifo[wr_ptr] <= bus.data_in;
	wr_ptr <= advance_ptr(wr_ptr);
	bus.count <= bus.count + 1;
end


// read accepted only if fifo is not bus.empty

else if(bus.rd_en && !bus.empty) begin
	bus.data_out <= fifo[rd_ptr] ;
	rd_ptr <= advance_ptr(rd_ptr);
	bus.count <= bus.count - 1;
end

end



end

endmodule





