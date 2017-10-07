----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: (c) Rajesh Panicker
--
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
--
-- Dependencies: NIL
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Decoder is port(
    Rd         : in 	std_logic_vector(3 downto 0);
    Op         : in 	std_logic_vector(1 downto 0);
    Funct      : in 	std_logic_vector(5 downto 0);
    PCS        : out	std_logic;
    RegW       : out	std_logic;
    MemW       : out	std_logic;
    MemtoReg   : out	std_logic;
    ALUSrc     : out	std_logic;
    ImmSrc     : out	std_logic_vector(1 downto 0);
    RegSrc     : out	std_logic_vector(1 downto 0);
    NoWrite    : out	std_logic;
    ALUControl : out	std_logic_vector(1 downto 0);
    FlagW      : out	std_logic_vector(1 downto 0)
);
end Decoder;

architecture Decoder_arch of Decoder is
    signal ALUOp 			   : std_logic_vector (1 downto 0);
    signal Branch 			   : std_logic;
    signal RdEquals15          : std_logic;
    signal RegWInternal       : std_logic;
    signal MemWInternal       : std_logic;
    signal FlagWInternal      : std_logic_vector (1 downto 0);
    signal IllegalMainDecoder : std_logic;
    signal IllegalALUDecoder  : std_logic;
    signal IllegalInstruction : std_logic;

begin

    -- Logic for Main Decoder
    main_decoder: process (Op, Funct)
    begin
        IllegalMainDecoder <= '0';  -- Legal by default.

        case Op is
           -- Branch Instruction
           when "10" =>
               Branch <= '1';
               MemtoReg <= '0';
               MemWInternal <= '0';
               ALUSrc <= '1';
               ImmSrc <= "10";
               RegWInternal <= '0';
               RegSrc <= "-1";
               ALUOp <= "11"; -- ADD always

           -- Memory Instruction
           when "01" =>
               Branch <= '0';
               ALUSrc <= '1';
               ImmSrc <= "01";
               if Funct(3) = '0' then -- U bit '0'
                ALUOp <= "10"; -- LDR/STR with Negative offset
               else
                ALUOp <= "11"; -- LDR/STR with Positive offset
               end if;

               -- STR Instruction
               if Funct(0) = '0' then
                   MemtoReg <= '-';
                   MemWInternal <= '1';
                   RegWInternal <= '0';
                   RegSrc <= "10";
               -- LDR Instruction
               else
                   MemtoReg <= '1';
                   MemWInternal <= '0';
                   RegWInternal <= '1';
                   RegSrc <= "-0";
               end if;

           -- Data Processing Instruction
           when "00" =>
               Branch <= '0';
               MemtoReg <= '0';
               MemWInternal <= '0';
               RegWInternal <= '1';
               ALUOp <= "00";

               -- DP Reg Instruction
               if Funct(5) = '0' then
                   ALUSrc <= '0';
                   ImmSrc <= "--";
                   RegSrc <= "00";
               -- DP Imm Instruction
               else
                   ALUSrc <= '1';
                   ImmSrc <= "00";
                   RegSrc <= "-0";
               end if;

           -- Invalid Op
           when others =>
               Branch <= '-';
               MemtoReg <= '-';
               MemWInternal <= '-';
               ALUSrc <= '-';
               ImmSrc <= "--";
               RegWInternal <= '-';
               RegSrc <= "--";
               ALUOp <= "--";
               IllegalMainDecoder <= '1';
        end case;
    end process;

    -- Logic for ALU Decoder
    alu_decoder: process (ALUOp, Funct) begin
        IllegalALUDecoder <= '0';  -- Legal by default.
        case ALUOp is
            -- Not a DP Instruction
            when "11" =>          -- LDR/STR with Positive offset; and Branch instruction
                FlagWInternal <= "00";
                NoWrite <= '0';
                ALUControl <= "00";
            when "10" =>          -- LDR/STR with Negative offset
                FlagWInternal <= "00";
                NoWrite <= '0';
                ALUControl <= "01";

            -- ALU operations for DP instructions
            when "00" =>
                NoWrite <= '0';  -- Should write by default.
                if Funct(0) = '0' then
                    FlagWInternal <= "00";
                else
                    -- N and Z flags
                    if Funct(4 downto 1) = "0100" or -- ADD
                       Funct(4 downto 1) = "0010" or -- SUB
                       Funct(4 downto 1) = "1010" then -- CMP
                        FlagWInternal(0) <= '1';
                    else
                        FlagWInternal(0) <= '0';
                    end if;

                    -- C and V flags
                    if Funct(4 downto 1) = "0100" or -- ADD
                       Funct(4 downto 1) = "0010" or -- SUB
                       Funct(4 downto 1) = "0000" or -- AND
                       Funct(4 downto 1) = "1100" or -- ORR
                       Funct(4 downto 1) = "1010" then -- CMP
                        FlagWInternal(1) <= '1';
                    else
                        FlagWInternal(1) <= '0';
                    end if;
                end if;

                case Funct (4 downto 1) is
                    -- ADD Instruction
                    when "0100" =>
                        ALUControl <= "00";
                    -- SUB Instruction
                    when "0010" =>
                        ALUControl <= "01";
                    -- AND Instruction
                    when "0000" =>
                        ALUControl <= "10";
                    -- ORR Instruction
                    when "1100" =>
                        ALUControl <= "11";
                    -- CMP Instruction
                    when "1010" =>
                        if Funct(0)='1' then
                            NoWrite <= '1';
                            ALUControl <= "01";
                        else  -- Illegal CMP
                            NoWrite <= '-';
                            ALUControl  <= "--";
                            FlagWInternal <= "--";
                            IllegalALUDecoder <= '1';
                        end if;
                    when others =>
                        NoWrite <= '-';
                        ALUControl  <= "--";
                        FlagWInternal <= "--";
                        IllegalALUDecoder <= '1';
                end case;
            when others =>
                NoWrite <= '-';
                ALUControl  <= "--";
                FlagWInternal <= "--";
                IllegalALUDecoder <= '1';
        end case;
    end process;

    -- PC Logic
    pc_logic: process (Rd, RdEquals15, RegWInternal, Branch, IllegalInstruction) begin
        if Rd = "1111" then
            RdEquals15 <= '1';
        else
            RdEquals15 <= '0';
        end if;
        PCS <= ((RdEquals15 and RegWInternal) or Branch) and (not IllegalInstruction);
    end process;

    IllegalInstruction <= IllegalMainDecoder or IllegalALUDecoder;

    -- If instruction is illegal, don't write any values
    RegW <= RegWInternal and (not IllegalInstruction);
    MemW <= MemWInternal and (not IllegalInstruction);
    FlagW <= FlagWInternal when (IllegalInstruction = '0') else "00";

end Decoder_arch;
