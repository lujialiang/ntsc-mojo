# NTSC Shield for the Mojo V3
Verilog code to test the NTSC Shield designed for the [Embedded Micro](https://embeddedmicro.com) Mojo V3 FPGA development board. Board capabilities include:

* Composite and S-Video outputs
* 8-bit 3-3-2 RGB color input
* 1 MB SRAM
* Deconfliction with the Embedded Micro SDRAM Shield

To create a project in PlanAhead for the Mojo V3, please considering the following:

* Clone the repository first to a folder of your choice
* Create the project in the repository folder
* Do not copy sources to the project
* Select **xc6slx9tqg144-2** as the device
* Add **-g Binary:Yes -g Compress** to the Bitstream Settings

For more information, please see the Hackaday.io [page](https://hackaday.io/project/25560-ntsc-shield).
