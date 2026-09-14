library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.npu_config.all;

package npu_types is

    subtype QFormat is signed;
    type QFormat_Array is array (natural range <>) of signed;

    type t_SRAM_input is record 
        en : std_logic;
        we : std_logic;
        addr : std_logic_vector(C_SRAM_ADDR_WIDTH - 1 downto 0);
        data_in : std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
    end record t_SRAM_input;

    type t_SRAM_output is record 
        data_out : std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
    end record t_SRAM_output;
    
end package npu_types;
