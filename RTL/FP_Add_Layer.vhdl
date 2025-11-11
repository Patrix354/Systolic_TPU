library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all;


entity FP_Add_Layer is
    generic (
        INTEGER_PART    : integer := 8;
        FRACTIONAL_PART : integer := 8;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat_Array(INPUT_SIZE - 1 downto 0)((INTEGER_PART + FRACTIONAL_PART - 1) downto 0);
        o_y     : out QFormat_Array((INPUT_SIZE / 2) - 1 downto 0)((INTEGER_PART + FRACTIONAL_PART - 1) downto 0)
    );
end entity;

architecture FP_Add_Layer_arch of FP_Add_Layer is 

    component FP_Add is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
    );
    end component;

begin
     LAYER_GEN: for i in 0 to (INPUT_SIZE/2)-1 generate
         SINGLE_FP_ADD: FP_Add
         generic map(
             INTEGER_PART => INTEGER_PART,
             FRACTIONAL_PART => FRACTIONAL_PART
         )
         port map(
             i_clk => i_clk,
             i_rstn => i_rstn,
             i_a => i_a(2*i),
             i_b => i_a((2*i)+1),
             o_y => o_y(i)
         );
     end generate LAYER_GEN;

end architecture;
