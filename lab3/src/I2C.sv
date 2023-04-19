module I2cInitializer(
	input i_rst_n,
	input i_clk_100K,
	input i_start,
	output o_finished,
	output o_I2C_SCLK,
	inout i2c_sdat,
	output i2c_oen // you are outputing (you are not outputing only when you are "ack"ing.)
);



localparam [239: 0] settings = {
    24'b00110100_000_0000_0_1001_0111,
    24'b00110100_000_0001_0_1001_0111,
    24'b00110100_000_0010_0_0111_1001,
    24'b00110100_000_0011_0_0111_1001,
    24'b00110100_000_0100_0_0001_0101,
    24'b00110100_000_0101_0_0000_0000,
    24'b00110100_000_0110_0_0000_0000,
    24'b00110100_000_0111_0_0100_0010,
    24'b00110100_000_1000_0_0001_1001,
    24'b00110100_000_1001_0_0000_0001
};

localparam S_IDLE = 3'd0, S_START = 3'd1, S_PREPARE = 3'd2, S_MOD = 3'd3, S_TX = 3'd4, S_STOP1 = 3'd5, S_STOP2 = 3'd6, S_FINISH = 3'd7;




logic [2:0] state, state_next;
logic sdat, sdat_next;
logic sclk, sclk_next;
logic oen;
logic [3:0] bit_cnt, bit_cnt_next;
logic [2:0] ack_cnt, ack_cnt_next;
logic [4:0] setup_cnt, setup_cnt_next;
logic [239:0] setup_data, setup_data_next;
assign i2c_sdat = oen? sdat:1'bz;
assign i2c_oen = oen;
assign o_I2C_SCLK = sclk;
//TODO:assign o_finished
assign oen = (bit_cnt == 4'd9)? 0:1;
assign o_finished = (state == S_IDLE && setup_cnt == 4'd10);

always_comb begin
    bit_cnt_next = bit_cnt;
    ack_cnt_next = ack_cnt;
    setup_cnt_next = setup_cnt;
    setup_data_next = setup_data;
    case(state) 
        S_IDLE: begin
            if(i_start)begin
                state_next = S_START;
                sdat_next = 0; // start transmission
                sclk_next = 1;
            end
            else begin
                state_next = state;
                sdat_next = 1;
                sclk_next = 1;
            end
        end
        S_START: begin
            state_next = S_PREPARE;
            setup_cnt_next = setup_cnt + 1'd1;
            sclk_next = 0;
        end
        S_PREPARE: begin
            state_next = S_MOD;
            sclk_next = 0;
            bit_cnt_next = bit_cnt + 1'd1;
            if(ack_cnt == 2'd3) begin // done one setting
                state_next = S_STOP1;
                bit_cnt_next = 4'd0;
                ack_cnt_next = 2'd0;
                sdat_next = 0;
                setup_data_next = setup_data;
            end
            else if(bit_cnt == 4'd8) begin // ack
                ack_cnt_next = ack_cnt + 1'd1;
                sdat_next = sdat;
                setup_data_next = setup_data;
            end
            else begin
                ack_cnt_next = ack_cnt;
                sdat_next = setup_data[239];
                setup_data_next = setup_data << 1'd1;
            end
        end
        S_MOD: begin
            state_next = S_TX;
            sdat_next = sdat; // stays the same
            sclk_next = 1; // change to 1
        end
        S_TX: begin
            state_next = S_PREPARE;
            sdat_next = sdat;   
            sclk_next = 0;
            if(bit_cnt == 4'd9)begin
                bit_cnt_next = 4'd0;
            end
            else begin
                bit_cnt_next = bit_cnt;
            end
        end
        S_STOP1:begin
            state_next = S_STOP2;
            sdat_next = sdat;
            sclk_next = 1;
        end
        S_STOP2:begin
            state_next = S_FINISH;
            sdat_next = 1;
            sclk_next = 1;
        end
        S_FINISH:begin
            if(setup_cnt == 4'd10) begin
                state_next = S_IDLE;
                sdat_next = 1;
                sclk_next = 1;
            end else begin
                state_next = S_START;
                sdat_next = 0;
                sclk_next = 1;
            end
        end

    endcase
end


always_ff @( posedge i_clk_100K, negedge i_rst_n  ) begin
    if(!i_rst_n) begin
        state <= 3'd0;
        sdat <= 1;
        sclk <= 1;
        bit_cnt <= 0;
        ack_cnt <= 0;
        setup_cnt <= 0;
        setup_data <= settings;
    end
    else begin
        state <= state_next;
        sdat <= sdat_next;
        sclk <= sclk_next;
        bit_cnt <= bit_cnt_next;
        ack_cnt <= ack_cnt_next;
        setup_cnt <= setup_cnt_next;
        setup_data <= setup_data_next;
    end
end


endmodule