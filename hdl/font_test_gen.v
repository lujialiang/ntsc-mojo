////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke (adapted from Dr. Pong P. Chu)
// 
// Create Date:     06/27/2017
// Module Name:     font_test_gen
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield Font Test Generator
//
//                  Outputs a 64-by-2 character (512-by-32 pixel) pattern of all
//                  128 characters in the font ROM. Each character is a 8-by-16
//                  array of pixels.
//
//                  Adapted from the book "FPGA Prototyping by Verilog Examples"
//                  written by Dr. Pong P. Chu, (c) 2008.
//
// Parameters:      COLOR        - font color
//
// Inputs:          clk          - 50 MHz clock
//                  x            - horizontal pixel
//                  y            - vertical pixel
//                  active_video - active video signal
//
// Outputs:         rgb          - red, green, blue level
//
// Dependencies:    font_rom
//
////////////////////////////////////////////////////////////////////////////////

module font_test_gen
    #(
    parameter COLOR = WHITE
    )
    (
    input wire clk,
    
    input wire [9:0] x,
    input wire [8:0] y,
    
    input wire active_video,
    
    output wire [7:0] rgb
    );
    
// CONSTANTS ///////////////////////////////////////////////////////////////////

    localparam BLACK = 8'h00,
               WHITE = 8'hff;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////

    // font ROM signals
    wire [10:0] rom_addr;
    wire [6:0] char_addr;
    wire [3:0] row_addr;
    wire [2:0] bit_addr;

    // font data
    wire [7:0] font_word;
    wire font_bit;
    
    // character display control signal
    wire text_bit_on;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    font_rom font_unit
        (
        .clk(clk),
        .en(1'b1),
        .addr(rom_addr),
        .data(font_word)
        );
    
    
// SIGNALS /////////////////////////////////////////////////////////////////////
    
    // font ROM interface                                         
    assign char_addr = {y[4], x[8:3]};          // 128 characters (64-by-2)
    assign row_addr = y[3:0];                   // 16 y-pixels per character
    assign rom_addr = {char_addr, row_addr};    // 11-bit font ROM address
    
    assign bit_addr = x[2:0];                   // 8 x-pixels per character
    assign font_bit = font_word[~bit_addr];     // correct endianness between
                                                // screen coordinate and font
                                                // word
    
    // limit text generation to 512-by-32 region    
    assign text_bit_on = (~x[9] & (~| y[8:5])) ? font_bit : 1'b0;
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////
    
    assign rgb = (active_video & text_bit_on) ? WHITE : BLACK;
    
endmodule
