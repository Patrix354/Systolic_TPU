library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_systolic_array_delay is
  port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_en : in std_logic_vector(C_ARRAY_SIZE-1 downto 0);
        i_data : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_data : out QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_en : out std_logic_vector(C_ARRAY_SIZE-1 downto 0)
  ) ;
end npu_systolic_array_delay ;

architecture npu_systolic_array_delay_rtl of npu_systolic_array_delay is

begin

    gen_delay : for i in 0 to C_ARRAY_SIZE - 1 generate
        u_npu_dly : entity work.npu_delay(npu_delay_rtl)
            generic map (
                G_DELAY => C_PE_LATENCY * i
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_en => i_en(i),
                i_data => i_data(i),
                o_en => o_en(i),
                o_data => o_data(i)
            );
    end generate ; -- gen_delay

end architecture ; -- arch