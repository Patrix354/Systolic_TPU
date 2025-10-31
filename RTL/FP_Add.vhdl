library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all; 

entity FP_Add is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART downto 0)
    );
end entity;

architecture FP_Add_arch of FP_Add is 
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                o_y <= (others => '0');
            else
                o_y <= resize(i_a, INTEGER_PART + FRACTIONAL_PART + 1)
                    + resize(i_b, INTEGER_PART + FRACTIONAL_PART + 1);
            end if;
        end if;

    end process;

end architecture;