library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
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
end entity;

-- architecture FP_Add_Array_serial_arch of FP_Add_Array is 
-- begin
    
--     process(i_clk)
--     begin
--         if rising_edge(i_clk) then
--             if i_rstn = '0' then
--             else
--             end if;
--         end if;

--     end process;

-- end architecture;

architecture FP_Add_Array_pararell_arch of FP_Add_Array is 

    signal s_mid_results : QFormat_Array(INUPT_SIZE - 2 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);

    component FP_Add_Layer is
        generic (
            INTEGER_PART    : integer := 8;
            FRACTIONAL_PART : integer := 8;
            INPUT_SIZE      : integer := 16
        );
        port (
            i_clk   : in  std_logic;
            i_rstn  : in  std_logic;

            i_a     : in  QFormat_Array(INPUT_SIZE - 1 downto 0)
                            ((INTEGER_PART + FRACTIONAL_PART - 1) downto 0);
            o_y     : out QFormat_Array((INPUT_SIZE / 2) - 1 downto 0)
                            ((INTEGER_PART + FRACTIONAL_PART - 1) downto 0)
        );
    end component FP_Add_Layer;

begin
    
    ARRAY_GEN: for i in integer(floor(log2(INUPT_SIZE))) downto 1 generate
        
        INPUT_LAYER: if (i = integer(floor(log2(INUPT_SIZE)))) generate 
            SINGLE_FP_LAYER: FP_Add_Layer
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART,
                INPUT_SIZE => 2**i
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_a => i_a,
                o_y => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) )
            );
        end generate INPUT_LAYER;

        MIDDLE_LAYERS: if (i /= integer(floor(log2(INUPT_SIZE)))) generate
            SINGLE_FP_LAYER: FP_Add_Layer
            generic map(
                INTEGER_PART => INTEGER_PART,
                FRACTIONAL_PART => FRACTIONAL_PART,
                INPUT_SIZE => 2**i
            )
            port map(
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_a => s_mid_results( (2**(i+1) - 2) downto (2**(i+1) - 2**i - 1) ),
                o_y => s_mid_results( (2**i - 2) downto (2**i - 2**(i-1) - 1) )
            );
        end generate MIDDLE_LAYERS;
        
     end generate LAYER_GEN;

    o_y <= s_mid_results(0);

end architecture;