library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Types is

    subtype QFormat is signed;
    type QFormat_Array is array (natural range <>) of signed(4 downto 0);

end package Types;