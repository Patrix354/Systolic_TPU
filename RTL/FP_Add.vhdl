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
        i_valid : in std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
    );
end entity;

architecture FP_Add_arch of FP_Add is 
    signal s_y  : QFormat(INTEGER_PART + FRACTIONAL_PART downto 0);
    signal s_a  : QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_b  : QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
    signal s_active : std_logic;
begin
    
    o_y <= s_y(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_y <= (others => '0');
                s_b <= (others => '0');
                s_a <= (others => '0');
            else
                if i_valid = '1' then
                    s_a <= i_a;
                    s_b <= i_b;
                    s_active <= '1';
                else
                    s_a <= s_a;
                    s_b <= s_b;
                    s_active <= '0';
                end if;

                if s_active = '1' then
                    s_y <= resize(s_a, INTEGER_PART + FRACTIONAL_PART + 1) + resize(s_b, INTEGER_PART + FRACTIONAL_PART + 1);    
                    o_ready <= '1';
                else
                    s_y <= s_y;    
                    o_ready <= '0';
                end if;
                
            end if;
        end if;

    end process;

end architecture;