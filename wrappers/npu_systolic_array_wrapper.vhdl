library ieee;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_systolic_array_wrapper is
    port (
        i_clk   : in std_logic;
        i_rstn  : in std_logic;
        i_clr   : in std_logic;
        i_w     : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH-1 downto 0);
        i_w_en  : in std_logic_vector(C_ARRAY_SIZE-1 downto 0);
        i_en    : in std_logic;
        i_data  : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH-1 downto 0);
        o_data  : out QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH-1 downto 0);
        o_en    : out std_logic
    );
end entity npu_systolic_array_wrapper;


architecture npu_systolic_array_wrapper_rtl of npu_systolic_array_wrapper is

begin

    u_npu_systolic_array : entity work.npu_systolic_array
        port map (
            i_clk  => i_clk,
            i_rstn => i_rstn,
            i_clr  => i_clr,
            i_w    => i_w,
            i_w_en => i_w_en,
            i_en   => i_en,
            i_data => i_data,
            o_data => o_data,
            o_en   => o_en
        );

end architecture npu_systolic_array_wrapper_rtl;