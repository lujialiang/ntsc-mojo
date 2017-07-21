////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     05/07/2017 
// Module Name:     sram_ctrl
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield SRAM Controller
//
// Inputs:          clk         - 50 MHz Mojo V3 clock input
//                  rst         - asynchronous reset
//                  mem         - initiate memory operation
//                  rw          - read (1) or write (0)
//                  addr        - 20-bit address
//                  data2ram    - 8-bit data to write to SRAM
//
// Outputs:         ready       - ready for new operation
//                  data2fpga   - 8-bit data read from SRAM
//                  data2fpga   - 8-bit data read from SRAM (unregistered)
//                  we_n        - SRAM write enable (active low)
//                  oe_n        - SRAM output enable (active low)
//                  a           - SRAM address
//
// Tri-States:      dq          - SRAM data
//
////////////////////////////////////////////////////////////////////////////////

module sram_ctrl
    (
    input wire clk,
    input wire rst,
    
    input wire mem,
    input wire rw,
    output reg ready,
    
    input wire [19:0] addr,
    input wire [7:0] data2ram,
    output wire [7:0] data2fpga,
    output wire [7:0] data2fpga_unreg,
    
    output wire we_n,
    output wire oe_n,
    output wire [19:0] a,
    inout wire [7:0] dq
    );
	
	
// CONSTANTS ///////////////////////////////////////////////////////////////////
   
    // FSM states
    localparam [2:0] S_IDLE   = 3'd0,
                     S_READ1  = 3'd1,
                     S_READ2  = 3'd2,
                     S_WRITE1 = 3'd3,
                     S_WRITE2 = 3'd4;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // FSMD state
    reg [2:0] state_ff, state_ns;
    
    // address and data lines
    reg [19:0] addr_ff, addr_ns;
    reg [7:0] data2ram_ff, data2ram_ns;
    reg [7:0] data2fpga_ff, data2fpga_ns;
    
    // control lines
    reg we_n_ff, we_n_ns;
    reg oe_n_ff, oe_n_ns;
    reg tri_n_ff, tri_n_ns;
    
    
// FSMD AND CONTROL SIGNAL REGISTERS////////////////////////////////////////////
    
    always @(posedge clk, posedge rst)
        if(rst)
            begin
                state_ff <= S_IDLE;
                
                addr_ff <= 20'd0;
                data2ram_ff <= 8'd0;
                data2fpga_ff <= 8'd0;
                
                we_n_ff <= 1'b1;
                oe_n_ff <= 1'b1;
                tri_n_ff <= 1'b1;
            end
        else
            begin
                state_ff <= state_ns;
                
                addr_ff <= addr_ns;
                data2ram_ff <= data2ram_ns;
                data2fpga_ff <= data2fpga_ns;
                
                we_n_ff <= we_n_ns;
                oe_n_ff <= oe_n_ns;
                tri_n_ff <= tri_n_ns;
            end
    
    
// FSMD NEXT STATE LOGIC ///////////////////////////////////////////////////////
    
    always @*
        begin
            state_ns = state_ff;
            
            addr_ns = addr_ff;
            data2ram_ns = data2ram_ff;
            data2fpga_ns = data2fpga_ff;
            
            ready = 1'b0;
            
            we_n_ns = 1'b1;
            oe_n_ns = 1'b1;
            tri_n_ns = 1'b1;
            
            case(state_ff)
                S_IDLE:
                    begin
                        ready = 1'b1;
                        
                        if(mem)         // begin SRAM operation
                            begin
                                addr_ns = addr;
                                
                                if(rw)  // read operation
                                    begin
                                        state_ns = S_READ1;
                                    end
                                else    // write operation
                                    begin
                                        data2ram_ns = data2ram;
                                        state_ns = S_WRITE1;
                                    end
                            end
                    end
                
                S_WRITE1:
                    begin
                        we_n_ns = 1'b0;
                        tri_n_ns = 1'b0;
                        state_ns = S_WRITE2;
                    end
                
                S_WRITE2:
                    begin
                        tri_n_ns = 1'b0;
                        state_ns = S_IDLE;
                    end
                
                S_READ1:
                    begin
                        oe_n_ns = 1'b0;
                        state_ns = S_READ2;
                    end
                
                S_READ2:
                    begin
                        oe_n_ns = 1'b0;
                        data2fpga_ns = dq;
                        state_ns = S_IDLE;
                    end
                
                default:
                    state_ns = S_IDLE;
            endcase
        end
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////
	
    // data read from SRAM
    assign data2fpga_unreg = dq;
    assign data2fpga = data2fpga_ff;
    
    // SRAM address and data lines
    assign a = addr_ff;
    assign dq = (tri_n_ff) ? 8'bzzzz_zzzz : data2ram_ff;
    assign we_n = we_n_ff;
    assign oe_n = oe_n_ff;
    
endmodule
