////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     02/15/2017 
// Module Name:     ntsc
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield Sync and Pixel Clock
//
// Inputs:          clk          - 50 MHz clock input
//                  rst          - asynchronous reset
//
// Outputs:         x            - horizontal pixel
//                  y            - vertical pixel
//                  active_video - active video
//                  hsync        - horizontal sync
//                  vsync        - vertical sync
//
// Dependencies:    pixel_clock, ntsc_sync
//
////////////////////////////////////////////////////////////////////////////////

module ntsc
    (
    input wire clk,
    input wire rst,
    
    output wire [9:0] x,
    output wire [8:0] y,
    
    output wire active_video,
    
    output wire hsync,
    output wire vsync
    );
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    wire pixel_tick;
    
    
// MODULES /////////////////////////////////////////////////////////////////////

    // Generate a 12.5 MHZ pixel clock tick
    pixel_clock pixel_clock_unit
        (
        .clk(clk),
        .rst(rst),
        .tick(pixel_tick)
        );
    
    // NTSC sync and pixel generator
    ntsc_sync ntsc_sync_unit
        (
        .clk(clk),
        .rst(rst),
        .pixel_tick(pixel_tick),
        .x(x),
        .y(y),
        .active_video(active_video),
        .hsync(hsync),
        .vsync(vsync)
        );

endmodule
