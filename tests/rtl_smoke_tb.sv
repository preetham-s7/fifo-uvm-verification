`timescale 1ns/1ps

module rtl_smoke_tb;
    localparam int DEPTH = 3;

    logic clk, rst_n, rd_en, wr_en;
    logic [7:0] data_in, data_out;
    logic overflow, underflow, full, empty;
    logic [1:0] count;

    sync_fifo #(.depth(DEPTH), .data_width(8)) dut (.*);

    always #5 clk = ~clk;

    task automatic check(input bit condition, input string message);
        if (!condition) begin
            $display("FAIL: %s", message);
            $fatal(1);
        end
    endtask

    task automatic write_item(input logic [7:0] value);
        @(negedge clk);
        wr_en = 1'b1;
        rd_en = 1'b0;
        data_in = value;
        @(posedge clk);
        #1;
    endtask

    task automatic read_item(input logic [7:0] expected);
        @(negedge clk);
        wr_en = 1'b0;
        rd_en = 1'b1;
        @(posedge clk);
        #1;
        check(data_out == expected, "FIFO order mismatch");
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        rd_en = 1'b0;
        wr_en = 1'b0;
        data_in = '0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        write_item(8'h11);
        write_item(8'h22);
        write_item(8'h33);
        check(count == DEPTH && full && !overflow,
              "accepted final write must not overflow");

        write_item(8'h44);
        check(count == DEPTH && full && overflow,
              "write to full FIFO must overflow");

        read_item(8'h11);
        read_item(8'h22);
        read_item(8'h33);
        check(count == 0 && empty && !underflow,
              "accepted final read must not underflow");

        read_item(8'h33);
        check(count == 0 && empty && underflow,
              "read from empty FIFO must underflow");

        $display("VERDICT: PASS - non-power-of-two depth and error flags");
        $finish;
    end
endmodule
