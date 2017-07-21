////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     07/02/2017 
// Module Name:     data_bus_test
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield SRAM Data Bus Test
//
//                  Data Bus Test is a "walking ones" test. The test writes a
//                  pattern of "walking ones" (00000001, 00000010, etc) to
//                  the same address. It reads after each write to verify a
//                  good write. If the write and read values don't match at any
//                  point, the test fails and exits.
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

module data_bus_test
    (
    input wire clk,
    input wire rst,
    
    input wire en,
    
    output reg mem,
    output reg rw,
    input wire ready,
    
    output wire [19:0] addr,
    output reg [7:0] data2ram,
    input wire [7:0] data2fpga,
    
    output wire done,
    output wire result
    );
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
   
    // FSM states
    localparam S_IDLE    = 3'd0,
               S_WRITE   = 3'd1,
               S_READ    = 3'd2,
               S_COMPARE = 3'd3,
               S_DONE    = 3'd4;
    
    localparam TEST_ADDR = 20'h0_0000;
    localparam INIT_DATA = 8'b0000_0001;
    
    localparam FAIL    = 1'b0,
               SUCCESS = 1'b1;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // FSM state registers
    reg [2:0] state_ff, state_ns;
    
    // SRAM test registers
    reg [7:0] data_ff, data_ns;
    reg result_ff, result_ns;
    
    
// REGISTERS////////////////////////////////////////////////////////////////////
    
    always @(posedge clk, posedge rst)
        if(rst)
            begin
                state_ff <= S_IDLE;
                data_ff <= INIT_DATA;
                result_ff <= FAIL;
            end
        else
            begin
                state_ff <= state_ns;
                data_ff <= data_ns;
                result_ff <= result_ns;
            end
    
    
// NEXT STATE LOGIC ////////////////////////////////////////////////////////////
    
    always @*
        begin
            state_ns = state_ff;
            
            mem = 1'b0;
            rw = 1'b1;
            data2ram = 8'd0;
            
            data_ns = data_ff;
            result_ns = result_ff;
            
            case(state_ff)
                // initialize the test
                S_IDLE:                   
                    if(en)
                        begin
                            data_ns = INIT_DATA;
                            result_ns = FAIL;
                            
                            state_ns = S_WRITE;
                        end
                
                // write a test pattern to the test address
                S_WRITE:
                    if(ready)
                        begin
                            mem = 1'b1;
                            rw = 1'b0;
                            data2ram = data_ff;
                            
                            state_ns = S_READ;
                        end
                
                // read the test address
                S_READ:
                    if(ready)
                        begin                            
                            mem = 1'b1;
                            rw = 1'b1;
                            
                            state_ns = S_COMPARE;
                        end
                
                // compare the written and read patterns and walk the ones
                S_COMPARE:
                    if(ready)
                        // if written and read don't match, test failure
                        if(data2fpga != data_ff)
                            state_ns = S_DONE;
                        else
                            if(data_ff[7])
                                begin
                                    // test successful
                                    result_ns = SUCCESS;
                                    state_ns = S_DONE;
                                end
                            else
                                begin
                                    // walk to the one and continue the test
                                    data_ns = data_ff << 8'd1;
                                    state_ns = S_WRITE;
                                end
                
                S_DONE:
                    state_ns = S_DONE;
                
                default:
                    state_ns = S_DONE;
            
            endcase
        end
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    // SRAM bus
    assign addr = TEST_ADDR;
    
    // SRAM test results
    assign done = (state_ff == S_DONE);
    assign result = result_ff;
    
endmodule
