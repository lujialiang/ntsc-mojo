////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
//
// Create Date:     02/09/2017 
// Module Name:     ntsc_sync
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield Sync and Pixel Generator
//
//                  The NTSC generator operates from a 12.5 MHz pixel clock tick
//
//                  The horizontal and vertical sync signals are output
//                  separately. Horizontal sync is gated to generate the
//                  appropriate pre/post-equalizing, vertical serration, and
//                  sync tip pulses. Vertical sync is asserted during the
//                  vertical serration pulses.
//
//                  Interlacing is accomplished by incrementing the line
//                  counter by two. This has the effect of producing an even
//                  field consisting of lines 0,2,4,...,524 and an odd field 
//                  consisting of lines 1,3,5,...525. The effective line count
//                  is 0-524 because lines 18 and 525 are half-lines.
//
//                  The pixel generator creates a 600x450 resolution which is
//                  slightly smaller than the safe action area. Total horizontal
//                  resolution is 794 and vertical resolution is 525. The active
//                  video region is between horizontal samples 165-764 (600
//                  total) and lines 58-507 (450 total).
//
// Inputs:          clk          - 50 MHz Mojo V3 clock input
//                  rst          - asynchronous reset
//                  pixel_tick   - 12.5 MHz pixel clock tick
//
// Outputs:         x            - horizontal pixel (0..599)
//                  y            - vertical pixel (0..449)
//                  active_video - active video signal
//                  hsync        - horizontal sync
//                  vsync        - vertical sync
//
////////////////////////////////////////////////////////////////////////////////

module ntsc_sync
    (
    input wire clk,
    input wire rst,

    input wire pixel_tick,
    
    output wire [9:0] x,
    output wire [8:0] y,
    
    output wire active_video,    
    
    output wire hsync,
    output wire vsync
    );
	
	
// CONSTANTS ///////////////////////////////////////////////////////////////////
   
    // horizontal sync sample counts (12.5 MHz)
    localparam HS_FRONT_PORCH  = 10'd19,  // Front Porch - 1.52 us
               HS_SYNC_TIP     = 10'd59,  // Horiz. Sync Tip - 4.72 us
               HS_HALF_LINE    = 10'd397, // Half Line - 31.76 us
               HS_FULL_LINE    = 10'd794, // Full Line - 63.52 us
               HS_EQUAL_PULSE  = 10'd29,  // Pre/Post-Equalizing Pulse - 2.32 us
               HS_SERRATION    = 10'd59;  // Vertical Serration - 4.72 us
    
    // line counts
    localparam VS_SERRATION    = 10'd6,     // Pre-Equalizing Pulses - Lines 0-5
               VS_POST_EQUAL   = 10'd12,    // Vertical Sync Pulses - Lines 6-11
               VS_BLANK        = 10'd18;    // Post-Equal. Pulses - Lines 12-17
    
    // active video region
    localparam HS_ACTIVE_LEFT  = 10'd165,   // Active video left (x = 0)
               HS_ACTIVE_RIGHT = 10'd764,   // Active video right (x = 599)
               VS_ACTIVE_TOP   = 10'd58,    // Active video top (y = 0)
               VS_ACTIVE_BTM   = 10'd507;   // Active video bottom (y = 449)
    
    // half lines
    localparam HALF_LINE_EVEN  = 10'd18,   // Even field - Line 18
               HALF_LINE_ODD   = 10'd525;  // Odd field  - Line 525
    
    // field ends
    localparam FIELD_END_EVEN  = 10'd524,  // Even field - Line 524
               FIELD_END_ODD   = 10'd525;  // Odd field - Line 525
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // horizonal sample and line counters
    reg [9:0] h_count_ff, h_count_ns;      // 0-793
    reg [9:0] line_ff, line_ns;            // 0-525 (half-lines make it 0-524)
    
    // half-line and end-of-line signals
    wire half_line, end_of_line;

    // hsync/vsync signals
    wire hsync_equalizing_en, hsync_equalizing;
    wire hsync_serration_en, hsync_serration;
    wire hsync_tip_en, hsync_tip;
    
    
