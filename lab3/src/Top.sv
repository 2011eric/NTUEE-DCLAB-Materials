module Top (
	input i_rst_n,
	input i_clk,
	input i_key_0, // stop 
	input i_key_1, // play/pause
	input i_key_2, // record
	// input [3:0] i_speed, // design how user can decide mode on your own
	
	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,
	
	// I2C
	input  i_clk_100K,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,


	// SWITCH (fast/slow_0/slow_1/speed)
	input [5:0] i_SW
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

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

// those are wires
wire i2c_oen, i2c_sdat, i2c_finished;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic record_valid, record_full;

// regs for FSM
logic [2:0] state, state_next;
logic playable, playable_next; // indicate there is a playable audio in sram
logic i2c_start, i2c_start_next;

// control signal
logic record_start, record_pause, record_stop;
logic dsp_start, dsp_pause, dsp_stop;
logic player_en;



assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign o_SRAM_WE_N = (state == S_RECD && record_valid && !record_full) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk_100K(i_clk_100K),
	.i_start(i2c_start),
	.o_finished(i2c_finished),
	.o_I2C_SCLK(o_I2C_SCLK),
	.i2c_sdat(i2c_sdat),
	.i2c_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(dsp_start),
	.i_pause(dsp_pause),
	.i_stop(),
	.i_speed(i_SW[2:0]),
	.i_fast(i_SW[5]),
	.i_slow_0(i_SW[4]), // constant interpolation
	.i_slow_1(i_SW[3]), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(record_start),
	.i_pause(record_pause),
	.i_stop(record_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record),
	.o_valid(record_valid),
	.o_full(record_full)
);


always_comb begin
	playable_next = playable;
	record_start = 0;
	record_pause = 0;
	record_stop = 0;
	dsp_start = 0;
	dsp_pause = 0;
	dsp_stop = 0;

	i2c_start_next = 0;
	player_en = 0;
	case(state)
		S_IDLE: begin
			if(i_key_2)begin
				state_next = S_RECD;
				record_start = 1;
			end 
			else if(playable && i_key_1) begin
				state_next = S_PLAY;
				dsp_start = 1;
			end
			else begin
				state_next = state;
			end
		end
		S_I2C: begin // initialize i2c
			i2c_start_next = 0;
			if(!i2c_finished) begin // wait for  i2c initializer to finish its job
				state_next = S_I2C;
			end
			else begin
				state_next = S_IDLE;
			end 
		end
		S_RECD: begin
			//TODO: record time
			if(record_full) begin // sram is full
				state_next = S_IDLE;
				record_stop = 1;
			end
			else if(i_key_0) begin
				state_next = S_IDLE;
				record_stop = 1;
			end
			else if(i_key_1) begin
				state_next = S_RECD_PAUSE;
				record_pause = 1;
			end 
			else begin
				state_next = state;
			end
		end
		S_RECD_PAUSE: begin
			if(i_key_0) begin 
				state_next = S_IDLE;
			end
			else if(i_key_1) begin // press pause again to keep recording
				state_next = S_RECD;
				record_start = 1;
			end
			else begin
				state_next = state;
			end
		end
		S_PLAY: begin
			//TODO: stop dac
			player_en = 1;
			if(addr_play == addr_record) begin
				state_next = S_IDLE;
				dsp_stop  = 1;
			end // time exceed
			if(i_key_0) begin
				state_next = S_IDLE;
				dsp_stop = 1;
			end
			else if(i_key_1) begin
				state_next = S_PLAY_PAUSE;
				dsp_pause = 1;
			end
			else begin
				state_next = state;
			end
		end
		S_PLAY_PAUSE: begin
			if(i_key_0) begin
				state_next = S_IDLE;
				dsp_stop = 1;
			end
			else if(i_key_1) begin
				state_next = S_PLAY;
				dsp_start = 1;
			end
			else begin
				state_next = state;
			end
		end
	endcase	
	// design your control here
end

always_ff @(posedge i_AUD_BCLK or posedge i_rst_n) begin
	if (!i_rst_n) begin
		state <= S_I2C;
		i2c_start <= 1;
		playable <= 0;
	end
	else begin
		state <= state_next;
		i2c_start <= i2c_start_next;
		playable <= playable_next;
	end
end

endmodule