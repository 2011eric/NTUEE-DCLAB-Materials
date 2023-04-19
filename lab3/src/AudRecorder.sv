module AudRecorder(
	input i_rst_n, 
	input i_clk,
	input i_lrc,
	input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	output [19:0] o_address,
	output [15:0] o_data,
    output o_valid,
    output o_full
);

logic [1:0] state, state_next;
logic [20:0] addr, addr_next;
logic [4:0] bit_cnt, bit_cnt_next; 
logic [15:0] data, data_next;

localparam S_IDLE = 2'd0, S_WAIT = 2'd1, S_PROC = 2'd2, S_PAUSE = 2'd3;
localparam ADDR_BASE = {21{1'b1}}; // addr_base = -1;

assign o_address =  addr[19:0]; 
assign o_valid = ((state == S_WAIT) && (bit_cnt == 5'd16));
assign o_data = data;
assign o_full = (addr == {20{1'b1}});
always_comb begin 
    case (state)
        S_IDLE: begin
            addr_next = addr;
            bit_cnt_next = 5'd0;
            data_next = 16'd0;
            if(i_start) begin
                state_next = S_WAIT;
            end
            else begin
                state_next = state;
            end
            
        end 
        S_WAIT: begin
            if(addr == {20{1'b1}}) begin //full
                state_next = S_IDLE;
            end
            if(i_stop) begin
                state_next = S_IDLE;
            end 
            else if(i_pause) begin
                state_next = S_PAUSE;
            end
            else if(i_lrc) begin //start receiving data
                state_next = S_PROC;
            end else begin
                state_next = state;
            end
            addr_next = addr;
            bit_cnt_next = 5'd0;
            data_next = 16'd0;
        end
        S_PROC: begin
            state_next = state;
            addr_next = addr;
            bit_cnt_next = bit_cnt;
            data_next = data;
            if(i_stop) begin
                state_next = S_IDLE;
                addr_next = ADDR_BASE;
                bit_cnt_next = 5'd0;
                data_next = 16'd0;
            end
            else if(i_pause) begin
                state_next = S_PAUSE;
                addr_next = addr;
                bit_cnt_next = 5'd0;
                data_next = 16'd0;
            end 
            else if(bit_cnt < 5'd16) begin
                state_next = state;
                addr_next = addr;
                bit_cnt_next = bit_cnt + (i_lrc? 1:0);
                data_next = {data[14:0], i_data};
            end 
            else if(!i_lrc) begin // end of transmission
                state_next = S_WAIT;
                addr_next = addr + 1'd1;
                bit_cnt_next = bit_cnt;
                data_next = data;
            end
        end 
        S_PAUSE: begin
            state_next = state;
            addr_next = addr; // stays at the original address so we can continue recording
            bit_cnt_next = 5'd0;
            data_next = 16'd0;
            if(i_stop) begin
                state_next = S_IDLE;
            end
            else if(i_start) begin
                state_next = S_WAIT;
            end
        end
    endcase



end

always_ff @(posedge i_clk, negedge i_rst_n) begin 
    if(~i_rst_n) begin
        state <= S_IDLE;
        addr <= ADDR_BASE;
        bit_cnt <= 5'd0;
        data <= 16'd0;
    end 
    else begin
        state <= state_next;
        addr <= addr_next;
        bit_cnt <= bit_cnt_next;
        data <= data_next;
    end
end
endmodule