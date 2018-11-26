
import BusTypes::astore_in_bus_t;

// mode = 0 -> search for length
//				if present, found = finished = 1 after O(n) cycles, len_out = the length
//				if not, found = 0, finished = 1 after O(n) cycles, len_out = 0
// mode = 1 -> save array length
module array_length_store(
	input astore_in_bus_t a_in,
	input clk, r,
	output reg [31:0] len_out,
	output logic found,
	output logic finished
);
	reg [31:0] next_idx;
	reg enable_search;
	reg [31:0] counter;
	reg [31:0] array_data [2**20:0];
	logic [31:0] next_counter;

	typedef enum logic [2:0] { CHECK_AT_COUNT, FIN_SUCCESS, FIN_FAILURE } alen_state_t;
	alen_state_t state, next_state;
	
	always_comb
	begin
		found = 0;
		finished = 0;
		len_out = 0;
		next_state = CHECK_AT_COUNT;
		next_counter = counter;

		case ( state )
			CHECK_AT_COUNT: begin
				if (counter >= next_idx) begin
					next_state = FIN_FAILURE;
				end else if (array_data[counter] == a_in.addr) begin
					next_state = FIN_SUCCESS;
				end else begin
					next_state = CHECK_AT_COUNT;
					next_counter = counter + 2;
				end
			end
			FIN_SUCCESS: begin
				len_out = array_data[counter + 1];
				found = 1;
				finished = 1;
				next_state = FIN_SUCCESS;
			end
			FIN_FAILURE: begin
				found = 0;
				finished = 0;
				next_state = FIN_FAILURE;
			end
		endcase
	end

	always_ff@(posedge clk)
	if ( !enable_search ) begin
		state <= CHECK_AT_COUNT;
		counter <= 32'b0;
	end else begin
		state <= next_state;
		counter <= next_counter;
	end

	always_ff@(posedge clk iff r == 0 or posedge r)
	if ( r ) begin
		array_data <= '{default:32'b0};
		next_idx <= 0;
		enable_search <= 0;
	end else begin
		if ( a_in.mode ) begin
			array_data[next_idx] <= a_in.addr;
			array_data[next_idx + 1] <= a_in.len;
			next_idx <= next_idx + 2;
			enable_search <= 0;
		end	else begin
			enable_search <= 1;
		end
	end
endmodule