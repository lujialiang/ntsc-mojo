////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     07/21/2017
// Module Name:     font_rom
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     Font ROM
//
//                  Synchronous Character ROM. 256 character, 8-by-16 font.
//                  ROM size 4096-by-8 bits (256 chars-by-16 rows/character.
//                  32 Kb equals two FPGA BRAM.
//
// Inputs:          clk     - 50 MHz clock
//                  en      - enable signal
//                  addr    - 12-bit address
//
// Outputs:         data    - 8-bit data
//
////////////////////////////////////////////////////////////////////////////////

module font_rom
    (
    input wire clk,
    input wire en,

    input wire [11:0] addr,
    output reg [7:0] data
    );
    
    reg [7:0] rom [0:4095];
    
    initial $readmemb("cp437.list", rom);
    
    always @(posedge clk)
        if(en)
            data = rom[addr];
    
endmodule
