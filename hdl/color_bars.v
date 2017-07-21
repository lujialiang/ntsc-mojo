////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     03/11/2017 
// Module Name:     color_bars
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield Color Bar Generator
//
//                  Generates 8 vertical colors bars: black, red, green, yellow,
//                  blue, magenta, cyan, and white.
//
// Parameters:      START_Y      - starting row
//
// Inputs:          x            - horizontal pixel
//                  y            - vertical pixel
//                  active_video - active video signal
//
// Outputs:         rgb          - red, green, blue level
//
////////////////////////////////////////////////////////////////////////////////

module color_bars
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

    localparam BLACK   = 8'b0000_0000,
               RED     = 8'b0000_0111,
               GREEN   = 8'b0011_1000,
               YELLOW  = 8'b0011_1111,
               BLUE    = 8'b1100_0000,
               MAGENTA = 8'b1100_0111,
               CYAN    = 8'b1111_1000,
               WHITE   = 8'b1111_1111;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////

    wire [7:0] color;
    
    
// COLOR BAR GENERATOR /////////////////////////////////////////////////////////
	
    assign color = (x < 75)  ? BLACK :
                   (x < 150) ? RED :
                   (x < 225) ? GREEN :
                   (x < 300) ? YELLOW :
                   (x < 375) ? BLUE :
                   (x < 450) ? MAGENTA :
                   (x < 525) ? CYAN :
                   WHITE;
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    assign rgb = (active_video & y >= START_Y) ? color : BLACK;
    
endmodule
