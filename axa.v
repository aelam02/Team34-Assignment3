//Based on Dietz Solution for assembler
`define WORD[15:0] //size of instruciton

//Bits represented with instruciton
`define OP[15:10] //6 bits for Op code
`define INSSET[9:8] //2 bits for type of SRC
`define SRC[7:4] // 4 Bits for SRC
`define DEST[3:0] //4 Bits for DEST

//Bits represnted for Immediate 8 bits
`define IMMEDAITE[11:4] //8 bits for Immediate value
`define IMMOP[15:12] //4 bits for  Op code

`define STATE[6:0]
`define REGSIZE [15:0] //According to AXA
`define MEMSIZE [65536:0]

//Define OPcodes
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
`define OPshr  6'b010001
`define OPor   6'b010010
`define OPand  6'b010011
`define OPdup  6'b010100
`define OPfail 6'001111
`define OPxhi  6'b100001
`define OPxlo  6'b101001
`define OPlhi  6'b110001
`define OPllo  6'b111001
`define OPex2  6'b010101

`define OPjerr 6'b001110
`define OPland 6'b010000
`define OPcom  6'b000001

`define NOP    16'b0


module processor(halt, reset, clk);
output reg halt;
inputr reset, clk;


//reset
always @(reset) begin
end

//stage 0: instruction fetch
always @(posedge clk) begin
end

//stage 1: register read
always @(posedge clk) begin
end

//stage 2: data memory access
always @(posedge clk) begin
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
  $dumpvars(0, PE, PE.regfile[1], PE.regfile[2], PE.mainmem[4]);
  #10 reset = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 1;
    #10 clk = 0;
  end
  $finish;
end
endmodule
