library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MAC_Cell is
    port (
        X : in std_logic;
        Y : out std_logic
    );
end entity;

architecture MAC_Cell_arch of MAC_Cell is 
begin
    Y <= not X;
end architecture;