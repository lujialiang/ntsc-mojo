`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////
//
// Author:        Ryan Clarke
//
// Create Date:   05/03/2017
// Module Name:   rgb_332_palette_tb
// Target Device: Mojo V3 (Spartan-6)  
//
// Description:   Verilog Test Fixture for module rgb_332_palette
//
// Dependencies:  rgb_332_palette
// 
////////////////////////////////////////////////////////////////////////////////

module rgb_332_palette_tb;
    
    
// INPUTS //////////////////////////////////////////////////////////////////////
    reg [9:0] x;
    reg [8:0] y;
    reg active_video;
    
    
// OUTPUTS /////////////////////////////////////////////////////////////////////
    
    wire [7:0] rgb;
    
    
// CONSTANTS ///////////////////////////////////////////////////////////////////
    
    // pixel clock period (ns)
    localparam T_pclk = 80;
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // pixel clock
    reg pclk;
    
    // file descriptor
    integer bmp_file;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    rgb_332_palette uut
        (
        .x(x), 
        .y(y), 
        .active_video(active_video), 
        .rgb(rgb)
        );
    
    
// CLOCK ///////////////////////////////////////////////////////////////////////
    
    always
        begin
            pclk = 1;
            #(T_pclk / 2);
            
            pclk = 0;
            #(T_pclk / 2);
        end
    
    
// MAIN ////////////////////////////////////////////////////////////////////////
    
    initial
        begin
            initialize();
            
            bmp_file = $fopen("rgb_332_palette.bmp");
        
            write_file_header(bmp_file);
            write_bmp_header(bmp_file);
        
            @(posedge pclk) active_video = 1;
        
            repeat(450)
                begin
                    repeat(600)
                        begin
                            @(posedge pclk) write_rgb888(bmp_file, rgb);
                            x = x + 1;
                        end
                
                    y = y + 1;
                    x = 0;
                end
            
            $fclose(bmp_file);
            
            y = 0;
            active_video = 0;
        
            @(posedge pclk) $stop;
        end
    
    
// TASKS ///////////////////////////////////////////////////////////////////////
    
    // initialize
    task initialize;
        begin
            x = 0;
            y = 0;
            active_video = 0;
        end
    endtask
    
    // file header
    task write_file_header(input integer fd);
        begin
            // Field     | Bytes | Description
            // ----------|-------|------------
            // Type      | 2     | "BM"
            // Size      | 4     | File size
            // Reserved1 | 2     | Zero
            // Reserved2 | 2     | Zero
            // Offset    | 4     | Start of pixel data
            $fwrite(fd, "%c%c", "B", "M");
            $fwrite(fd, "%c%c%c%c", 8'h46, 8'h5c, 8'h0c, 0);
            $fwrite(fd, "%c%c", 0, 0);
            $fwrite(fd, "%c%c", 0, 0);
            $fwrite(fd, "%c%c%c%c", 8'h36, 0, 0, 0);
        end
    endtask
    
    // image header
    task write_bmp_header(input integer fd);
        begin
            // Field        | Bytes | Description
            // -------------|-------|------------
            // Size         | 4     | Header size (40)
            // Width        | 4     | Width in pixels
            // Height       | 4     | Height in pixels
            // Planes       | 2     | Image planes (1)
            // BPP          | 2     | Bits per pixel
            // Compression  | 4     | Compression type (0 = uncompressed)
            // Res X PPM    | 4     | Pixels per meter resolution
            // Res Y PPM    | 4     | Pixels per meter resolution
            // ClrUsed      | 4     | Color map entries used
            // ClrImportant | 4     | Color map significant entries
            $fwrite(fd, "%c%c%c%c", 40, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 8'h58, 8'h02, 0, 0);
            $fwrite(fd, "%c%c%c%c", 8'h3e, 8'hfe, 8'hff, 8'hff);
            $fwrite(fd, "%c%c", 1, 0);
            $fwrite(fd, "%c%c", 24, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
            $fwrite(fd, "%c%c%c%c", 0, 0, 0, 0);
        end
    endtask
    
    // convert RGB332 to RGB888
    task write_rgb888(input integer fd, input reg [7:0] rgb);
        begin
            $fwrite(bmp_file, "%c%c%c",
                    {5'd0, rgb[7:6]} * 255 / 3,  // blue
                    {5'd0, rgb[5:3]} * 255 / 7,  // green
                    {6'd0, rgb[2:0]} * 255 / 7); // red
        end
    endtask
    
endmodule
