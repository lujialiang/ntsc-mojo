////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     05/03/2017 
// Module Name:     rgb_332_palette
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield 3-3-2 RGB Palette Generator
//
//                  Generates 512-by-128 pixel palette. Each color is a 16-by-16
//                  square. There are 8 rows, one for each green level. Each
//                  horizontal square cycles through the 4 blue levels per 8 red
//                  levels.
//
// Parameters:      START_Y      - shift the y-pixel start position     
//
// Inputs:          x            - horizontal pixel
//                  y            - vertical pixel
//                  active_video - active video signal
//
// Outputs:         rgb          - red, green, blue level
//
////////////////////////////////////////////////////////////////////////////////

module rgb_332_palette
    #(
    parameter START_Y = 9'd0
    )
    (    
    input wire [9:0] x,
    input wire [8:0] y,
    
    input wire active_video,
    
    output wire [7:0] rgb
    );
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
    
    localparam BLACK = 8'h00;
    
	
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // y-pixel shifted position
    wire [8:0] y_shift;
    
    // active image signal
    wire image_on;
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
	
    // shift the image down the screen
    assign y_shift = y - START_Y;
    
    // palette is displayed when x < 512 and y < 128, shifted by the y-pixel
    // start position
    assign image_on = (y >= START_Y) & (~x[9]) & (~| y_shift[8:7]);
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    // red changes every 64 x-pixels, green changes every 16 y-pixels, and
    // blue changes every 16 x-pixels
    assign rgb = (active_video & image_on) ?
                    {x[5:4], y_shift[6:4], x[8:6]} :
                    BLACK;
    
endmodule
