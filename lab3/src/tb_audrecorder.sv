`timescale 1ps/1ps

module AudRecorder_test;

parameter cycle = 100.0;

logic i_clk;
logic i_rst_n, i_start, i_lrc, i_pause, i_stop, i_data;

logic [19:0] o_address;
logic [15:0] o_data;
logic o_valid;

initial i_clk = 0;
always #(cycle/2.0) i_clk = ~i_clk;


AudRecorder DUT(
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_lrc(i_lrc),
    .i_start(i_start),
    .i_pause(i_pause),
    .i_stop(i_stop),
    .i_data(i_data),
    .o_address(o_address),
    .o_data(o_data),
    .o_valid(o_valid)
);

initial begin
	$fsdbDumpfile("audrecorder.fsdb");
	$fsdbDumpvars(0, AudRecorder_test, "+all");
end  

logic [15:0] dat, dat2;
initial begin
    i_clk = 0;
    i_rst_n = 1;
    i_start = 0;
    i_pause = 0;
    i_stop = 0;
    dat = 16'b0010001100100011;
    dat2 = 16'b1100110011001100;
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


    // data 1
    i_data = 0;
    @(negedge i_clk) i_lrc = 1;
    for (int i = 0; i < 16; i = i+1 ) begin
        @(negedge i_clk) i_data = dat[i];
    end
    repeat (5) begin
        @(negedge i_clk);
    end
    @(negedge i_clk) i_lrc = 0;
    repeat (50) begin
        @(negedge i_clk);
    end



    // data2
    i_data = 0;
    @(negedge i_clk) i_lrc = 1;
    for (int i = 0; i < 16; i = i+1 ) begin
        @(negedge i_clk) i_data = dat[i];
    end
    repeat (5) begin
        @(negedge i_clk);
    end
    @(negedge i_clk) i_lrc = 0;

    repeat (50) begin
        @(negedge i_clk);
    end


    // data 3
    i_data = 0;
    @(negedge i_clk) i_lrc = 1;
    for (int i = 0; i < 10; i = i+1 ) begin
        @(negedge i_clk) i_data = dat2[i];
    end
    @(negedge i_clk) i_pause = 1; 
    @(negedge i_clk) i_pause = 0;
//    @(negedge i_clk) i_start = 1; 
  //  @(negedge i_clk) i_start = 0; 
    repeat (5) begin
        @(negedge i_clk);
    end
    @(negedge i_clk) i_lrc = 0;
    repeat (50) begin
        @(negedge i_clk);
    end
    @(negedge i_clk) i_stop = 1;
	@(negedge i_clk);
	@(negedge i_clk) i_stop = 0;
end

initial #(cycle*10000000) $finish;

endmodule