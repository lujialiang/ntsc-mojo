////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     07/03/2017 
// Module Name:     addr_bus_test
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield SRAM Address Bus Test
//
//                  Address Bus Test is a "walking ones" test. The test writes a
//                  test pattern to each "walking one" address (0x00001,
//                  0x00002, etc.), then writes the inverse to each address
//                  (including 0x00000) and tests to make sure each other
//                  address holds the original test pattern. 
//
// Inputs:          clk         - 50 MHz Mojo V3 clock input
//                  rst         - asynchronous reset
//                  en          - enable test
//                  ready       - ready for new operation
//                  data2fpga   - 8-bit data read from SRAM
//		
// Outputs:         mem         - initiate memory operation
//                  rw          - read (1) or write (0)
//                  addr        - 20-bit address
//                  data2ram    - 8-bit data to write to SRAM
//                  done        - test done flag
//                  result      - test result
//
////////////////////////////////////////////////////////////////////////////////

module addr_bus_test
    (
    input wire clk,
    input wire rst,
    
    input wire en,
    
    output reg mem,
    output reg rw,
    input wire ready,
    
    output reg [19:0] addr,
    output reg [7:0] data2ram,
    input wire [7:0] data2fpga,
    
    output wire done,
    output wire result
    );
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
   
    // FSM states
    localparam S_IDLE    = 3'd0,
               S_INIT    = 3'd1,
               S_WRITE   = 3'd2,
               S_READ    = 3'd3,
               S_COMPARE = 3'd4,
               S_REINIT  = 3'd5,
               S_DONE    = 3'd6;
    
    // initial address and data
    localparam INIT_ADDR = 20'h0_0000;
    localparam INIT_DATA = 8'b1010_1010;
    localparam TEST_DATA = ~INIT_DATA;
    
    // test results
    localparam FAIL    = 1'b0,
               SUCCESS = 1'b1;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // FSM registers
    reg [2:0] state_ff, state_ns;
    
    // test registers
    reg [19:0] addr_ff, addr_ns;
    reg [19:0] test_addr_ff, test_addr_ns;
    wire [7:0] data;
    reg result_ff, result_ns;
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
    
    // multiplex data depending on if it's the test address or not
    assign data = (addr_ff == test_addr_ff) ? TEST_DATA : INIT_DATA;
    
    
// REGISTERS ///////////////////////////////////////////////////////////////////
    
    always @(posedge clk, posedge rst)
        if(rst)
            begin
                state_ff <= S_IDLE;
                addr_ff <= 20'h0_0001;
                test_addr_ff <= INIT_ADDR;
                result_ff <= FAIL;
            end
        else
            begin
                state_ff <= state_ns;
                addr_ff <= addr_ns;
                test_addr_ff <= test_addr_ns;
                result_ff <= result_ns;
            end
    
    
// NEXT STATE LOGIC ////////////////////////////////////////////////////////////
    
    always @*
        begin
            state_ns = state_ff;
            
            // default control, address, and data signals
            mem = 1'b0;
            rw = 1'b1;
            addr = 20'h0_0000;
            data2ram = 8'd0;
            
            addr_ns = addr_ff;
            test_addr_ns = test_addr_ff;
            result_ns = result_ff;
            
            case(state_ff)
                // idle state
                S_IDLE:
                    if(en)
                        begin                    
                            // reset address, test address, and result
                            addr_ns = 20'h0_0001;
                            test_addr_ns = INIT_ADDR;
                            result_ns = FAIL;
                            
                            state_ns = S_INIT;
                        end
                
                // initialize the SRAM
                S_INIT:
                    if(ready)
                        begin
                            mem = 1'b1;
                            rw = 1'b0;
                            addr = addr_ff;
                            data2ram = INIT_DATA;
                            
                            // "walk the ones" for the address lines
                            if(addr_ff[19])
                                begin
                                    // reset address for the upcoming read
                                    addr_ns = INIT_ADDR;
                                    state_ns = S_WRITE;
                                end
                            else
                                begin
                                    addr_ns = addr_ff << 1;
                                    state_ns = S_INIT;
                                end
                        end
                
                // write the test data to the test address
                S_WRITE:
                    if(ready)
                        begin
                            mem = 1'b1;
                            rw = 1'b0;
                            addr = test_addr_ff;
                            data2ram = TEST_DATA;
                            
                            state_ns = S_READ;
                        end
                
                // read from the SRAM
                S_READ:
                    if(ready)
                        begin                            
                            mem = 1'b1;
                            rw = 1'b1;
                            addr = addr_ff;
                            
                            state_ns = S_COMPARE;
                        end
                
                // compare written and read data
                S_COMPARE:
                    if(ready)
                        if(data2fpga != data)
                            state_ns = S_DONE;
                        else
                            if(addr_ff[19])
                                begin
                                    if(test_addr_ff[19])
                                        begin
                                            // if last test address complete and
                                            // all addresses good, we're done
                                            result_ns = SUCCESS;
                                            state_ns = S_DONE;
                                        end
                                    else
                                        begin
                                            // if it's not the last test address
                                            // then re-init the test address
                                            // and continue
                                            addr_ns = INIT_ADDR;
                                            state_ns = S_REINIT;
                                        end
                                end
                            else
                                begin
                                    // "walk the ones" of the address
                                    if(addr_ff == 20'h0_0000)
                                        addr_ns = 20'h0_0001;
                                    else
                                        addr_ns = addr_ff << 1;
                                    
                                    state_ns = S_READ;
                                end
                
                // re-write the last test address with the init data
                S_REINIT:
                    if(ready)
                        begin
                            mem = 1'b1;
                            rw = 1'b0;
                            addr = test_addr_ff;
                            data2ram = INIT_DATA;
                            
                            // "walk the ones" of the test address
                            if(test_addr_ff == 20'h0_0000)
                                test_addr_ns = 20'h0_0001;
                            else
                                test_addr_ns = test_addr_ff << 1;
                            
                            state_ns = S_WRITE;
                        end
                
                S_DONE:
                    state_ns = S_DONE;
                
                default:
                    state_ns = S_DONE;
            
            endcase
        end
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////
    
    // SRAM test results
    assign done = (state_ff == S_DONE);
    assign result = result_ff;
    
endmodule
