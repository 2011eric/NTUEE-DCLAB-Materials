module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm
localparam S_IDLE = 2'd0, S_PREP = 2'd1, S_MONT = 2'd2, S_CALC = 2'd3;


wire prep_valid, prep_finished, mont, mont_finished;
wire [255:0] prep_data;
logic [1:0] state, nextstate;
logic [255:0] y, d, n, t;
logic [16:0] counter;


assign prep_valid = (state == S_PREP) ; // valid signal for RsaPrep
RsaPrep rsaprep(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_valid(prep_valid),
	.i_n(n),
	.i_y(y),
	.o_t(prep_data),
	.o_finished(prep_finished)
);


always_comb begin 
	case (state)
		S_IDLE: begin
			if(i_start) nextstate = S_PREP;
			else nextstate = S_IDLE;
		end 
		S_PREP: begin
			if(prep_finished) nextstate = S_MONT;
			else nextstate = S_PREP;
		end
		S_MONT: begin
			if(mont_finished) nextstate = S_CALC;
			else nextstate = S_MONT;
		end
		S_CALC: begin
			if(o_finished) nextstate = S_IDLE;
			else if(counter != 16'd256) nextstate = S_MONT;
		end
		default: 
			nextstate = S_IDLE;
	endcase	
end



always_ff @(posedge i_clk, posedge i_rst) begin 
	if(i_rst) begin
		state <= S_IDLE;
		y <= 0;
		d <= 0;
		n <= 0;
		t <= 0;
	end else begin
		state <= nextstate;	
		if(i_start) begin
			y <= i_a;
			d <= i_d;
			n <= i_n;
		end
		if(prep_finished) t <= prep_out;
	end
	
end
endmodule



module RsaPrep(
	input          i_clk,
	input          i_rst,
	input          i_valid,
	input  [255:0] i_n, // N
	input  [255:0] i_y, // y
	output logic [255:0] o_data,
	output         o_finished
);

logic proc;
logic [8:0] counter;
logic [255:0] n,m, t;

assign o_finished = (counter == 9'd257);

always_ff @(posedge i_clk, posedge i_rst) begin
	if(i_rst) begin
		n <= 0;
		m <= 0;
		t <= 0;
		proc <= 0;
	end else if(i_valid && !proc) begin
		proc <= 1;
		n <= i_n;
		t <= i_y;
	end else if(proc && counter <= 9'd256) begin
		counter <= counter + 1'b1;
		if(counter == 9'd256) begin // i-th bit of a is 1
			m <= (m+t >= n)? m+t-n : m+t;
		end else begin
			t <= (t+t > n)? t+t-n: t+t;
		end
	end
end


endmodule

