library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package npu_types is

    subtype QFormat is signed;
    type QFormat_Array is array (natural range <>) of signed;


end package npu_types;
