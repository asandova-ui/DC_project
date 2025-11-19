//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////  			  RV32IM extension: Multiply & Divide instructions
////						arithmethic modules
////						Multiplier module extracted from laRVa.v
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
///////////////////////////////////////////////
// 	Multiplier: shift-reg, 4 bits/cycle
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

always @(posedge clk or posedge reset)
	if (reset) {oua,oa} <= 0;
	else if (load) {oua,oa} <= {ua,a};

always @(posedge clk or posedge reset)
	if (reset) {oub,ob} <= 0;
	else if (load) {oub,ob} <= {ub,b};

// internal load if needed
wire iload = load & ( ({oa,ob} != {a,b}) | (hm & ({oua,oub} != {ua,ub})) );

// make multiplicand positive (truco de signo del diseño original)
wire sma = (~ua) & a[31];       // signed multiplier
wire [31:0]ma = (sma ? (~a) : a) + sma;	// change sign if needed
wire [31:0]mb = (sma ? (~b) : b) + sma;	// change sign if needed

// ---------------------------------------------------------------------------
//  SHA: registro desplazante del multiplicador (32 bits)
//       Ahora procesamos 4 bits (un nibble) por ciclo.
// ---------------------------------------------------------------------------
reg [31:0]sha = 0;
always @(posedge clk or posedge reset) begin
	if (reset)
		sha <= 0;
	else
		sha <= iload ? ma : {4'b0, sha[31:4]};  // shift right 4 bits
end

// busy mientras haya nibbles pendientes o estemos cargando
assign busy = iload | (|sha);

// ---------------------------------------------------------------------------
//  SHB: multiplicando de 64 bits, sign/zero extendido
//       Se desplaza 4 bits a la izquierda cada ciclo.
// ---------------------------------------------------------------------------
reg [63:0]shb;
always @(posedge clk) begin
	shb <= iload ? { ub ? 32'b0 : {32{mb[31]}}, mb } :
	               { shb[59:0], 4'b0 };   // shift left 4 bits
end

// nibble actual del multiplicador
wire [3:0] nib = sha[3:0];

// producto parcial de este ciclo: multiplicando * nibble
// El operador '*' infiere un multiplicador dedicado en la FPGA.
wire [63:0] pp = shb * nib;

// ---------------------------------------------------------------------------
//  ACC: acumulador del producto (64 bits)
// ---------------------------------------------------------------------------
reg [63:0]acc;
always @(posedge clk or posedge reset) begin
	if (reset)
		acc <= 0;
	else if (iload)
		// inicio de una nueva multiplicación
		acc <= 0;
	else if (|sha)
		// mientras queden nibbles por procesar, acumulamos pp
		acc <= acc + pp;
end

// selección de mitad alta o baja del producto
assign out = hm ? acc[63:32] : acc[31:0];

endmodule
