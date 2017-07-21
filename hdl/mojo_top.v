////////////////////////////////////////////////////////////////////////////////
//
// Author:          Ryan Clarke
// 
// Create Date:     05/05/2017 
// Module Name:     ntsc
// Target Devices:  Mojo V3 (Spartan-6)
//
// Description:     NTSC Shield for the Mojo V3
//
// Inputs:          clk         - 50 MHz clock input
//                  rst_n       - input from reset button (active low)
//                  cclk        - cclk input from AVR, high when AVR is ready
//                  spi_ss      - AVR SPI SS
//                  spi_mosi    - AVR SPI MOSI
//                  spi_sck     - ACR SPI SCK
//                  avr_tx      - AVR Tx => FPGA Rx
//                  avr_rx_busy - AVR Rx buffer full
//                  addr        - SRAM address
//
// Outputs:         led         - outputs to the 8 onboard LEDs
//                  spi_miso    - AVR SPI MISO
//                  spi_channel - AVR ADC channel select
//                  avr_rx      - AVR Rx => FPGA Tx
//                  rgb         - NTSC RGB color
//                  hsync       - NTSC horizontal sync
//                  vsync       - NTSC vertical sync
//                  we_n        - SRAM write enable (active low)
//                  oe_n        - SRAM output enable (active low)
//                  a           - SRAM address
//
// Tri-States:      dq          - SRAM data
//
// Dependencies:    ntsc, ntsc_test, sram_ctrl, sram_test
//
////////////////////////////////////////////////////////////////////////////////

module mojo_top
    (
    input clk,
    input rst_n,
    
    input cclk,
    
    output [7:0] led,
    
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    
    output [3:0] spi_channel,
    
    input avr_tx,
    output avr_rx,
    input avr_rx_busy,
    
    output [7:0] rgb,
    output hsync,
    output vsync,
    
    output we_n,
    output oe_n,
    output [19:0] a,
    inout [7:0] dq
    );
    
    
// SIGNAL DECLARATION //////////////////////////////////////////////////////////
    
    // make reset active high
    wire rst = ~rst_n;
    
    // NTSC signals
    wire [9:0] x;
    wire [8:0] y;
    wire active_video;
    
    // SRAM control and bus signals
    wire mem, rw, ready;
    wire [19:0] addr;
    wire [7:0] data2ram, data2fpga;
    
    // SRAM test signals
    wire done;
    wire [2:0] result;
    
    
// MODULES /////////////////////////////////////////////////////////////////////
    
    ntsc ntsc_unit
        (
    	.clk(clk),
    	.rst(rst),
    	.x(x),
    	.y(y),
    	.active_video(active_video),
    	.hsync(hsync),
    	.vsync(vsync)
        );
    
    ntsc_test ntsc_test_unit
        (
        .clk(clk),
        .x(x),
        .y(y),
        .active_video(active_video),
        .rgb(rgb)
        );
    
    sram_ctrl sram_ctrl_unit
        (
        .clk(clk),
        .rst(rst),
        .mem(mem),
        .rw(rw),
        .ready(ready),
        .addr(addr),
        .data2ram(data2ram),
        .data2fpga(data2fpga),
        .data2fpga_unreg(),
        .we_n(we_n),
        .oe_n(oe_n),
        .a(a),
        .dq(dq)
        );
    
    sram_test sram_test_unit
        (
        .clk(clk),
        .rst(rst),
        .mem(mem),
        .rw(rw),
        .ready(ready),
        .addr(addr),
        .data2ram(data2ram),
        .data2fpga(data2fpga),
        .done(done),
        .result(result)
        );
    
    
// OUTPUT LOGIC ////////////////////////////////////////////////////////////////
    
    // Mojo pins that must be hi-Z if not used
    assign spi_miso = 1'bz;
    assign avr_rx = 1'bz;
    assign spi_channel = 4'bzzzz;
    
    // LEDs display status of SRAM test
    assign led = {done, 4'd0, result};
    
endmodule
