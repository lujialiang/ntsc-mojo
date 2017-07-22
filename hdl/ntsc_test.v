////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     06/27/2017 
// Module Name:     ntsc_test
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield Video Test
//
// Inputs:          clk          - 50 MHz clock input
//                  rst          - asynchronous reset
//                  x            - horizontal pixel
//                  y            - vertical pixel
//                  active_video - active video
//
// Outputs:         rgb          - red, green, blue level
//
// Dependencies:    ntsc, font_test_gen, rgb_332_palette, color_bars
//
////////////////////////////////////////////////////////////////////////////////

module ntsc_test
    (
    input wire clk,
    
    input wire [9:0] x,
    input wire [8:0] y,
    
    input wire active_video,
    
    output wire [7:0] rgb
    );
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // RGB signals
    wire [7:0] rgb0, rgb1, rgb2;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    // font ROM test generator (512-by-32)
    font_test_gen font_test_gen_unit
        (
        .clk(clk),
        .x(x),
        .y(y),
        .active_video(active_video),
        .rgb(rgb0)
        );
    
    // RGB 3-3-2 palette generator (512-by-128)
    rgb_332_palette #(.START_Y(9'd80)) rgb_332_palette_unit
        (
    	.x(x),
    	.y(y),
    	.active_video(active_video),
    	.rgb(rgb1)
        );
    
    // color bars
    color_bars #(.START_Y(9'd224)) color_bars_unit
        (
        .x(x),
        .y(y),
        .active_video(active_video),
        .rgb(rgb2)
        );
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////
    
    // combine the RGB outputs
    assign rgb = rgb0 + rgb1 + rgb2;
    
endmodule
