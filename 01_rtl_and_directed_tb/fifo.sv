module sync_fifo #(
    parameter int depth = 16,
    parameter int data_width = 8,
    parameter int ptr_width = (depth < 2) ? 1 : $clog2(depth),
    parameter int count_width = (depth < 2) ? 1 : $clog2(depth + 1)
)(
    input logic clk,
    input logic rst_n,
    input logic rd_en,
    input logic wr_en,
    input logic [data_width-1:0] data_in,
    output logic [data_width-1:0] data_out,
    output logic overflow,
    output logic underflow,
    output logic full,
    output logic empty,
    output logic [count_width-1:0] count
);

logic [ptr_width-1:0] rd_ptr, wr_ptr;
logic [data_width-1:0] fifo [0:depth-1];

assign full  = (count == depth);
assign empty = (count == 0);

function automatic logic [ptr_width-1:0] advance_ptr(input logic [ptr_width-1:0] ptr);
    if (ptr == depth - 1)
        advance_ptr = '0;
    else
        advance_ptr = ptr + 1'b1;
endfunction

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < depth; i++)
            fifo[i] <= '0;
        rd_ptr <= '0;
        wr_ptr <= '0;
        data_out <= '0;
        count <= '0;
        overflow <= 1'b0;
        underflow <= 1'b0;
    end else begin
        // Error flags describe rejected accesses at this clock edge.
        overflow <= wr_en && full;
        underflow <= rd_en && empty;

        if ((wr_en && !full) && (rd_en && !empty)) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= advance_ptr(wr_ptr);
            data_out <= fifo[rd_ptr];
            rd_ptr <= advance_ptr(rd_ptr);
        end else if (wr_en && !full) begin
            fifo[wr_ptr] <= data_in;
            wr_ptr <= advance_ptr(wr_ptr);
            count <= count + 1'b1;
        end else if (rd_en && !empty) begin
            data_out <= fifo[rd_ptr];
            rd_ptr <= advance_ptr(rd_ptr);
            count <= count - 1'b1;
        end
    end
end

endmodule
