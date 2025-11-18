library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Extender_array is
    generic (
        INPUT_SIZE          : integer := 4;
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_a     : in QFormat_Array(INPUT_SIZE - 1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat_Array(INPUT_SIZE - 1 downto 0)(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - 1 downto 0)
    );
end entity FP_Extender_array;

architecture FP_Extender_array_arch of FP_Extender_array is
begin
    
    EXTENDER_GEN : for i in 0 to INPUT_SIZE - 1 generate
        EXT_INST: FP_Extender 
        generic map (
            IN_INTEGER_PART     => IN_INTEGER_PART;
            IN_FRACTIONAL_PART  => IN_FRACTIONAL_PART;
            OUT_INTEGER_PART    => OUT_INTEGER_PART;
            OUT_FRACTIONAL_PART => OUT_FRACTIONAL_PART
        )
        port map (
            i_a => i_a(i),
            o_y => o_y(i)
        )
    end generate EXTENDER_GEN;
    
end architecture FP_Extender_array_arch;