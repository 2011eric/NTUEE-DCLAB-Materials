`timescale 1ps/1ps

module I2C_test;

parameter cycle = 100.0;

logic i_clk;
logic i_rst_n, i_start, o_finished, o_sclk, o_oen;
wire o_sdat;


initial i_clk = 0;
always #(cycle/2.0) i_clk = ~i_clk;


I2cInitializer DUT(
    .i_rst_n(i_rst_n),
    .i_clk_100K(i_clk),
    .i_start(i_start),
    .o_finished(o_finished),
    .o_I2C_SCLK(o_sclk),
    .i2c_sdat(o_sdat),
    .i2c_oen(o_oen)
);


// module I2cInitializer(
// 	input i_rst_n,
// 	input i_clk_100K,
// 	input i_start,
// 	output o_finished,
// 	output o_I2C_SCLK,
// 	inout i2c_sdat,
// 	output i2c_oen // you are outputing (you are not outputing only when you are "ack"ing.)
// );
initial begin
	$fsdbDumpfile("i2c.fsdb");
	$fsdbDumpvars(0, I2C_test, "+all");
end  

initial begin
    i_clk = 0;
    i_rst_n = 1;
    i_start = 0;
    @(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk) i_rst_n = 0;
	@(negedge i_clk) i_rst_n = 1; 

    @(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk);
	@(negedge i_clk) i_start = 1;
	@(negedge i_clk);
	@(negedge i_clk) i_start = 0;




   
    repeat (50000) begin
        @(negedge i_clk);
    end
    // @(negedge i_clk) i_stop = 1;
	// @(negedge i_clk);
	// @(negedge i_clk) i_stop = 0;
end

initial #(cycle*10000000) $finish;

endmodule