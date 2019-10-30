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

//Miscellaneous definitions
`define STATE[6:0]
`define REGSIZE [15:0] //According to AXA
`define MEMSIZE [65536:0]
`define USIZE [15:0] //Undo stack size
`define INDEX [3:0] //Undo stack index
`define RegType    2'b00
`define I4Type     2'b01
`define SrcRegType 2'b10
`define Buffi4Type 2'b11

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
reg `DATA ustack `USIZE; //Undo stack
reg `INDEX usp; //Undo stack pointer
reg `WORD ir; //Instruction Register

reg `WORD pc0, pc1, pc2; //Pipeline PC value
reg `WORD sext0, sext1; //Pipeline sign extended
reg `WORD ir0, ir1, ir2; //Pipeline IR
reg `WORD d1, d2; //Pipeline destination register
reg `WORD s1, s2; //Pipeline source

wire pendjb1, pendjb2; //Check for jump/branch
wire jb; //Is it a jump or branch?
wire zero, nzero, neg, nneg; //Checks jump/branch conditions
wire pendpush; //Checks if instruction pushes to undo stack
wire datadep; //Checks if there's a data dependency

//reset
always @(reset) begin
  halt <= 0;
  pc <= 0;
  usp <= 0;
  targetpc <= 0; landpc <= 0; lc <= 0;
  pc0 <= 0; pc1 <= 0; pc2 <= 0;
  sext0 <= 0; sext1 <= 10;
  ir0 <= `NOP; ir1 <= `NOP; ir2 <= `NOP;
  d1 <= 0; d2 <= 0;
  s1 <= 0; s2 <= 0;
  $readmemh0(regfile);
  $readmemh1(datamem);
  $readmemh2(instmem);
  $readmemh3(ustack);
end

assign pendjb1 = (ir1 `OP == `OPjz) || (ir1 `OP == `OPjnz)
|| (ir1 `OP == `OPjn) || (ir1 `OP == `OPjnn);
assign pendjb2 = (ir2 `OP == `OPjz) || (ir2 `OP == `OPjnz)
|| (ir2 `OP == `OPjn) || (ir2 `OP == `OPjnn);
assign jb = (ir2 `INSSET == 1); //1 if branch, 0 if jump
assign zero = (d2 == 0) && (ir2 `OP == `OPjz);
assign nzero = (d2 != 0) && (ir2 `OP == `OPjnz);
assign neg = (d2 < 0) && (ir2 `OP == `OPjn);
assign nneg = (d2 >= 0) && (ir2 `OP == `OPjnn);
assign pendpush = (ir1 `PUSHBIT) && (ir1 `OP != `OPland);
assign datadep = ((ir0 `DEST == ir1 `DEST) && (~pendjb1))
|| ((ir0 `DEST == ir2 `DEST) && (~pendjb2)); //Finish this later

//stage 0: instruction fetch
always @(posedge clk) begin
end

//stage 1: register read
always @(posedge clk) begin
end

//stage 2: data memory access
always @(posedge clk) begin
  if(ir1 `OP == `OPex) begin
    d2 <= datamem[s1];
    datamem[s1] <= d1;
  end else begin
    d2 <= d1;
  end

  case (ir1 `INSSET)
    `RegType: begin s2 <= s1; end
    `I4Type: begin s2 <= sext1; end
    `SrcRegType: begin s2 <= datamem[s1]; end
    `Buffi4Type: begin s2 <= ustack[s1[3:0]]; end
  endcase

  if(pendpush) begin
    if(usp == 0) begin
      ustack[usp] <= d1;
      usp <= usp + 1;
    end else begin
      ustack[usp + 1] <= d1;
      usp <= usp + 1;
    end
  end
  pc2 <= pc1;
  ir2 <= ir1;
  halt <= 1;
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
