-- File: /home/laura/Documents/Magisterka/mac-cell/RTL/FP_Acc.vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Acc is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8);
    port (
        i_clk  : in std_logic;
        i_rstn : in std_logic;
        i_en   : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
    
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0)
    );
end entity FP_Acc;

architecture FP_Acc_arch of FP_Acc is

    constant s_fractional_zeros : std_logic_vector((OUT_FRACTIONAL_PART - IN_FRACTIONAL_PART - 1) downto 0) := 
    (others => '0'); 
    constant s_integer_zeros : std_logic_vector((OUT_INTEGER_PART - IN_INTEGER_PART - 1) downto 0) := 
    (others => '0'); 
    constant s_integer_ones : std_logic_vector((OUT_INTEGER_PART - IN_INTEGER_PART - 1) downto 0) := 
    (others => '1'); 
    

begin


    s_data <= (s_integer_zeros & std_logic_vector(i_data) & s_fractional_zeros) when 
    i_data(IN_INTEGER_PART+IN_FRACTIONAL_PART-1)='0' else
    (s_integer_ones & std_logic_vector(i_data) & s_fractional_zeros);

end architecture rtl;