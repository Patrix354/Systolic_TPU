library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.npu_types.all;
use work.npu_config.all;

entity npu_sram_wrapper is
    port (
        -- Port A
        i_clk_a  : in  std_logic;
        i_rstn_a : in  std_logic;
        i_en_a   : in  std_logic;
        i_we_a   : in  std_logic;
        i_addr_a : in  std_logic_vector(C_SRAM_ADDR_WIDTH - 1 downto 0);
        i_data_a : in  std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
        o_data_a : out std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);

        -- Port B
        i_clk_b  : in  std_logic;
        i_rstn_b : in  std_logic;
        i_en_b   : in  std_logic;
        i_we_b   : in  std_logic;
        i_addr_b : in  std_logic_vector(C_SRAM_ADDR_WIDTH - 1 downto 0);
        i_data_b : in  std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
        o_data_b : out std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0)
    );
end entity npu_sram_wrapper;

architecture npu_sram_wrapper_rtl of npu_sram_wrapper is
begin

    u_npu_sram : entity work.npu_sram(npu_sram_behav)
        port map (
            -- Port A
            clk_a      => i_clk_a,
            rstn_a     => i_rstn_a,
            en_a       => i_en_a,
            we_a       => i_we_a,
            addr_a     => i_addr_a,
            data_a_in  => i_data_a,
            data_a_out => o_data_a,

            -- Port B
            clk_b      => i_clk_b,
            rstn_b     => i_rstn_b,
            en_b       => i_en_b,
            we_b       => i_we_b,
            addr_b     => i_addr_b,
            data_b_in  => i_data_b,
            data_b_out => o_data_b
        );

end architecture npu_sram_wrapper_rtl;