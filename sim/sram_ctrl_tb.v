`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////
//
// Author:        Ryan Clarke
//
// Create Date:   05/03/2017
// Module Name:   sram_ctrl_tb
// Target Device: Mojo V3 (Spartan-6)  
//
// Description:   Verilog Test Fixture for module sram_ctrl
//
// Dependencies:  sram_ctrl
// 
////////////////////////////////////////////////////////////////////////////////

module sram_ctrl_tb;
    
    
// INPUTS //////////////////////////////////////////////////////////////////////
    
    reg clk;
    reg rst;
    reg mem;
    reg rw;
    reg [19:0] addr;
    reg [7:0] data2ram;
    
    
// OUTPUTS /////////////////////////////////////////////////////////////////////
    
    wire ready;
    wire [7:0] data2fpga;
    wire [7:0] data2fpga_unreg;
    wire we_n;
    wire oe_n;
    wire [19:0] a;
    wire [7:0] dq;
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
    
    // Clock period (ns)
    localparam T_clk = 20;
    
    // SRAM timing (ns)
    localparam T_wp  = 8,   // write pulse width
               T_oe  = 4.5, // output enable access time
               T_ohz = 4;   // output disable to output in high-z
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////

    // tri-state for signal dq
    reg [7:0] dq_in;
    
    // SRAM register
    reg [7:0] sram;
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
    
    // tri-state for signal dq
    assign dq = dq_in;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
	
    sram_ctrl uut
        (
        .clk(clk),
        .rst(rst),
        .mem(mem),
        .rw(rw),
        .ready(ready),
        .addr(addr),
        .data2ram(data2ram),
        .data2fpga(data2fpga),
        .data2fpga_unreg(data2fpga_unreg),
        .we_n(we_n),
        .oe_n(oe_n),
        .a(a),
        .dq(dq)
        );
    
    
// CLOCK ///////////////////////////////////////////////////////////////////////
    
    // 50 MHz master clock
    always
        begin
            clk = 1'b1;
            #(T_clk / 2);
            
            clk = 1'b0;
            #(T_clk / 2);
        end
    
    
// MAIN ////////////////////////////////////////////////////////////////////////
	
    initial
        begin
            initialize();
        
            write_sram(20'h0_0000, "A");
            read_sram(20'h0_0000);
            
            // wait until OE goes high after the read and then delay a cycle
            @(posedge oe_n);
            @(posedge clk) $stop;
        end
    
    
// SRAM SIMULATION /////////////////////////////////////////////////////////////

    // write
    always
        begin
            // SRAM takes data T_wp after WE goes low
            @(negedge we_n);
            #(T_wp) sram = dq;
        end 
    
    // read
    always
        begin
            // SRAM data valid T_oe after OE goes low
            @(negedge oe_n);
            #(T_oe) dq_in = sram;
            
            // SRAM high-z T_ohz after OE goes high
            @(posedge oe_n);
            #(T_ohz) dq_in = 8'bzzzz_zzzz;
        end
    
    
// TASKS ///////////////////////////////////////////////////////////////////////
    
    // initialization
    task initialize;
        begin
            // SRAM controller signals default state
            mem = 0;
            rw = 1;
            addr = 0;
            data2ram = 0;
            
            // SRAM tri-state
            dq_in = 8'bzzzz_zzzz;
	        
            reset_async();
        end
    endtask
	
    // asynchronous reset
    task reset_async;
        begin
            rst = 1;
            #(T_clk / 2) rst = 0;
        end
    endtask
	
    // write data to SRAM address
    task write_sram(input [19:0] address, input [7:0] data);
        begin
            @(posedge clk) wait(ready);
            mem = 1;
            rw = 0;
            addr = address;
            data2ram = data;
    
            @(posedge clk);
            mem = 0;
            rw = 1;
            addr = 0;
            data2ram = 0;
        end
    endtask
    
    // read data from SRAM address
    task read_sram(input [19:0] address);
        begin
            @(posedge clk) wait(ready);
            mem = 1;
            rw = 1;
            addr = address;
            data2ram = 0;
            
            @(posedge clk);
            mem = 0;
            rw = 1;
            addr = 0;
            data2ram = 0;
        end
    endtask
	
endmodule
