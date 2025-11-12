library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.Types.all;

entity FP_Add_Array is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;

        i_a     : in QFormat_Array(INPUT_SIZE-1 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_y     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
    );
end entity FP_Add_Array;

architecture FP_Add_Array_serial_arch of FP_Add_Array is 

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

    signal s_mid_results : QFormat_Array((INPUT_SIZE - 2) downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

begin
    
    SERIAL_ARRAY_GEN: for i in (INPUT_SIZE-2) downto 0 generate

        FIRST_ADDER: if (i = (INPUT_SIZE-2)) generate
            FIRST_ADDER_INSTANCE: FP_Add
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_a => i_a(i),
                i_b => i_a(i+1),
                o_y => s_mid_results(i)
            );
        end generate FIRST_ADDER;

        NEXT_ADDERS: if (i /= (INPUT_SIZE-2)) generate
            NEXT_ADDER_INSTANCE: FP_Add
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_a => i_a(i),
                i_b => s_mid_results(i+1),
                o_y => s_mid_results(i)
            );
        end generate NEXT_ADDERS;

    end generate SERIAL_ARRAY_GEN;

    o_y <= s_mid_results(0);

end architecture;

-- architecture FP_Add_Array_pararell_arch of FP_Add_Array is 

--     signal s_mid_results : QFormat_Array(INPUT_SIZE - 2 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

--     component FP_Add_Layer is
--         generic (
--             INTEGER_PART    : integer := 8;
--             FRACTIONAL_PART : integer := 8;
--             INPUT_SIZE      : integer := 16
--         );
--         port (
--             i_clk   : in  std_logic;
--             i_rstn  : in  std_logic;

--             i_a     : in  QFormat_Array(INPUT_SIZE - 1 downto 0)
--                             ((INTEGER_PART + FRACTIONAL_PART - 1) downto 0);
--             o_y     : out QFormat_Array((INPUT_SIZE / 2) - 1 downto 0)
--                             ((INTEGER_PART + FRACTIONAL_PART - 1) downto 0)
--         );
--     end component FP_Add_Layer;

-- begin
    
--     ARRAY_GEN: for i in integer(floor(log2(real(INPUT_SIZE)))) downto 1 generate
        
--         INPUT_LAYER: if (i = integer(floor(log2(real(INPUT_SIZE))))) generate 
--             INPUT_LAYER_INSTANCE: FP_Add_Layer
--             generic map(
--                 INTEGER_PART => INTEGER_PART,
--                 FRACTIONAL_PART => FRACTIONAL_PART,
--                 INPUT_SIZE => 2**i
--             )
--             port map(
--                 i_clk => i_clk,
--                 i_rstn => i_rstn,
--                 i_a => i_a,
--                 o_y => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) )
--             );
--         end generate INPUT_LAYER;

--         MIDDLE_LAYERS: if (i /= integer(floor(log2(real(INPUT_SIZE))))) generate
--             MIDDLE_LAYER_INSTANCE: FP_Add_Layer
--             generic map(
--                 INTEGER_PART => INTEGER_PART,
--                 FRACTIONAL_PART => FRACTIONAL_PART,
--                 INPUT_SIZE => 2**i
--             )
--             port map(
--                 i_clk => i_clk,
--                 i_rstn => i_rstn,
--                 i_a => s_mid_results( (2**(i+1) - 2) downto (2**(i+1) - 2**i - 1) ),
--                 o_y => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) )
--             );
--         end generate MIDDLE_LAYERS;
        
--      end generate ARRAY_GEN;

--     o_y <= s_mid_results(0);

-- end architecture FP_Add_Array_pararell_arch;