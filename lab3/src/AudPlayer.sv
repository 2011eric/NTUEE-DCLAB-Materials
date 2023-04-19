// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
module AudPlayer (
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input signed [15:0] i_dac_data, //dac_data
	output o_aud_dacdat
);
    
// design the FSM and states as you like
// state
parameter S_WAIT_A	= 0;
parameter S_WAIT_B	= 1;
parameter S_PLAY	= 2;


logic [1:0] state_r,state_w;
logic [4:0] count_r,count_w;
logic signed [15:0] data_r,data_w;

assign o_aud_dacdat = (i_en)?data_r[15]:1'b0;


always_comb begin
	// design your control here
	state_w = state_r;
	data_w = data_r;
	count_w = count_r;

	case(state_r)
		S_WAIT_A:begin
			if(i_en & ~i_daclrck) begin
				state_w = S_WAIT_B;
			end
			else begin
				state_w = state_r;
			end
		end
		S_WAIT_B:begin
			if(i_en & i_daclrck) begin
				state_w = S_PLAY;
				// data_w = i_dac_data;
				count_w = 5'd0;
			end
			else begin
				state_w = state_r;
				// data_w = data_r;
				count_w = count_r;
			end
		end
		S_PLAY:begin
			if(count_r == 0) begin
				count_w = count_r+1;
				data_w = i_dac_data;
				state_w = state_r;
			end
			else if(count_r<5'd16) begin
				count_w = count_r+1;
				data_w = data_r<<1;
				state_w = state_r;
			end
			else begin
				count_w = 5'd0;
				state_w = S_WAIT_A; 
				data_w = 16'd0;

			end
		end
	endcase

	
end

always_ff @(negedge i_daclrck or negedge i_bclk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r <= S_WAIT_A;
		data_r <= 16'd0;
		count_r <= 5'd0;		
	end
	else begin
		state_r <= state_w;
		data_r <= data_w;
		count_r <= count_w;
		
	end
end

endmodule