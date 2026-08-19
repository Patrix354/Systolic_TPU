library ieee;
use ieee.std_logic_1164.all;

package npu_config is
   
    constant C_INTEGER_PART  : positive := 4;
    constant C_FRACTIONAL_PART  : positive := 4;
    
    constant C_DATA_WIDTH   : positive := C_INTEGER_PART + C_FRACTIONAL_PART;
    constant C_ARRAY_SIZE   : positive := 3;

end package npu_config;