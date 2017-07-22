////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     02/26/2017 
// Module Name:     pixel_clock 
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     Mod-4 clock divider for the Mojo V3 50 MHz clock to generate
//                  a 12.5 MHz tick to be used for a NTSC pixel clock.
//
// Inputs:          clk     - 50 MHz clock input
//                  rst     - asynchronous reset
//
// Outputs:         tick    - 12.5 MHz pixel clock tick
//
////////////////////////////////////////////////////////////////////////////////

module pixel_clock
    (
    input wire clk,
    input wire rst,
    
    output wire tick
    );
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
	
    reg [1:0] q_ff;


// MOD-4 DIVIDER ///////////////////////////////////////////////////////////////

    // body
    // registers
    always @(posedge clk, posedge rst)
        if(rst)
            q_ff <= 2'd0;
        else
            q_ff <= q_ff + 2'd1;
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    assign tick = (q_ff == 2'b11) ? 1'b1 : 1'b0;
    
endmodule
