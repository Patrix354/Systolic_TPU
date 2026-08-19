library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_pe is
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_en    : std_logic;
        i_w_en  : in std_logic;
        i_w     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_x     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_y     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        o_x     : out QFormat(C_DATA_WIDTH - 1 downto 0);
        o_y     : out QFormat(C_DATA_WIDTH - 1 downto 0);
        o_en  : out std_logic
    );
end entity;

architecture npu_pe_rtl of npu_pe is 
    signal s_w : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_mul_out : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_mul_ready : std_logic;

    signal s_y : QFormat_Array(C_DATA_WIDTH - 1 downto 0)(C_DATA_WIDTH - 1 downto 0);
    signal s_y_out : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_x : QFormat_Array(C_DATA_WIDTH + 1 downto 0)(C_DATA_WIDTH - 1 downto 0);
    signal s_en : std_logic;

begin
    
  u_npu_mul : entity work.npu_mul(npu_mul_rtl)
        port map(
            i_clk => i_clk,
            i_rstn => i_rstn,
            i_valid => i_en,
            i_a => s_w,
            i_b => i_x,
            o_y => s_mul_out,
            o_ready => s_mul_ready
        );

    u_npu_add: entity work.npu_add(npu_add_rtl)
         port map(
             i_clk => i_clk,
             i_rstn => i_rstn,
             i_valid => s_mul_ready,
             i_a => s_y(C_DATA_WIDTH - 1),
             i_b => s_mul_out,
             o_y => s_y_out,
             o_ready => s_en
         );       

 process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_w <= (others => '0');
            else
                if(i_w_en = '1') then
                    s_w <= i_w;
                else
                    s_w <= s_w;
                end if;

                s_x(C_DATA_WIDTH + 1 downto 1) <= s_x(C_DATA_WIDTH downto 0);
                s_x(0) <= i_x;
                s_y(C_DATA_WIDTH - 1 downto 1) <= s_y(C_DATA_WIDTH - 2 downto 0);
                s_y(0) <= i_y;

                if(s_en = '1') then
                    o_en <= '1';
                    o_x <= s_x(C_DATA_WIDTH + 1);
                    o_y <= s_y_out;
                else
                    o_en <= '0';
                    o_x <= s_x(C_DATA_WIDTH + 1);
                    o_y <= s_y_out;
                end if;
            end if;
        end if;

    end process; 

end architecture;