`timescale 1ps/1ps

module top_test;

parameter cycle = 100.0;

logic i_rst_n, i_clk, i_key_0, i_key_1, i_key_2;
logic [19:0] o_SRAM_ADDR;
wire [15:0] io_SRAM_DQ;
logic o_SRAM_WE_N, o_SRAM_CE_N, o_SRAM_OE_N, o_SRAM_LB_N, o_SRAM_UB_N;
logic o_I2C_SCLK;
wire io_I2C_SDAT;
wire i_AUD_ADCDAT, i_AUD_ADCLRCK, i_AUD_BCLK, i_AUD_DACLRCK, o_AUD_DACDAT;
logic [5:0] i_SW;
initial i_clk = 0;
always #(cycle/2.0) i_clk = ~i_clk;

initial begin
	$fsdbDumpfile("top.fsdb");
	$fsdbDumpvars(0, top_test, "+all");
end  

Top DUT(
	.i_rst_n(i_rst_n),
    .i_clk(i_clk),
	.i_key_0(i_key_0), // stop 
	.i_key_1(i_key_1), // play/pause
	.i_key_2(i_key_2), // record
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// // AudDSP and SRAM
	.o_SRAM_ADDR(o_SRAM_ADDR),
	.io_SRAM_DQ(io_SRAM_DQ),
	.o_SRAM_WE_N(o_SRAM_WE_N),
	.o_SRAM_CE_N(o_SRAM_CE_N),
	.o_SRAM_OE_N(o_SRAM_OE_N),
	.o_SRAM_LB_N(o_SRAM_LB_N),
	.o_SRAM_UB_N(o_SRAM_UB_N),
	
	// I2C
	.i_clk_100K(i_clk),
	.o_I2C_SCLK(o_I2C_SCLK),
	.io_I2C_SDAT(io_I2C_SDAT),
	
	// AudPlayer
	.i_AUD_ADCDAT(i_AUD_ADCDAT),
	.i_AUD_ADCLRCK(i_AUD_ADCLRCK),
	.i_AUD_BCLK(i_AUD_BCLK),
	.i_AUD_DACLRCK(i_AUD_DACLRCK),
	.o_AUD_DACDAT(o_AUD_DACDAT),


	// SWITCH (fast/slow_0/slow_1/speed)
	.i_SW(i_SW)
	// SEVENDECODER (optional display)
	// output [5:0] o_record_time,
	// output [5:0] o_play_time,

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);




endmodule