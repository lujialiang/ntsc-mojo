`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////
//
// Author:        Ryan Clarke
//
// Create Date:   02/19/2017
// Module Name:   ntsc_tb
// Target Device: Mojo V3 (Spartan-6)  
//
// Description:   Verilog Test Fixture for module ntsc
//
// Dependencies:  ntsc
// 
////////////////////////////////////////////////////////////////////////////////

module ntsc_tb;
    
    
// INPUTS //////////////////////////////////////////////////////////////////////
    
    reg clk;
    reg rst;
    
    
// OUTPUTS /////////////////////////////////////////////////////////////////////
    
    wire [9:0] x;
    wire [8:0] y;
    wire active_video;
    wire hsync;
    wire vsync;
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
    
    // clock period (ns)
    localparam T = 20;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    ntsc uut
        (
        .clk(clk),
        .rst(rst),
        .x(x),
        .y(y),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync)
        );
    
    
// CLOCK ///////////////////////////////////////////////////////////////////////
    
    always
        begin
        clk = 1'b1;
        #(T/2);
        
        clk = 1'b0;
        #(T/2);
    end
    
    
// MAIN ////////////////////////////////////////////////////////////////////////
    
    initial
        begin
            // Reset for the first half cycle
            rst = 1;
            #(T/2);
            rst = 0;       
            
            // Wait 17.28 ms
            #(3250*T);
        
            $stop;
        end
    
endmodule