// HORIZONTAL SAMPLE AND LINE COUNTERS /////////////////////////////////////////

    // body
    // registers
    always @(posedge clk, posedge rst)
        if(rst)
            begin
                h_count_ff <= 10'd0;
                line_ff <= 10'd1;		// reset to line 1, odd field
            end
        else
            begin
                h_count_ff <= h_count_ns;
                line_ff <= line_ns;
            end
    
    // half-line (lines 18 and 525) and end-of-line signals
    assign half_line = (line_ff == HALF_LINE_EVEN) ||
                       (line_ff == HALF_LINE_ODD);
    assign end_of_line = ((h_count_ff == HS_FULL_LINE - 10'd1) && !half_line) ||
                         ((h_count_ff == HS_HALF_LINE - 10'd1) && half_line);
        
    // horizontal sample and line counters next-state logic
    always @*
        begin
            h_count_ns = h_count_ff;
            line_ns = line_ff;
            
            if(pixel_tick)
                if(end_of_line)
                    begin
                        h_count_ns = 10'd0;
                        
                        if(line_ff == FIELD_END_EVEN)
                            line_ns = 10'd1; // finished even field, go to odd
                        else if(line_ff == FIELD_END_ODD)
                            line_ns = 10'd0; // finished odd field, go to even
                        else
                            line_ns = line_ff + 10'd2; // skip every other line
                    end
                else
                    h_count_ns = h_count_ff + 10'd1;
        end
    
    
// HORIZONTAL SYNC SIGNALS /////////////////////////////////////////////////////

    // vertical sync equalizing pulses for lines 0-5 and 12-17
    assign hsync_equalizing_en = (line_ff < VS_SERRATION) ||
                                 ((line_ff >= VS_POST_EQUAL) &&
                                  (line_ff < VS_BLANK));
    assign hsync_equalizing = (h_count_ff < HS_EQUAL_PULSE) ||
                              ((h_count_ff >= HS_HALF_LINE) &&
                               (h_count_ff < (HS_HALF_LINE + HS_EQUAL_PULSE)));
    
    // vertical sync serration pulses for lines 6-11
    assign hsync_serration_en = (line_ff >= VS_SERRATION) &&
                                (line_ff < VS_POST_EQUAL);
    assign hsync_serration = ((h_count_ff >= (HS_HALF_LINE - HS_SERRATION)) &&
                              (h_count_ff < HS_HALF_LINE)) ||
                             (h_count_ff >= HS_FULL_LINE - HS_SERRATION);
    
    // horizontal sync tip for lines 19-525 (18 is a half-line with no sync)
    assign hsync_tip_en = line_ff > VS_BLANK;
    assign hsync_tip = (h_count_ff >= HS_FRONT_PORCH) &&
                       (h_count_ff < (HS_FRONT_PORCH + HS_SYNC_TIP));
	
	
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////

    // output logic
    assign x = (active_video) ? (h_count_ff - HS_ACTIVE_LEFT) : 10'd0;
    assign y = (active_video) ? (line_ff - VS_ACTIVE_TOP) : 9'd0;
    
    assign active_video = ((h_count_ff >= HS_ACTIVE_LEFT) &&
                           (h_count_ff <= HS_ACTIVE_RIGHT)) &&
                          ((line_ff >= VS_ACTIVE_TOP) &&
                           (line_ff <= VS_ACTIVE_BTM));
    
    assign hsync = (hsync_equalizing_en & hsync_equalizing) |
                   (hsync_serration_en & hsync_serration) |
                   (hsync_tip_en & hsync_tip);
    assign vsync = (line_ff >= VS_SERRATION) && (line_ff < VS_POST_EQUAL);
    
endmodule
