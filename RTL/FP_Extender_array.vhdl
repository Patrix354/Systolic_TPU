library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Types.all;

entity FP_Extender_array is
    generic (
        INPUT_SIZE          : integer := 4;
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk : in std_logic;
        i_rstn : in std_logic;
        i_data     : in QFormat_Array(INPUT_SIZE - 1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        i_valid : in std_logic;
        o_data     : out QFormat_Array(INPUT_SIZE - 1 downto 0)(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
end entity FP_Extender_array;

architecture FP_Extender_array_arch of FP_Extender_array is

    component FP_Extender is
    generic (
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk : in std_logic;
        i_rstn : in std_logic;
        i_data : in QFormat((IN_INTEGER_PART+IN_FRACTIONAL_PART-1) downto 0);
        i_valid : in std_logic;
        o_data : out QFormat((OUT_INTEGER_PART+OUT_FRACTIONAL_PART-1) downto 0);
        o_ready : out std_logic
    );
    end component FP_Extender;


    signal s_ready : std_logic_vector(INPUT_SIZE - 1 downto 0);

begin
    EXTENDER_GEN : for i in 0 to INPUT_SIZE - 1 generate
        EXT_INST: FP_Extender 
        generic map (
            IN_INTEGER_PART     => IN_INTEGER_PART,
            IN_FRACTIONAL_PART  => IN_FRACTIONAL_PART,
            OUT_INTEGER_PART    => OUT_INTEGER_PART,
            OUT_FRACTIONAL_PART => OUT_FRACTIONAL_PART
        )
        port map (
            i_clk => i_clk,
            i_rstn => i_rstn,
            i_data => i_data(i),
            i_valid => i_valid,
            o_data => o_data(i),
            o_ready => s_ready(i)
        );
    end generate EXTENDER_GEN;
    
    o_ready <= s_ready(0);


end architecture FP_Extender_array_arch;