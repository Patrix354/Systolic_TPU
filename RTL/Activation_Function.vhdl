library ieee;
use ieee.std_logic_1164.all;

entity Activation_Function is
    generic (
        DATA_WIDTH : positive := 8;
        FUNC_TYPE  : string := "RELU"
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        data_in   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        valid_in  : in  std_logic;
        data_out  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        valid_out : out std_logic
    );
end entity Activation_Function;

architecture rtl of Activation_Function is
begin
    -- Architecture content goes here
end architecture rtl;