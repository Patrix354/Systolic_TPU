library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Acc is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk  : in std_logic;
        i_rstn  : in std_logic;
        i_en   : in std_logic;
        i_zero : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0)
    );
end entity FP_Acc;

architecture FP_Acc_arch of FP_Acc is

    signal s_ext_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_acc_data   : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_a      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_b      : QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
    signal s_en     : std_logic;
    signal s_zero   : std_logic;

    component FP_Add is
        generic (
            INTEGER_PART    : integer := OUT_INTEGER_PART;
            FRACTIONAL_PART : integer := OUT_FRACTIONAL_PART
        );
        port (
            i_clk   : in std_logic;
            i_rstn   : in std_logic;
            i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
            o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
        );
    end component;

    component FP_Extender is
        generic (
            IN_INTEGER_PART    : integer := 4;
            IN_FRACTIONAL_PART : integer := 4;
            OUT_INTEGER_PART   : integer := 8;
            OUT_FRACTIONAL_PART: integer := 8
            );
        port (
            i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
            o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0)
        );
    end component;

begin

    s_en <= i_en when i_rstn = '1' else '0';
    s_zero <= i_zero when i_rstn = '1' else '0';
    o_data <= s_acc_data when i_rstn = '1' else (others => '0');


    ACC_SUM_CELL: FP_Add
         generic map(
             INTEGER_PART => OUT_INTEGER_PART,
             FRACTIONAL_PART => OUT_FRACTIONAL_PART
         )
         port map(
             i_clk => i_clk,
             i_rstn => i_rstn,
             i_a => s_a,
             i_b => s_b,
             o_y => s_acc_data
         );

    SIGNED_EXT: FP_Extender 
        generic map(
            IN_INTEGER_PART    => IN_INTEGER_PART,
            IN_FRACTIONAL_PART => IN_FRACTIONAL_PART,
            OUT_INTEGER_PART    => OUT_INTEGER_PART,
            OUT_FRACTIONAL_PART => OUT_INTEGER_PART
        )
        port map(
            i_data => i_data,
            o_data => s_ext_data

        );

    ACC_PROC : process( i_clk )
    begin
        if rising_edge(i_clk) then
            s_a <= s_ext_data when s_zero = '0' else (others => '0');
            s_b <= s_acc_data when s_en = '1' else (others => '0');
        end if;
    end process;

end architecture FP_Acc_arch;