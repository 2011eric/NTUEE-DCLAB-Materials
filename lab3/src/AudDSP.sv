module AudDSP(
    input i_rst_n,
	input i_clk,
	input i_start,
	input i_pause,
	input i_stop,
	input[2:0] i_speed, // available range (0~7) which means (speed+1) times faster/slower
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	input i_daclrck,
	input[15:0] i_sram_data,
	output[15:0] o_dac_data,
	output[19:0] o_sram_addr
);
// state of pause

parameter S_PAUSE = 2'b00;
parameter S_PROC = 2'b01;
parameter S_STOP  = 2'b10;
// state of procedure type
parameter S_FAST = 2'b00;   // faster output with sample rate speed
parameter S_SLOW_0 = 2'b01; // constant interpolation
parameter S_SLOW_1 = 2'b10; // linear interpolation
parameter S_UNKNOWN = 2'b11;// this state means that we don't know what the output type is

logic[1:0] type_r, type_w, state_r, state_w;
logic[2:0] speed_counter_r , speed_counter_w; 
logic signed[19:0] hold_r, hold_w, next_r, next_w, output_r, output_w; 
logic[19:0] o_addr_r, o_addr_w;

assign o_sram_addr = o_addr_r;
assign o_dac_data  = output_r[15:0];

always_comb begin
	// design your control here
    if(i_fast)begin
        type_w = S_FAST;
    end
    else if(i_slow_0)begin
        type_w = S_SLOW_0;
    end
    else if(i_slow_1)begin
        type_w = S_SLOW_1;
    end
    else begin
        type_w = S_UNKNOWN;
    end

    case(state_r)
        S_PAUSE:begin
            if(i_start)begin
                state_w = S_PROC;
                speed_counter_w = speed_counter_r;
                o_addr_w = o_addr_r;
            end
            else if(i_stop)begin
                state_w         = S_STOP;
                hold_w          = 20'd0;
                next_w          = 20'd0;
                output_w        = 20'd0;
                o_addr_w        = 20'd0;
                speed_counter_w = 3'd0;
            end
            else begin
                state_w = S_PAUSE;
                speed_counter_w = speed_counter_r;
                o_addr_w = o_addr_r;
            end
        end
        S_PROC:begin
            if(i_pause)begin
                state_w = S_PAUSE;
                speed_counter_w = speed_counter_r;
                o_addr_w = o_addr_r;
            end
            else if(i_stop)begin
                state_w         = S_STOP;
                hold_w          = 20'd0;
                next_w          = 20'd0;
                next_w          = 20'd0;
                output_w        = 20'd0;
                o_addr_w        = 20'd0;
                speed_counter_w = 3'd0;
            end
            else begin
                state_w = S_PROC;
                speed_counter_w = speed_counter_r;
                o_addr_w = o_addr_r;
            end
        end
        S_STOP:begin
            state_w = S_STOP;
            if(i_start)begin
                state_w = S_PROC;
                speed_counter_w = 0;
                o_addr_w = 20'd0;
                hold_w = 20'd0;
                next_w = i_sram_data;
                type_w = S_UNKNOWN;
            end
            else begin
                state_w = S_STOP;
                speed_counter_w = 0;
                o_addr_w = 20'd0;
                hold_w = 20'd0;
                next_w = 20'd0;
                type_w = S_UNKNOWN;
                speed_counter_w = speed_counter_r;
            end
        end
        default:begin
            state_w         = S_PAUSE;
            hold_w          = 20'd0;
            next_w          = 20'd0;
            output_w        = 20'd0;
            o_addr_w        = 20'd0;
            speed_counter_w = 3'd0;
        end
    endcase

    case(type_r)
        S_FAST:begin
            hold_w = $signed(i_sram_data);
            next_w = $signed(i_sram_data);
            output_w = $signed(i_sram_data);
            o_addr_w = o_addr_r + {17'd0,i_speed} + 20'd1;
            speed_counter_w = 3'd7;
        end
        S_SLOW_0:begin
            output_w = $signed(next_r);
            if(speed_counter_r >= i_speed)begin
                speed_counter_w = 0;
                // read data from sram
                hold_w   = $signed(i_sram_data);
                next_w   = $signed(i_sram_data);
                o_addr_w = o_addr_r + 20'd1;
                // output
            end
            else begin
                speed_counter_w = speed_counter_r + 1;
                next_w = $signed(next_r);
            end
        end
        S_SLOW_1:begin
            if(speed_counter_r >= i_speed)begin
                // interpolation
                speed_counter_w = 0;
                output_w = $signed(next_r);
                hold_w   = $signed(next_r);
                next_w   = $signed(i_sram_data);
                o_addr_w = o_addr_r + 20'd1;
            end
            else begin
                speed_counter_w = speed_counter_r + 1;
                // interpolation
                hold_w   = $signed(hold_r);
                next_w   = $signed(next_r);
                output_w = ( $signed(hold_r) * (i_speed - speed_counter_r) + $signed(next_r) * (speed_counter_r + 1) )/(i_speed + 1);
            end
        end
        default:begin
            hold_w = $signed(0);
            next_w = $signed(0);
            output_w = $signed(i_sram_data);
            o_addr_w = 20'd0;
            speed_counter_w = 3'd7;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    // only process left sound
	if (!i_rst_n) begin
		state_r         <= S_STOP;
        type_r          <= S_UNKNOWN;
        hold_r          <= 19'd0;
        next_r          <= i_sram_data;
        output_r        <= 19'd0;
        o_addr_r        <= 20'd0;
        speed_counter_r <= 3'd0;
	end
	else begin
		state_r         <= state_w;
        type_r          <= type_w;
        hold_r          <= $signed(hold_w);
        next_r          <= $signed(next_w);
        output_r        <= $signed(output_w);
        o_addr_r        <= o_addr_w;
        speed_counter_r <= speed_counter_w;
	end
end

endmodule
