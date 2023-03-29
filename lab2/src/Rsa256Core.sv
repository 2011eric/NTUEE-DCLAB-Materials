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


wire prep_valid, prep_finished, mont_valid, mont_finished_m, mont_finished_t;
wire [255:0] prep_data, mont_data_m, mont_data_t;
logic [1:0] state, nextstate;
logic [256:0] y,y_next, d, d_next, n, n_next, t, t_next, m, m_next;
logic [16:0] counter, counter_next;
logic finished, finished_next;


assign prep_valid = (state == S_PREP); // valid signal for RsaPrep
assign mont_valid = (state == S_MONT && !mont_finished_m && !mont_finished_t);
assign o_a_pow_d = m[255:0];  //output is m
assign o_finished = finished;

RsaPrep rsaprep(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_valid(prep_valid),
	.i_n(n),
	.i_y(y),
	.o_data(prep_data),
	.o_finished(prep_finished)
);

// m <- mont(n, m, t)
RsaMont rsamont_1(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_valid(mont_valid),
	.i_n(n[255:0]),
	.i_a(m[255:0]),
	.i_b(t[255:0]),
	.o_data(mont_data_m),
	.o_finished(mont_finished_m)
);
// t <- mont(n, t, t)
RsaMont rsamont_2(
	.i_clk(i_clk),
	.i_rst(i_rst),
	.i_valid(mont_valid),
	.i_n(n[255:0]),
	.i_a(t[255:0]),
	.i_b(t[255:0]),
	.o_data(mont_data_t),
	.o_finished(mont_finished_t)
);
always_comb begin 
	m_next = m;
	d_next = d;
	counter_next = counter;
	t_next = t;
	finished_next = finished;
	y_next = y;
	n_next = n;
	case (state)
		S_IDLE: begin
			if(i_start) begin
				nextstate = S_PREP;
				d_next = i_d;
				counter_next = 0;
				m_next = 1;
				t_next = 0;
				y_next = i_a;
				n_next = i_n;
				finished_next = 0;
			end
			else nextstate = S_IDLE;
		end 
		S_PREP: begin
			if(prep_finished) begin
				nextstate = S_MONT;
				t_next = prep_data;
			end else begin
				nextstate = S_PREP;
			end
		end
		S_MONT: begin
			if(mont_finished_m & mont_finished_t) begin
				d_next = d >> 1;
				counter_next = counter + 1'd1;
				nextstate = S_CALC;
				m_next = d[0]? mont_data_m : m;
				t_next = mont_data_t;
			end
			else begin
				nextstate = S_MONT;
				t_next = t;
			end
		end
		S_CALC: begin
			if(counter == 16'd256) begin
				nextstate = S_IDLE;
				finished_next = 1'b1;
			end
			else  nextstate = S_MONT;
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
		m <= 1;
		counter <= 0;
		finished <= 0;
	end else begin
		state <= nextstate;	
		y <= y_next;
		n <= n_next;
		d <= d_next;
		t <= t_next;
		m <= m_next;
		counter <= counter_next;
		finished <= finished_next;
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
logic [256:0] n, m, t ;

assign o_finished = (counter == 9'd257);
assign o_data = t[255:0];
always_ff @(posedge i_clk, posedge i_rst) begin
	if(i_rst) begin
		n <= 0;
		m <= 0;
		t <= 0;
		proc <= 0;
		counter <= 0;
	end else if(i_valid && !proc) begin
		proc <= 1;
		n <= i_n;
		t <= i_y;
	end else if(proc && counter <= 9'd256) begin
		counter <= counter + 1'b1;
		if(counter == 9'd256) begin // i-th bit of a is 1
			m <= (m+t >= n)? m+t-n : m+t;
		end else begin
			if((t << 1 )>= n) begin
				t <= (t << 1) - n;
			end
			else begin
				t <= t<<1;
			end

		end
	end else if(counter == 9'd257) begin
		proc <= 0;
		counter <= 0;
	end
end


endmodule

module RsaMont(
	input          i_clk,
	input          i_rst,
	input          i_valid,
	input  [255:0] i_n, // N
	input  [255:0] i_a, // a
	input  [255:0] i_b, // b
	output logic [255:0] o_data,
	output         o_finished
);

localparam S_IDLE = 1'b0, S_PROC = 1'b1;
logic state, nextstate, finished, finished_next;
logic [255:0] a, a_next, b, b_next, n, n_next;
logic [257:0] m, m_next;
logic [7:0] counter, counter_next;

assign o_data = m[255:0];
assign o_finished = finished;

always_comb begin
	case (state) 
		S_IDLE : begin
			finished_next = 0;
			counter_next = 0;
			m_next = 0;
			if(i_valid) begin
				nextstate = S_PROC;
				b_next = i_b;
				n_next = i_n;
				a_next = i_a;
			end else begin
				nextstate = S_IDLE;
				b_next = 0;
				n_next = 0;
				a_next = 0;
			end
		end 
		S_PROC : begin
			a_next = a >> 1;
			b_next = b;
			n_next = n;
			//m_next = (m+ ((a[0] ? b:0 ) + (m_tmp[0] & 1'b1)? n:0)) >> 1;
			m_next = a[0] ? m+b:m;
			m_next = (m_next[0] & 1'b1)? (m_next +n):m_next;
			m_next = m_next >> 1;
			counter_next = counter + 8'd1;
			if(counter == 8'd255) begin
				m_next = (m_next >= n)? (m_next-n):m_next;
				finished_next = 1; //check if m_next and finished_next is correct
				nextstate = S_IDLE;
			end else begin
				finished_next = 0;
				nextstate = S_PROC;
			end
		end
		default: a_next = a;
	endcase
end


always_ff @(posedge i_clk, posedge i_rst) begin
	if(i_rst) begin
		state <= 0;
		a <= 0;
		b <= 0;
		n <= 0;
		m <= 0;
		counter <= 0;
		finished <= 0;
	end else begin
		a <= a_next;
		state <= nextstate;
		b <= b_next;
		n <= n_next;
		m <= m_next;
		counter <= counter_next;
		finished <= finished_next;
	end
end

endmodule
