module Top (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [3:0] o_random_out
);

// ===== States =====
parameter S_IDLE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_STOP = 2'b10;

// ===== Output Buffers =====
logic [3:0] o_random_out_r, o_random_out_w;
logic [5:0] cycle_r, cycle_w;
logic [31:0] period_r, period_w, counter_r, counter_w;
logic [3:0] seed_r;
logic i_start_pressed_r;

// ===== Registers & Wires =====
logic state_r, state_w;

// ===== Output Assignments =====
assign o_random_out = o_random_out_r;


// ===== Combinational Circuits =====
always_comb begin
	// Default Values
	o_random_out_w = o_random_out_r;
	state_w        = state_r;
	counter_w = counter_r;
	cycle_w = cycle_r;
	period_w = period_r;
	// FSM
	case(state_r)
	S_IDLE: begin
		if ((i_start_pressed_r ^ i_start) && i_start) begin
			state_w = S_PROC;
			o_random_out_w = seed_r;
			counter_w = 4'b0;
			cycle_w = 4'b0;
			period_w <= 32'd1250;
		end
	end
	S_PROC: begin
		if (((i_start_pressed_r ^ i_start) && i_start)|| (cycle_r == 6'd15) ) begin
			state_w = S_STOP;
		end 
		else if (counter_r == period_r) begin
			counter_w = 0;
			if (((cycle_r+1'd1) & 6'b11) == 32'b0 && cycle_r) begin
				period_w = period_r << 1'b1;
			end
			cycle_w = cycle_r + 1;
			o_random_out_w = (o_random_out_w * 4'd5) + 4'd1;
		end
		else begin
			counter_w = counter_r + 1;
		end
	end
	S_STOP: begin
		if ((i_start_pressed_r ^ i_start) && i_start) begin
			state_w = S_IDLE;
		end
	end
	endcase
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		o_random_out_r <= 4'd0;
		state_r        <= S_IDLE;
		counter_r <= 4'd0;
		i_start_pressed_r <= 0;
		cycle_r <= 0;
		period_r <= 32'd1250;
		seed_r <= 0;
 	end
	else begin
		o_random_out_r <= o_random_out_w;
		state_r        <= state_w;
		counter_r <= counter_w;
		cycle_r <= cycle_w;
		period_r <= period_w;
		seed_r <= seed_r + 4'b1;
		if (i_start) begin
			i_start_pressed_r = 1;
		end
		else begin
			i_start_pressed_r = 0;
		end
	end
end

endmodule