
import BusTypes::mem_in_bus_t;

// copy [src, src + length) to [dest, dest + length)
// outputs finished = 1 when finished
module mem_copier(
	input [31:0] src, length, dest,
	input [31:0] mem_data_out,
	input clk, en,
	output mem_in_bus_t mem_in,
	output logic finished
);
	reg [31:0] src_end;
	logic [1:0] counter_mode;
	wire [31:0] count;
	accumulator counter('z, counter_mode, clk, count);

	typedef enum logic [2:0] { READ_MEM, WRITE_MEM, FIN } mem_copier_state_t;
	mem_copier_state_t state, next_state;

	always_comb
	begin
		next_state = READ_MEM;
		counter_mode = 2'b00; // do keep current counter value
		mem_in.mode = 2'b00;
		mem_in.address = src;
		mem_in.offset = count;
		mem_in.data = 'z;
		finished = 0;

		if ( !en )
			counter_mode = 2'b11;
		else
			case ( state )
				READ_MEM: begin
					mem_in.mode = 2'b00; // read
					mem_in.address = src;
					mem_in.offset = count;
					
					counter_mode = 2'b00; // keep current value
					
					// must do this check here instead of after WRITE_MEM because
					// accumulator is not incremented until this clock cycle & no
					// need to stick in a full adder where not necessary
					next_state = (count < length) ? WRITE_MEM : FIN;
				end
				WRITE_MEM: begin
					mem_in.mode = 2'b01; // write
					mem_in.address = dest;
					mem_in.offset = count;
					mem_in.data = mem_data_out;
					
					counter_mode = 2'b01; // increment
					
					next_state = READ_MEM;
				end
				FIN: begin
					finished = 1;
					next_state = FIN;
				end
			endcase
	end

	always_ff@(posedge clk)
	if ( !en )
		state <= READ_MEM;
	else
		state <= next_state;
endmodule