library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all; 

entity Activation_Function is
    generic (
        DATA_WIDTH : integer := 8
    );
    port (
        i_clk       : in  std_logic;
        i_rstn       : in  std_logic;
        i_data   : in  signed(DATA_WIDTH - 1 downto 0);
        i_valid  : in  std_logic;
        o_data  : out signed(DATA_WIDTH - 1 downto 0);
        o_ready : out std_logic
    );
end entity Activation_Function;

architecture ReLU of Activation_Function is
    signal s_data  : signed(DATA_WIDTH - 1 downto 0);
begin
    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_data <= (others => '0');
                o_ready <= '0';
            else
                if i_valid = '1' then
                    if i_data(DATA_WIDTH - 1) = '1' then
                        s_data <= (others => '0');
                        o_ready <= '1';
                    else
                        s_data <= i_data;
                        o_ready <= '1';
                    end if;
                else
                    o_ready <= '0';
                    s_data <= s_data;
                end if;
            end if;
        end if;
    end process;

    o_data <= s_data;

end architecture ReLU;