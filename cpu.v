
//add lea 2's complement 


`timescale 1ps/1ps

//
// This is an inefficient implementation.
//   make it run correctly in less cycles, fastest implementation wins
//

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0);
    end

    //Clock
    wire clk;
    clock c0(clk);

   counter ctr(wb_isHalt && wb_valid, clk, wb_valid, );     //more ports?

   // PC
   reg [15:0]pc = 16'h0000;

   mem i0(clk, 
        f1_fetchEnable, f1_pc, r1_fetchOut, 
        r1_loadEnable, r1_loadAddr, x1_loadOut,
        x1_loadEnable, x1_loadAddr, wb_loadOut,  
        wb_memWriteEnable, wb_memWriteAddr, wb_memWriteData);
    

   regs rf(clk,
        r1_regSR1ReadEnable, r1_regSR1,  x1_regSR1Out,
        r1_regSR2ReadEnable, r1_regSR2, x1_regSR2Out, 
        wb_regWriteEnable, wb_regDR, wb_regWriteData);


   /******************
   ******Fetch 1******
   ******************/
   reg f1_valid = 1; 
   wire f1_fetchEnable = x1_isStall ? 0 : 1; 
   wire [15:0]f1_pc = pc;

   /******************
   ******Regs 1*******
   ******************/
   reg r1_valid = 0;
   reg [15:0]r1_pc = 0; 
   wire [15:0]r1_fetchOut; 
   wire [15:0]r1_instruction = r1_fetchOut; 
   wire r1_regSR1ReadEnable = x1_isStall ? 0 : 1; 
   wire r1_regSR2ReadEnable = x1_isStall ? 0 : 1; 
   wire [3:0]r1_opcode = r1_instruction[15:12]; 
   wire [2:0]r1_regSR1 = r1_isStore || r1_isStoreIndirect || r1_isStr ? r1_instruction[11:9] :
                         r1_instruction[8:6]; 
   wire [2:0]r1_regSR2 = r1_SR2_Add_And ? r1_instruction[2:0] : r1_instruction[8:6]; 
   wire [2:0]r1_regDR = r1_instruction[11:9]; //everything with DR uses these bits

   wire [8:0]r1_movImm = r1_instruction[8:0]; 
   wire [15:0]r1_addAndImm = r1_instruction[4:0]; 
   wire [8:0]r1_pcOffset = r1_instruction[8:0]; //change later for ldi, also only supports 0 sign numbers right now 
   wire [6:0]r1_ldrOffset = r1_instruction[6:0];   
   wire [6:0]r1_baseR = r1_instruction[8:6];

   wire r1_movImmSign = r1_instruction[8];
   wire r1_addAndImmSign = r1_instruction[4];
   wire r1_pcOffsetSign = r1_instruction[8];
   wire r1_ldrOffsetSign = r1_instruction[6]; 

   wire [15:0]r1_loadAddr = r1_pc + r1_pcOffset;  //change later for ldi
   wire r1_loadEnable = r1_isLd || r1_isLdi; 

   wire r1_isAdd = (r1_opcode == 1) && (r1_instruction[5] == 0); 
   wire r1_isAddImm = (r1_opcode == 1) && (r1_instruction[5] == 1);
   wire r1_isAnd = (r1_opcode == 5) && (r1_instruction[5] == 0); 
   wire r1_isAndImm = (r1_opcode == 5) && (r1_instruction[5] == 1); 
   wire r1_isNot = (r1_opcode == 9);
   wire r1_isLd = (r1_opcode == 2); 
   wire r1_isMovImm = (r1_opcode == 13);
   wire r1_isHalt = (r1_opcode == 15); 
   wire r1_isJump = (r1_opcode == 12);
   wire r1_isLea = (r1_opcode == 14);
   wire r1_isLdi = (r1_opcode == 10);
   wire r1_isLdr = (r1_opcode == 6); 
   wire r1_isStore = (r1_opcode == 3);
   wire r1_isStoreIndirect = (r1_opcode == 11);
   wire r1_isStr = (r1_opcode == 7); 
   wire r1_SR1_Add_And_Not = r1_isNot || r1_isAdd || r1_isAddImm || r1_isAnd || r1_isAndImm;
   wire r1_SR2_Add_And = r1_isAdd || r1_isAnd; 


   /******************
   *****Execute 1*****
   ******************/
   reg x1_valid = 0; 
   reg [15:0]x1_pc = 0;
   reg [15:0]x1_instruction = 0;
   reg [2:0]x1_regSR1 = 0;
   reg [2:0]x1_regSR2 = 0;
   wire [15:0]x1_regSR1Out;
   wire [15:0]x1_regSR2Out;  
   wire [15:0]x1_regSR1Val = x1_wbHazardSR1 ? wb_regWriteData :
                             x1_wbPreviousHazardSR1 ? wb_previousWriteData :
                             x1_regSR1Out; //more hazards
   wire [15:0]x1_regSR2Val = x1_wbHazardSR2 ? wb_regWriteData :
                             x1_wbPreviousHazardSR2 ? wb_previousWriteData :
                             x1_regSR2Out; 
   reg [2:0]x1_regDR = 0;

   wire [15:0]x1_loadOut; 
   wire [15:0]x1_loadAddr = x1_isLdr ? x1_regSR1Val + x1_ldrOffset : 
                            x1_isLdi ? x1_loadOut : 0;
   wire x1_loadEnable = x1_isLdr || x1_isLdi || x1_isStoreIndirect;
   //if wb_mem write addr = x1_loadaddr, hazard

   //reminder: check if_store in r1 to avoid picking up that 0
   wire [15:0]x1_storeAddr = x1_isStore ? x1_pc + x1_pcOffset : 0; 

   wire x1_loadHazard; 

   reg x1_isAdd = 0;
   reg x1_isAddImm = 0;
   reg x1_isAnd = 0;
   reg x1_isAndImm = 0;
   reg x1_isNot = 0;
   reg x1_isLd = 0;
   reg x1_isMovImm = 0;
   reg x1_isHalt = 0; 
   reg x1_isJump = 0;
   reg x1_isLea = 0;
   reg x1_isLdi = 0;
   reg x1_isLdr = 0; 
   reg x1_isStore = 0;
   reg x1_isStoreIndirect = 0;
   reg x1_isStr = 0; 

   reg x1_movImmSign = 0;
   reg x1_addAndImmSign = 0;
   reg x1_pcOffsetSign = 0;
   reg x1_ldrOffsetSign = 0;

   reg [8:0]x1_movImm = 0; 
   reg [4:0]x1_addAndImm = 0;   
   reg [6:0]x1_ldrOffset = 0; 
   reg [8:0]x1_pcOffset = 0;
   reg [2:0]x1_baseR = 0;    

   //Sign extending immediates
   wire [4:0]x1_addAndImmNegation = (~x1_addAndImm) + 1;
   wire [8:0]x1_movImmNegation = (~x1_movImm) + 1;
   wire [6:0]x1_ldrOffsetNegation = (~x1_ldrOffset) + 1; 
   wire [8:0]x1_pcOffsetNegation = (~x1_pcOffsetNegation) + 1; 

   wire [15:0]x1_addValue = x1_regSR1Val + x1_regSR2Val; 
   wire [15:0]x1_addImmValue = x1_addAndImmSign ? x1_regSR1Val - x1_addAndImmNegation : 
                               x1_regSR1Val + x1_addAndImm; 
   wire [15:0]x1_andValue = x1_regSR1Val & x1_regSR2Val;
   wire [15:0]x1_andImmValue = x1_addAndImmSign ? x1_regSR1Val & x1_addAndImmNegation : 
                               x1_regSR1Val & x1_addAndImm; 
   wire [15:0]x1_notValue = ~(x1_regSR1Val); 
   wire [15:0]x1_leaValue = x1_pc + x1_pcOffset; 

   //Check for hazards
   wire x1_wbPreviousHazardSR1 = (wb_previousWriteReg == x1_regSR1) && wb_previousRegWriteValid;
   wire x1_wbPreviousHazardSR2 = (wb_previousWriteReg == x1_regSR2) && wb_previousRegWriteValid;
   wire x1_wbHazardSR1 = (wb_regDR == x1_regSR1) && wb_isRegWrite && wb_valid;
   wire x1_wbHazardSR2 = (wb_regDR == x1_regSR2) && wb_isRegWrite && wb_valid;

   wire x1_wbPreviousHazardLoad = (wb_previousWriteMem == x1_loadAddr) && wb_previousMemWriteValid;
   wire x1_wbHazardLoad = (wb_memWriteAddr == x1_loadAddr) && wb_isMemWrite && wb_valid;
   wire [15:0]x1_hazardLoadVal = x1_wbPreviousHazardLoad ? wb_previousWriteMemData : 
                                 x1_wbHazardLoad ? wb_memWriteData : 0;

   //Ldr, ldi, and sti must stall due to writeback values being regs, not wires
   wire x1_isStall = x1_isLdr ? x1_valid && !x1_ldrReady : 
                     x1_isLdi ? x1_valid && !x1_ldiReady : 
                     x1_isStoreIndirect ? x1_valid && !x1_stiReady : 0; 

   /******************
   **Load mini cycle**
   ******************/ 
   wire [15:0]x1_ldrOut = wb_loadOut; 
   reg x1_ldrReady = 0; 
   reg x1_ldiReady = 0;
   reg x1_stiReady = 0; 


   /******************
   *****Writeback*****
   ******************/
   reg wb_valid = 0;
   reg [15:0]wb_pc = 0; 
   wire [15:0]wb_loadOut;
   reg wb_wasLoadHazard = 0;
   reg [15:0]wb_x1LoadVal = 0; 
   wire [15:0]wb_loadVal = wb_wasLoadHazard ? wb_x1LoadVal : wb_loadOut; 
   reg [15:0]wb_instruction;
   wire wb_regWriteEnable = wb_valid && wb_isRegWrite;  //change later
   wire wb_isRegWrite = wb_isLd || wb_isMovImm || wb_isAdd || wb_isAddImm || wb_isAnd || wb_isNot || wb_isLea || wb_isLdr || wb_isLdi;
   wire wb_memWriteEnable = wb_valid && wb_isMemWrite; 
   wire wb_isMemWrite = wb_isStore || wb_isStoreIndirect || wb_isStr;
   reg [2:0]wb_regDR = 0;
   reg [15:0]wb_regWriteData = 0; 
   reg [15:0]wb_regSR1Val = 0; 
   reg [15:0]wb_memWriteAddr = 0;
   reg [15:0]wb_memWriteData = 0; 
   reg [15:0]wb_memStiFirstVal = 0; 
   reg wb_isAdd = 0;
   reg wb_isAddImm = 0;
   reg wb_isAnd = 0;
   reg wb_isAndImm = 0;
   reg wb_isNot = 0;
   reg wb_isLd = 0;
   reg wb_isMovImm = 0;
   reg wb_isHalt = 0; 
   reg wb_isJump = 0;
   reg wb_isLea = 0;
   reg wb_isLdi = 0;
   reg wb_isLdr = 0; 
   reg wb_isStore = 0;
   reg wb_isStoreIndirect = 0;
   reg wb_isStr = 0; 

   reg [2:0]wb_previousWriteReg = 0;
   reg [15:0]wb_previousWriteData = 0; 
   reg wb_previousRegWriteValid = 0;
   reg [15:0]wb_previousWriteMem = 0;
   reg [15:0]wb_previousWriteMemData = 0;
   reg wb_previousMemWriteValid = 0;


   always @(posedge clk) begin

      if(x1_isStall) begin

         if(x1_isLdr)
            x1_ldrReady <= 1;

         else if(x1_isLdi)
            x1_ldiReady <= 1;

         else
            x1_stiReady <= 1; 

         wb_valid <= 0; 

      end

      else begin

      //Update pc
         pc <= (wb_isJump && wb_valid) ? wb_regSR1Val :  pc + 1;

      //Reset stalling bits
         x1_ldrReady <= 0;
         x1_ldiReady <= 0;
         x1_stiReady <= 0;

      //Update valid bits
         r1_valid <= (wb_isJump && wb_valid) ? 0 : f1_valid;
         x1_valid <= (wb_isJump && wb_valid) ? 0 : r1_valid;
         wb_valid <= (wb_isJump && wb_valid) ? 0 : x1_valid; 

      //Pass pc along pipeline
         r1_pc <= f1_pc;
         x1_pc <= r1_pc;
         wb_pc <= x1_pc; 

      //Hazards         
         wb_x1LoadVal <= x1_hazardLoadVal; 
         wb_wasLoadHazard <= x1_wbHazardLoad || x1_wbPreviousHazardLoad; 

      //Pass decode bits along pipeline
         x1_isAdd <= r1_isAdd;
         x1_isAddImm <= r1_isAddImm;
         x1_isAnd <= r1_isAnd;
         x1_isAndImm <= r1_isAndImm;
         x1_isNot <= r1_isNot;
         x1_isLd <= r1_isLd;
         x1_isMovImm <= r1_isMovImm;
         x1_isHalt <= r1_isHalt;
         wb_isAdd <= x1_isAdd;
         wb_isAddImm <= x1_isAddImm;
         wb_isAnd <= x1_isAnd;
         wb_isAndImm <= x1_isAndImm;
         wb_isNot <= x1_isNot;
         wb_isLd <= x1_isLd;
         wb_isMovImm <= x1_isMovImm;
         wb_isHalt <= x1_isHalt; 
         x1_isJump <= r1_isJump;
         x1_isLea <= r1_isLea;
         x1_isLdi <= r1_isLdi;
         x1_isLdr <= r1_isLdr; 
         x1_isStore <= r1_isStore;
         x1_isStoreIndirect <= r1_isStoreIndirect;
         wb_isJump <= x1_isJump;
         wb_isLea <= x1_isLea;
         wb_isLdi <= x1_isLdi;
         wb_isLdr <= x1_isLdr; 
         wb_isStore <= x1_isStore;
         wb_isStoreIndirect <= x1_isStoreIndirect;
         x1_isStr <= r1_isStr;  
         wb_isStr <= x1_isStr; 

      //Keep previous instruction for hazards
         wb_previousWriteReg <= wb_regDR;
         wb_previousWriteData <= wb_regWriteData; 
         wb_previousRegWriteValid <= wb_regWriteEnable; 
         wb_previousWriteMem <= wb_memWriteAddr;
         wb_previousWriteMemData <= wb_memWriteData;
         wb_previousMemWriteValid <= wb_memWriteEnable;

      //Pass various immediates/registers along pipeline
         x1_baseR <= r1_baseR; 
         x1_movImm <= r1_movImm; 
         x1_addAndImm <= r1_addAndImm; 
         x1_regSR1 <= r1_regSR1;
         x1_regSR2 <= r1_regSR2; 
         x1_regDR <= r1_regDR;
         wb_regDR <= x1_regDR;
         wb_regSR1Val <= x1_regSR1Val; 
         x1_instruction <= r1_instruction;
         wb_instruction <= x1_instruction; 
         x1_pcOffset <= r1_pcOffset; 
         x1_ldrOffset <= r1_ldrOffset; 

      //Signs for sign extending
         x1_movImmSign <= r1_movImmSign;
         x1_addAndImmSign <= r1_addAndImmSign;
         x1_pcOffsetSign <= r1_pcOffsetSign;
         x1_ldrOffsetSign <= r1_ldrOffsetSign;

      //Values and addresses for writeback
         wb_memWriteAddr <= x1_isStore ? x1_pcOffset + x1_pc :
                            x1_isStr ?  x1_ldrOffset + x1_regSR2Val :
                            x1_isStoreIndirect ? x1_ldrOut : 0; 
         wb_memWriteData <= x1_regSR1Val;

         wb_regWriteData <= x1_isLd ? x1_loadOut : 
                            x1_isMovImm ? x1_movImm :
                            x1_isAddImm ? x1_addImmValue : 
                            x1_isAdd ? x1_addValue : 
                            x1_isNot ? x1_notValue : 
                            x1_isLea ? x1_leaValue : 
                            x1_isLdr ? x1_ldrOut : 
                            x1_isLdi ? x1_ldrOut : 0;
         end 

   end


endmodule
