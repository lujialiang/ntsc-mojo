////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     05/24/2017 
// Module Name:     sram_test
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield SRAM Test
//
//                  Comprehensive test routine for the NTSC Shield onboard
//                  SRAM. Runs a Data Bus Test, Address Bus Test, and a Device
//                  Test.
//
// Inputs:          clk         - 50 MHz Mojo V3 clock input
//                  rst         - asynchronous reset
//                  ready       - ready for new operation
//                  data2fpga   - 8-bit data read from SRAM
//		
// Outputs:         mem         - initiate memory operation
//                  rw          - read (1) or write (0)
//                  addr        - 20-bit address
//                  data2ram    - 8-bit data to write to SRAM
//                  done        - test done flag
//                  result      - 3-bit test result
//
////////////////////////////////////////////////////////////////////////////////

module sram_test
    (
    input wire clk,
    input wire rst,
    
    output wire mem,
    output wire rw,
    input wire ready,
    
    output wire [19:0] addr,
    output wire [7:0] data2ram,
    input wire [7:0] data2fpga,
    
    output wire done,
    output wire [2:0] result
    );
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // SRAM signals
    wire dbus_mem, abus_mem, dev_mem;
    wire dbus_rw, abus_rw, dev_rw;
    wire [19:0] dbus_addr, abus_addr, dev_addr;
    wire [7:0] dbus_data2ram, abus_data2ram, dev_data2ram;
    
    // test result signals
    wire abus_en, dev_en;
    wire dbus_done, abus_done, dev_done;
    wire dbus_result, abus_result, dev_result;
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
    
    assign abus_en = dbus_done & dbus_result;
    assign dev_en = abus_done & abus_result;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    data_bus_test data_bus_test_unit
        (
        .clk(clk),
        .rst(rst),
        .en(1'b1),
        .mem(dbus_mem),
        .rw(dbus_rw),
        .ready(ready),
        .addr(dbus_addr),
        .data2ram(dbus_data2ram),
        .data2fpga(data2fpga),
        .done(dbus_done),
        .result(dbus_result)
        );
    
    addr_bus_test addr_bus_test_unit
        (
        .clk(clk),
        .rst(rst),
        .en(abus_en),
        .mem(abus_mem),
        .rw(abus_rw),
        .ready(ready),
        .addr(abus_addr),
        .data2ram(abus_data2ram),
        .data2fpga(data2fpga),
        .done(abus_done),
        .result(abus_result)
        );
    
    device_test device_test_unit
        (
        .clk(clk),
        .rst(rst),
        .en(dev_en),
        .mem(dev_mem),
        .rw(dev_rw),
        .ready(ready),
        .addr(dev_addr),
        .data2ram(dev_data2ram),
        .data2fpga(data2fpga),
        .done(dev_done),
        .result(dev_result)
        );
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    // SRAM control and bus output
    assign mem = (dev_en)  ? dev_mem :
                 (abus_en) ? abus_mem :
                             dbus_mem;
    
    assign rw = (dev_en)  ? dev_rw :
                (abus_en) ? abus_rw :
                            dbus_rw;
    
    assign addr = (dev_en)  ? dev_addr :
                  (abus_en) ? abus_addr :
                              dbus_addr;
    
    assign data2ram = (dev_en)  ? dev_data2ram :
                      (abus_en) ? abus_data2ram :
                                  dbus_data2ram;
    
    // SRAM test results
    assign done = dbus_done & abus_done & dev_done;
    assign result = {dev_result, abus_result, dbus_result};
    
endmodule
