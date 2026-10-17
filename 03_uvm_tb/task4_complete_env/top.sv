

module top;
    import uvm_pkg::*;
    import tx_pkg::*;

    fifo_if vif();
    sync_fifo fifo_dut (.bus(vif));

    initial begin 
        vif.clk = 0;
        vif.rst_n = 0;   // Assert reset
        vif.wr_en = 0;
        vif.rd_en = 0;
        vif.data_in = 0;
        #20;
        vif.rst_n = 1;   // Release reset
    end

    always #5 vif.clk = ~vif.clk;

    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "uvm_test_top.env*", "vif", vif);
        run_test("tx_test");
    end
endmodule
