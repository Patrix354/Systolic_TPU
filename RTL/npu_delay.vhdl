library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_delay is
    generic (
        G_DELAY : natural := 8
    );
    port (
    i_clk   : in std_logic;
    i_rstn   : in std_logic;
    i_en : in std_logic;
    i_data : in QFormat(C_DATA_WIDTH - 1 downto 0);
    o_data : out QFormat(C_DATA_WIDTH - 1 downto 0);
    o_en : out std_logic
  );
end npu_delay;

architecture npu_delay_rtl of npu_delay is

    signal s_data_delay_pipe : QFormat_Array(G_DELAY downto -1)(C_DATA_WIDTH - 1 downto 0);
    signal s_en_delay_pipe : std_logic_vector(G_DELAY downto -1);

begin

    seq_proc : process( i_clk )
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                for i in -1 to G_DELAY loop
                    s_data_delay_pipe(i) <= (others => '0');
                end loop;

                s_en_delay_pipe <= (others => '0');
            else
                for i in 0 to G_DELAY - 1 loop
                    s_data_delay_pipe(i+1) <= s_data_delay_pipe(i);
                end loop; 

                for i in 0 to G_DELAY - 1 loop
                    s_en_delay_pipe(i+1) <= s_en_delay_pipe(i);
                end loop;

                s_en_delay_pipe(0) <= i_en;
                s_data_delay_pipe(0) <= i_data;
            end if;
        end if;
    end process; -- seq_proc 

    comb_proc : process( all )
    begin
        o_data <= i_data when G_DELAY = 0 else s_data_delay_pipe(G_DELAY - 1);
        o_en <= i_en when G_DELAY = 0 else s_en_delay_pipe(G_DELAY - 1);

    end process ; -- comb_proc

end architecture ; -- npu_delay_rtl