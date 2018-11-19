
package BusTypes;
typedef struct {
    logic [31:0] address;
    logic [31:0] offset;
    logic [31:0] data;
    logic [1:0] mode;
} mem_in_bus_t;

typedef struct {
    logic [31:0] data;
    logic [2:0] sel;
    logic mode;
} reg_in_bus_t;

endpackage: BusTypes
