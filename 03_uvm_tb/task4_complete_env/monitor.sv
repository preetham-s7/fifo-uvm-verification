// `include "uvm_macros.svh"
// import uvm_pkg::*;

// class tx_monitor extends uvm_monitor;

    
//     `uvm_component_utils(tx_monitor)

//     uvm_analysis_port #(tx_item) ap;



    

//     function new(string name, uvm_component parent);
//         super.new(name, parent);
//     endfunction

//         virtual fifo_if vif;

//     function void build_phase(uvm_phase phase);
        
//         super.build_phase(phase);

//         if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
//             `uvm_info("Monitor", "Getting interface Output", UVM_LOW);

//         ap = new("ap", this); // building the object for the analysis port
        
//     endfunction

//     task run_phase(uvm_phase phase);


//         tx_item tx;

//         super.run_phase(phase);

//         forever begin
//  //       repeat(5) begin
//         @(negedge vif.clk);
        
//         tx = tx_item::type_id::create("tx");

//         if(vif.wr_en || vif.rd_en) begin

//             tx.rd_en = vif.rd_en;
//             tx.wr_en = vif.wr_en;
//             tx.data_in = vif.data_in;
//             tx.data_out = vif.data_out;
//             tx.overflow = vif.overflow;
//             tx.underflow = vif.underflow;
//             tx.full = vif.full;
//             tx.empty = vif.empty;
//             tx.count = vif.count;

//             //calling the port
//             ap.write(tx);

//             `uvm_info("Monitor", "Data Recieved From Interface ", UVM_LOW );


//             end
//         end

//     endtask



// //check phase


// //report phase




// endclass

`include "uvm_macros.svh"
import uvm_pkg::*;

class tx_monitor extends uvm_monitor;

    `uvm_component_utils(tx_monitor)

    uvm_analysis_port #(tx_item) ap;
    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Fail early if interface is missing
        if(!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Virtual interface 'vif' not found in Config DB!")
        end

        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        tx_item tx;
        super.run_phase(phase);

        forever begin
            @(posedge vif.clk);
            #1; // Sample after DUT nonblocking updates and away from driver writes.

            // Only create and sample when reset is inactive AND a operation occurs
            if (vif.rst_n && (vif.wr_en || vif.rd_en)) begin
                tx = tx_item::type_id::create("tx");

                tx.rd_en     = vif.rd_en;
                tx.wr_en     = vif.wr_en;
                tx.data_in   = vif.data_in;
                tx.data_out  = vif.data_out;
                tx.overflow  = vif.overflow;
                tx.underflow = vif.underflow;
                tx.full      = vif.full;
                tx.empty     = vif.empty;
                tx.count     = vif.count;

                ap.write(tx);

                `uvm_info("MON", $sformatf("Captured Tx: wr=%0b rd=%0b din=0x%0h dout=0x%0h count=%0d", 
                          tx.wr_en, tx.rd_en, tx.data_in, tx.data_out, tx.count), UVM_LOW)
            end
        end
    endtask

endclass
