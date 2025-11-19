//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////  			  RV32IM extension: Multiply & Divide instructions
////						arithmethic modules
////						Multiplier module extracted from laRVa.v
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
///////////////////////////////////////////////
// 	Multiplier: simple shift-reg, 1 cycle/bit
///////////////////////////////////////////////
///////////////////////////////////////////////

module multiplier (
	input  clk,
	input  reset,		// async. reset
	input  [31:0]a,		// Multiplier (rs2)
	input  [31:0]b,		// Multiplicand (rs1)
	input  ua,			// unsigned multiplier
	input  ub,			// unsigned multiplicand
	input  hm,			// return high word (bits 63:32)
	input  load,		// load strobe
	output busy,		// doing processing while 1
	output [31:0]out	// output result
);

// last multiplication data
reg [31:0]oa;
reg [31:0]ob;
reg oua;
reg oub;
always @(posedge clk or posedge reset) if (reset) {oua,oa}<=0; else if (load) {oua,oa}<={ua,a};
always @(posedge clk or posedge reset) if (reset) {oub,ob}<=0; else if (load) {oub,ob}<={ub,b};

// internal load if needed
wire iload = load & ( ({oa,ob}!={a,b}) | (hm & ({oua,oub}!={ua,ub})));

// make multiplicand positive
wire sma = (~ua)&a[31];	// signed multiplier
wire [31:0]ma = (sma ? (~a) : a) +sma;	// change sign if needed
wire [31:0]mb = (sma ? (~b) : b) +sma;	// change sign if needed

// shift operands	
reg [31:0]sha=0;
always @(posedge clk or posedge reset) 
	if (reset) sha<=0; else sha<= iload ? ma : {1'b0,sha[31:1]};
assign busy=iload |(|sha);

reg [63:0]shb;
always @(posedge clk) shb<= iload ? { ub ? 32'b0 : {32{mb[31]}},mb} : 
							{shb[62:0],1'b0};

// accumulator
reg [63:0]acc;
always @(posedge clk or posedge reset)
	if (reset) acc<=0;
	else if (iload | sha[0]) acc <= iload ? 0 : acc + shb;

assign out= hm ? acc[63:32] : acc[31:0];
endmodule