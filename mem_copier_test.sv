
import BusTypes::mem_in_bus_t;

module mem_copier_test();
	reg clk;
	reg reset_mem;
	wire [31:0] mem_data_out;
	reg enable_manual;
	wire enable_copier;
	wire copier_finished;
	
	reg [31:0] copier_src;
	reg [31:0] copier_dest;
	reg [31:0] copier_length;
	
	assign enable_copier = !enable_manual;

	
	mem_in_bus_t manual_mem_in;
	mem_in_bus_t copier_mem_in;
	mem_in_bus_t mem_in;
	
	mem_in_bus_buf m_buf(manual_mem_in, enable_manual, mem_in);
	mem_in_bus_buf c_buf(copier_mem_in, enable_copier, mem_in);
	
	mem_sys ms(mem_in, clk, reset_mem, mem_data_out);
	
	mem_copier mc(copier_src, copier_length, copier_dest,
		mem_data_out,
		clk, enable_copier,
		copier_mem_in,
		copier_finished
	);
	
	initial begin
		enable_manual <= 1;
		clk <= 0;
		reset_mem <= 1;
		
		#10
		
		reset_mem <= 0;
		manual_mem_in.data = 32'b1;
		manual_mem_in.mode = 2'b01;
		manual_mem_in.offset = 32'b0;
		manual_mem_in.address = 32'h5555;
		
		#10
		
		manual_mem_in.data = 32'd2;
		manual_mem_in.offset = 32'd1;
		
		#10
		
		manual_mem_in.data = 32'd3;
		manual_mem_in.offset = 32'd2;
		
		#10
		
		manual_mem_in.data = 32'd4;
		manual_mem_in.offset = 32'd3;
		
		#10
		
		copier_src <= 32'h5555;
		copier_length <= 3; // should not copy the 4th element (4)
		copier_dest = 32'h5570;
		
		#10
		
		enable_manual <= 0;
	end
	
	always begin
		#5
		clk = ~clk;
	end
endmodule