
import BusTypes::mem_in_bus_t;

module mem_in_bus_buf(
	input mem_in_bus_t in,
	input en,
	output mem_in_bus_t out
);
	tribuf_32 address_buf(in.address, en, out.address);
	tribuf_32 offset_buf(in.offset, en, out.offset);
	tribuf_32 data_buf(in.data, en, out.data);
	tribuf_n #(2) mode_buf(in.mode, en, out.mode);
endmodule

// mode = 2'b00 -> data_out = *(address + offset)
// mode = 2'b01 -> *(address + offset) <= data
// mode = 2'b10 -> data_out = malloc(offset)
// mode = 2'b11 -> zero_array_address <= address
module mem_sys(
	input mem_in_bus_t mem_bus,
	input clk,
	input reset,
	output reg [31:0] data_out
);
	reg [31:0] main_mem [33554431:0]; // gives 128MB ram 128/4*2^20
	reg [31:0] next_alloc;
	reg [31:0] zero_array_address;

	logic [31:0] real_address;

	always_comb
	case(mem_bus.address)
		32'b0: real_address = mem_bus.address + zero_array_address;
		default: real_address = mem_bus.address;
	endcase

	always_ff@(posedge clk iff reset == 0 or posedge reset)
	if (reset) begin
		main_mem <= '{default:32'b0};
		zero_array_address <= 32'b0;
		next_alloc <= 32'b10000;
	end else case(mem_bus.mode)
		2'b00: data_out <= main_mem[real_address + mem_bus.offset];
		2'b01: main_mem[real_address + mem_bus.offset] <= mem_bus.data;
		2'b10: begin
			data_out <= next_alloc;
			next_alloc <= next_alloc + mem_bus.offset;
		end
		2'b11: zero_array_address <= mem_bus.data;
	endcase
endmodule