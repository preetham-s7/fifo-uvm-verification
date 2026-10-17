`include "uvm_macros.svh"
import uvm_pkg::*;

class tx_scoreboard extends uvm_component;

    `uvm_component_utils(tx_scoreboard)
    
    virtual fifo_if vif;
    uvm_analysis_imp #(tx_item, tx_scoreboard) sb_ap;

    // expected signals for the ref model;
    bit [7:0] ref_fifo[$]; // dynamic queue for the ref model
    bit expected_full, expected_empty, expected_overflow, expected_underflow;
    int expected_count;
    int pass_count = 0;
    int fail_count = 0;
    bit trans_pass;
    bit check_read;
    logic [7:0] expected_out; 
    
    int fifo_depth = 4; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sb_ap = new("sb_ap", this);

        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_error("SB", "Virtual interface not found in Scoreboard")

        expected_empty = 1;
        expected_full  = 0;
        expected_count = 0;
    endfunction

    function void write(tx_item tr);
        bit was_full;
        bit was_empty;
        
        // reset reference state during reset
        if (!vif.rst_n) begin
            ref_fifo.delete();
            expected_count = 0;
            expected_empty = 1;
            expected_full  = 0;
            expected_overflow = 0;
            expected_underflow = 0;
            return;
        end
        
        `uvm_info("SB", $sformatf("Received item: wr_en=%0b rd_en=%0b data_in=%0h", tr.wr_en, tr.rd_en, tr.data_in), UVM_LOW);

        check_read = 0; 
        trans_pass = 1;

        // Error flags describe whether the access was rejected at this edge,
        // so calculate them from the FIFO state before applying this item.
        was_full  = expected_full;
        was_empty = expected_empty;
        expected_overflow  = tr.wr_en && was_full;
        expected_underflow = tr.rd_en && was_empty;

        if ((tr.wr_en && !was_full) && (tr.rd_en && !was_empty)) begin
            // Simultaneous read/write
            ref_fifo.push_back(tr.data_in);
            expected_out = ref_fifo.pop_front();
            check_read = 1;
        end 
        else if (tr.wr_en && !was_full) begin
            // Write only
            ref_fifo.push_back(tr.data_in);
        end 
        else if (tr.rd_en && !was_empty) begin
            // Read only
            expected_out = ref_fifo.pop_front();
            check_read = 1;
        end

        if (check_read) begin
            trans_pass &= check_read_data(tr.data_out, expected_out);
            check_read = 0; // resetting check read flag
        end

        // Update core expected states
        expected_count = ref_fifo.size();
        expected_empty = (expected_count == 0);
        expected_full  = (expected_count == fifo_depth); 

        // Verify Flags
        trans_pass &= check_flag("Full", tr.full, expected_full);
        trans_pass &= check_flag("Empty", tr.empty, expected_empty);
        trans_pass &= check_flag("Overflow", tr.overflow, expected_overflow);
        trans_pass &= check_flag("Underflow", tr.underflow, expected_underflow);
        trans_pass &= check_count(tr.count, expected_count); 

        // Update counters
        if(trans_pass) pass_count++;
        else fail_count++;            
     
    endfunction

    // Helper Check Method: Read Data
    function bit check_read_data(logic [7:0] actual, logic [7:0] expected);
        if (actual === expected) begin
            $display("\n Time = [%0t] ns | [SCOREBOARD PASS| Read Data Match: DUT=%0d | REF=%0d", $time, actual, expected);
            return 1;
        end else begin
            $display("\n Time = [%0t] ns | [SCOREBOARD FAIL| Read Data Mismatch: DUT=%0d | REF=%0d", $time, actual, expected);
            return 0;
        end
    endfunction

    // Helper Check Method: Flags
    function bit check_flag(string flag_name, bit actual, bit expected);
        if (actual !== expected) begin
            $display("\n Time = [%0t] ns | SCOREBOARD FAIL | %0s Mismatch: DUT=%0b | REF=%0b", $time, flag_name, actual, expected);
            return 0;
        end else begin
            return 1;
        end
    endfunction

    // Helper Check Method: Count
    function bit check_count(int actual, int expected);
        if (actual !== expected) begin
            $display("\n Time = [%0t] ns | SCOREBOARD FAIL | COUNT Mismatch: DUT=%0d | REF=%0d", $time, actual, expected);
            return 0;
        end else begin
            return 1;
        end
    endfunction

    // Report
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("  ");

        $display("=================== FINAL REPORT ==================");
        $display("  ");

        $display(" Total passed checks = %0d", pass_count);
        $display(" Total failed checks = %0d", fail_count);
        
        if (fail_count == 0 && pass_count > 0)
            $display("=================== TEST PASSED SUCCESSFULLY ==================");
        else begin
             $display("============= TEST FAILED===================");
             `uvm_error("FIFO_RESULT", "No checks completed or scoreboard mismatches occurred")
        end

    endfunction
endclass
