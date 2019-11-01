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

reg wait1; //used to stall in stage 1
reg `WORD pc0, pc1, pc2; //Pipeline PC value
reg `WORD sext0, sext1; //Pipeline sign extended
reg `WORD ir0, ir1, ir2; //Pipeline IR
reg `WORD d1, d2; //Pipeline destination register
reg `WORD s1, s2; //Pipeline source

wire pendjb1, pendjb2; //Check for jump/branch
wire jb; //Is it a jump or branch?
wire zero, nzero, neg, nneg; //Checks jump/branch conditions
wire jbtaken; //Is the jump or branch taken?
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
  
function regscr;
input `WORD inst;
regscr = (inst `INSSET == `RegType);
endfunction

function imfour;
input `WORD inst;
imfour = (inst `INSSET == `I4Type);
endfunction

function atscr;
input `WORD inst;
atscr = (inst `INSSET == `SrcRegType);
endfunction

function atimfour;
input `WORD inst;
atimfour = (inst `INSSET == `Buffi4Type);
endfunction

function setsdest;
input `INST inst;
setsdest = (((inst `OP >= `OPadd) && (inst `OP < `OPjerr)) || ((inst `OP > `OPjerr) && (inst `OP <= `OPllo)));
endfunction

function usesdest;
input `INST inst;
usesdest = ((inst `OP == `OPadd) ||
          (inst `OP == `OPsub) ||
          (inst `OP == `OPxor) ||
          (inst `OP == `OPex) ||
          (inst `OP == `OProl) ||
          (inst `OP == `OPshr) ||
          (inst `OP == `OPor) ||
          (inst `OP == `OPand) ||
          (inst `OP == `OPbz) ||
          (inst `OP == `OPjz) ||
          (inst `OP == `OPbnz) ||
          (inst `OP == `OPjnz) ||
          (inst `OP == `OPbn) ||
          (inst `OP == `OPjn) ||
          (inst `OP == `OPbnn) ||
          (inst `OP == `OPjnn) ||
          (inst `OP == `OPxhi) ||
          (inst `OP == `OPxlo) ||
          (inst `OP == `OPlhi) ||
          (inst `OP == `OPllo));
endfunction

function usesscr;
input `WORD inst;
usesscr = ((!(inst `WORD)) && (((inst `OP > `OPcomm) && (inst `OP < `OPjerr)) || ((inst `OP > `OPland) && (inst `OP <= `OPllo))));
endfunction

assign pendjb1 = (ir1 `OP == `OPjz) || (ir1 `OP == `OPjnz)
|| (ir1 `OP == `OPjn) || (ir1 `OP == `OPjnn);
assign pendjb2 = (ir2 `OP == `OPjz) || (ir2 `OP == `OPjnz)
|| (ir2 `OP == `OPjn) || (ir2 `OP == `OPjnn);
assign jb = (ir2 `INSSET == 1); //1 if branch, 0 if jump
assign zero = (d2 == 0) && (ir2 `OP == `OPjz);
assign nzero = (d2 != 0) && (ir2 `OP == `OPjnz);
assign neg = (d2 < 0) && (ir2 `OP == `OPjn);
assign nneg = (d2 >= 0) && (ir2 `OP == `OPjnn);
assign jbtaken = zero || nzero || neg || nneg;

// sign-extended i4
assign sexi4 = {{12{ir[7]}}, (ir `SRC)};

assign pendpush = (ir1 `PUSHBIT) && (ir1 `OP != `OPland);

assign datadep = ((ir0 `DEST == ir1 `DEST) && (~pendjb1) && (ir0 != `NOP) && (ir1 != `NOP))
|| ((ir0 `DEST == ir2 `DEST) && (~pendjb2) && (ir0 != `NOP) && (ir2 != `NOP))
|| ((ir0 `SRC == ir1 `DEST) && (~pendjb1) && (ir0 != `NOP) && (ir1 != `NOP))
|| ((ir0 `SRC == ir2 `DEST) && (~pendjb2) && (ir0 != `NOP) && (ir2 != `NOP));

//stage 0: instruction fetch
always @(posedge clk) begin
  pc0 = (jb ? targetpc : pc);
  if(wait1) begin
    // blocked by stage 1: should not have a jump
    pc <=pc0;
  end else begin
    //not blocked by stage 1:
    ir = instmem[pc0];
    landpc <= lc; 
    lc <= pc;
    ir0 <= `NOP;
    if ((ir `OP != `OPjerr) || (ir `OP != `OPland) || (ir `OP != `OPcom) || (ir `OP != `OPfail)) 
    begin
        if (regscr(ir)) begin
          s1 <= regfile[ir `SRC]; targetpc <= regfile[ir `SRC];
        end else if (imfour(ir)) begin
          s1 <= sexi4; targetpc <= pc + sexi4;
        end else if (atscr(ir)) begin
          s1 <= datamem[ regfile[ir `SRC] ]; targetpc <= datamem[ regfile[ir `SRC] ];
        end else if (atimfour)
          s1 <= ustack[ usp - (ir `SRC)]; targetpc <= ustack[ usp - (ir `SRC)];
        end
        d1<= regfile[ir `DEST];
        ir0 <= ir;
    end
    pc <= pc0 + 1;
  end
  pc1 <= pc0;
end

//stage 1: register read
always @(posedge clk) begin
  if ((ir0 != `NOP) && setsdest(ir1) && ((usesdest(ir0) && (ir0 `DEST == ir1 `DEST)) || (usesscr(ir0) && (ir0 `SRC == ir1 `DEST)))) 
  begin
    // stall waiting for register value
    wait1 = 1;
    ir1 <= `NOP;
  end else begin
    // all good, get operands (even if not needed)
    wait1 = 0;
    d2 <=  regfile[ir0 `DEST];
    s2 <=  regfile[ir0 `SRC];
    ir2 <= ir1;
  end
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
    `Buffi4Type: begin s2 <= ustack[usp - s1[3:0]]; end
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
