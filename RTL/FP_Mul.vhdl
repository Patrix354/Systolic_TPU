library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FP_Mul is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in signed(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in signed(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

        o_y     : out signed( 2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0)
    );
end entity;

architecture FP_Mul_arch of FP_Mul is 
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                o_y <= (others => '0');
            else
                o_y <= i_a * i_b;
            end if;
        end if;

    end process;

end architecture;