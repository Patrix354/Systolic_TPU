library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all; 
use work.npu_config.all;

entity npu_add is
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid : in std_logic;
        i_a     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_b     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat(C_DATA_WIDTH - 1 downto 0)
    );
end entity;

architecture npu_add_rtl of npu_add is 
    signal s_y  : QFormat(C_DATA_WIDTH downto 0);
    signal s_a  : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_b  : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_active : std_logic;
begin
    
    o_y <= s_y(C_DATA_WIDTH - 1 downto 0);

    process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_y <= (others => '0');
                s_b <= (others => '0');
                s_a <= (others => '0');
                o_ready <= '0';
                s_active <= '0';
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
                    s_y <= resize(s_a, C_DATA_WIDTH + 1) + resize(s_b, C_DATA_WIDTH + 1);    
                    o_ready <= '1';
                else
                    s_y <= s_y;    
                    o_ready <= '0';
                end if;
                
            end if;
        end if;

    end process;

end architecture;