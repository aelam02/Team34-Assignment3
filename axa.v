//Based on Dietz Solution for assembler
`define WORD[15:0] //size of instruciton
`define DATA[15:0] //size of data
`define ADDR[15:0] //size of address

//Bits represented with instruciton
`define OP[15:10] //6 bits for Op code
`define INSSET[9:8] //2 bits for type of SRC
`define SRC[7:4] // 4 Bits for SRC
`define DEST[3:0] //4 Bits for DEST
`define PUSHBIT[14] //Bit 14 represents non-reversible instructions

//Bits represnted for Immediate 8 bits
`define IMMEDAITE[11:4] //8 bits for Immediate value
`define IMMOP[15:12] //4 bits for  Op code

`define STATE[6:0]
`define REGSIZE [15:0] //According to AXA
`define MEMSIZE [65536:0]
`define USIZE [15:0] //Undo stack size
`define INDEX [3:0] //Undo stack index

//Define OPcodes
//Op values
`define OPsys  6'b000000
`define OPcom  6'b000001
`define OPadd  6'b000010
`define OPsub  6'b000011
`define OPxor  6'b000100
`define OPex   6'b000101
`define OProl  6'b000110
`define OPbz   6'b001000
`define OPbnz  6'b001001
`define OPbn   6'b001010
`define OPbnn  6'b001011
`define OPjz   `OPbz
`define OPjnz  `OPbnz
`define OPjn   `OPbn
`define OPjnn  `OPbnn
`define OPjerr 6'b001110
`define OPfail 6'b001111
`define OPland 6'b010000
`define OPshr  6'b010001
`define OPor   6'b010010
`define OPand  6'b010011
`define OPdup  6'b010100
`define OPxhi  6'b100000
`define OPxlo  6'b101000
`define OPlhi  6'b110000
`define OPllo  6'b111000

`define NOP    16'hffff

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `DATA regfile `REGSIZE; //Register file
reg `DATA datamem `MEMSIZE; //Data memory
reg `WORD instmem `MEMSIZE; //Instruction memory
reg `ADDR pc; //Program Counter
reg `ADDR targetpc, landpc, lc; //Target PC, Landing PC, Current PC
reg `STATE s; //State
reg `DATA ustack `USIZE; //Undo stack
reg `INDEX usp; //Undo stack pointer
reg `WORD ir; //Instruction Register

reg `WORD pc0, pc1, pc2; //Pipeline PC value
reg `WORD sext0, sext1, sext2; //Pipeline sign extended
reg `WORD ir0, ir1, ir2; //Pipeline IR
reg `WORD d1, d2; //Pipeline destination register
reg `WORD s1, s2; //Pipeline source

wire pendjb; //Check for jump/branch
wire jb; //Is it a jump or branch?
wire zero, nzero, neg, nneg; //Checks jump/branch conditions
wire pendpush; //Checks if instruction pushes to undo stack

assign pendjb = (ir2 `OP == `OPjz) || (ir2 `OP == `OPjnz) || (ir2 `OP == `OPjn) || (ir2 `OP == `OPjnn);
assign jb = (ir2 `INSSET == 1); //1 if branch, 0 if jump
assign zero = (d2 == 0);
assign nzero = (d2 != 0);
assign neg = (d2 < 0);
assign nneg = (d2 >= 0);
assign pendpush = (ir2 `OP == `OPlhi) || (ir2 `OP == `OPllo) || (ir2 `OP == `OPshr) ||

//reset
always @(reset) begin
  halt = 0;
  pc = 0;
  ir0 = `NOP;
  ir1 = `NOP;
  ir2 = `NOP;
end

//stage 0: instruction fetch
always @(posedge clk) begin
end

//stage 1: register read
always @(posedge clk) begin
end

//stage 2: data memory access
always @(posedge clk) begin
  s2 <= datamem[s1];
  if(ir1 `OP == `OPex) begin
    d2 <= datamem[s1];
    datamem[s1] <= d1;
  end else begin
    d2 <= d1;
  end
  ir2 <= ir1;
end

//stage 3: ALU op and register write
always @(posedge clk) begin
end

endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
  $dumpfile;
  $dumpvars(0, PE);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
