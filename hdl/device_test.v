////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     07/02/2017 
// Module Name:     device_test
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield SRAM Device Test
//
//                  Device Test checks that each address can hold a 0 and 1 bit.
//                  The test begins by writing an incrementing value to
//                  incrementing addresses (0x00000: 0x00, 0x00001: 0x01, etc),
//                  reads the data back, compares it, then writes the inverse
//                  (0x00000: 0xff, 0x00001: 0xfe, etc), and repeats.
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

module device_test
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
               S_WRITE   = 3'd1,
               S_READ    = 3'd2,
               S_COMPARE = 3'd3,
               S_DONE    = 3'd4;
    
    localparam INIT_ADDR = 20'h0_0000;
    
    localparam TEST_1 = 1'b0,
               TEST_2 = 1'b1;
    
    localparam FAIL    = 1'b0,
               SUCCESS = 1'b1;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // FSM state registers
    reg [2:0] state_ff, state_ns;
    
    // SRAM test signals
    reg test_ff, test_ns;
    reg [19:0] addr_ff, addr_ns;
    wire [7:0] data;
    reg result_ff, result_ns;
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
    
    assign data = (test_ff == TEST_1) ? addr_ff[7:0] :
                                        ~addr_ff[7:0];
    
    
// REGISTERS ///////////////////////////////////////////////////////////////////
    
    always @(posedge clk, posedge rst)
        if(rst)
            begin
                state_ff <= S_IDLE;
                test_ff <= TEST_1;
                addr_ff <= INIT_ADDR;
                result_ff <= FAIL;
            end
        else
            begin
                state_ff <= state_ns;
                test_ff <= test_ns;
                addr_ff <= addr_ns;
                result_ff <= result_ns;
            end
    
    
// NEXT STATE LOGIC ////////////////////////////////////////////////////////////
    
    always @*
        begin
            state_ns = state_ff;
            
            mem = 1'b0;
            rw = 1'b1;
            addr = 20'h0_0000;
            data2ram = 8'd0;
            
            test_ns = test_ff;
            addr_ns = addr_ff;
            result_ns = result_ff;
            
            case(state_ff)
                // initialize the test
                S_IDLE:
                    if(en)
                        begin                    
                            test_ns = TEST_1;
                            addr_ns = INIT_ADDR;
                            result_ns = FAIL;
                            
                            state_ns = S_WRITE;
                        end
                
                // write the test pattern
                S_WRITE:
                    if(ready)
                        begin
                            mem = 1'b1;
                            rw = 1'b0;
                            addr = addr_ff;
                            data2ram = data;
                            
                            if(addr_ff == 20'hf_ffff)
                                begin
                                    addr_ns = INIT_ADDR;
                                    state_ns = S_READ;
                                end
                            else
                                begin
                                    addr_ns = addr_ff + 20'h0_0001;
                                    state_ns = S_WRITE;
                                end
                        end
                
                // read the test address
                S_READ:
                    if(ready)
                        begin                            
                            mem = 1'b1;
                            rw = 1'b1;
                            addr = addr_ff;
                            
                            state_ns = S_COMPARE;
                        end
                
                S_COMPARE:
                    if(ready)
                        // verify data read vs data written
                        if(data2fpga != data)
                            state_ns = S_DONE;
                        else
                            if(addr_ff == 20'hf_ffff)
                                // last address and test 2 complete? done.
                                if(test_ff == TEST_2)
                                    begin
                                        result_ns = SUCCESS;
                                        state_ns = S_DONE;
                                    end
                                // otherwise, execute test 2
                                else
                                    begin
                                        test_ns = TEST_2;
                                        addr_ns = INIT_ADDR;
                                        
                                        state_ns = S_WRITE;
                                    end
                            else
                                begin
                                    addr_ns = addr_ff + 20'h0_0001;
                                    state_ns = S_READ;
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
