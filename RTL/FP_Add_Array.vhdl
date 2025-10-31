library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all;

entity FP_Add_Array is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat_Array(INPUT_SIZE-1 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART downto 0)
    );
end entity;

architecture FP_Add_Array_serial_arch of FP_Add_Array is 
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
            else
            end if;
        end if;

    end process;

end architecture;

architecture FP_Add_Array_pararell_arch of FP_Add_Array is 
begin
    
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
            else
            end if;
        end if;

    end process;

end architecture;