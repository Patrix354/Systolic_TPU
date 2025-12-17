library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Types.all

entity MAC_Core is
    generic (
        INUPT_PAIRS_NUMBER  : integer := 16;
        IN_INTEGER_PART     : integer := 4;
        IN_FRACTIONAL_PART  : integer := 4;
        OUT_INTEGER_PART    : integer := 8;
        OUT_FRACTIONAL_PART : integer := 8
    );
    port (
        i_clk : in std_logic;
        i_rstn : in std_logic;
        i_valid : in std_logic;
        i_zero : in std_logic;
        i_data : in QFormat_Array((2*INUPT_PAIRS_NUMBER)-1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        o_data : out QFormat(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - downto 0);
        o_busy : out std_logic
    );
end entity;

architecture MAC_Core_arch of MAC_Core is 

    -- Bit length of multiplication stage output
    constant C_MUL_OUTPUT_LEN          : integer := 2 * (IN_INTEGER_PART + IN_FRACTIONAL_PART);
    constant C_MUL_OUTPUT_INTEGER_PART : integer := 2 * IN_INTEGER_PART;
    constant C_MUL_OUTPUT_FRACTIONAL_PART : integer := 2 * IN_FRACTIONAL_PART;

    -- Bit length of addition stage output
    constant C_ADD_ARRAY_OUTPUT_LEN    : integer := C_MUL_OUTPUT_LEN + (INUPT_PAIRS_NUMBER - 1);
    constant C_ADD_ARRAY_OUTPUT_INTEGER_PART : integer := C_MUL_OUTPUT_INTEGER_PERT + (INUPT_PAIRS_NUMBER - 1);
    constant C_ADD_ARRAY_OUTPUT_FRACTIONAL_PART : integer := C_MUL_OUTPUT_FRACTIONAL_PART;

    -- Bit length of accumulation stage output
    constant C_ACC_INTEGER_PART : integer := OUT_INTEGER_PART;
    constant C_ACC_FRACTIONAL_PART : integer := OUT_FRACTIONAL_PART;
    constant C_ACC_OUTPUT_LEN : integer := C_ACC_INTEGER_PART + C_ACC_FRACTIONAL_PART;

    -- Necessary componenet declarations
    component FP_Mul is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid    : in std_logic;
        i_a     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        i_b     : in QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat( 2 * (INTEGER_PART + FRACTIONAL_PART) - 1 downto 0)
    );
    end component FP_Mul;

    component FP_Extender_array is
    generic (
        INPUT_SIZE          : integer := 4;
        IN_INTEGER_PART    : integer := 4;
        IN_FRACTIONAL_PART : integer := 4;
        OUT_INTEGER_PART   : integer := 8;
        OUT_FRACTIONAL_PART: integer := 8
    );
    port (
        i_clk   : in std_logic;
        i_rstn  : in std_logic;
        i_data  : in QFormat_Array(INPUT_SIZE - 1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        i_valid : in std_logic;
        o_data  : out QFormat_Array(INPUT_SIZE - 1 downto 0)(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - 1 downto 0);
        o_ready : out std_logic
    );
    end component FP_Extender_array;

    component FP_Add_Array is
    generic (
        INTEGER_PART    : integer := 4;
        FRACTIONAL_PART : integer := 4;
        INPUT_SIZE      : integer := 16
    );
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid    : std_logic;
        i_data     : in QFormat_Array(INPUT_SIZE-1 downto 0)(INTEGER_PART + FRACTIONAL_PART - 1 downto 0);
        o_ready     : out std_logic;
        o_data     : out QFormat(INTEGER_PART + FRACTIONAL_PART - 1 downto 0)
    );
    end component FP_Add_Array;

    component FP_Acc is
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
    end component FP_Acc;

    component Activation_Function is
    generic (
        DATA_WIDTH : integer := 8
    );
    port (
        i_clk       : in  std_logic;
        i_rstn      : in  std_logic;
        i_data   : in  signed(DATA_WIDTH - 1 downto 0);
        i_valid  : in  std_logic;
        o_data  : out signed(DATA_WIDTH - 1 downto 0)
    );
    end component Activation_Function;

    signal s_start_dly : std_logic;
    signal s_busy : std_logic;
    signal s_done : std_logic;
    signal s_propagating_valid : std_logic_vector(4 downto 0);
    signal s_in_data : QFormat_Array((2*INUPT_PAIRS_NUMBER)-1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
    signal s_FP_Mul_output_array : QFormat_Array(INUPT_PAIRS_NUMBER-1 downto 0)(C_MUL_OUTPUT_LEN - 1 downto 0);
    signal s_FP_Add_array_input_array : QFormat_Array(INUPT_PAIRS_NUMBER-1 downto 0)(C_ADD_ARRAY_OUTPUT_LEN-1 downto 0);
    signal s_FP_Add_array_output : QFormat(C_ADD_ARRAY_OUTPUT_LEN-1 downto 0);
    signal s_FP_Acc_output : QFormat(C_ACC_OUTPUT_LEN-1 downto 0);
    signal s_Activation_output : QFormat(C_ACC_OUTPUT_LEN-1 downto 0);
    signal s_out_data : QFormat(C_ACC_OUTPUT_LEN-1 downto 0);
begin
    
    -- First layer
    -- Multiplication
    MUL_LAYER: for i in 0 to INPUT_PAIRS_NUMBER-1 generate
        SINGLE_MUL: FP_Mul
        generic map(
            INTEGER_PART => IN_INTEGER_PART,
            FRACTIONAL_PART => IN_FRACTIONAL_PART
        )
        port map(
            i_clk => i_clk,
            i_rstn => i_rstn,
            i_valid => s_propagating_valid(0),
            i_a => s_in_data(2*i),
            i_b => s_in_data(2*i+1)
            o_y => s_FP_Mul_outupt_array(i),
            o_ready => s_propagating_valid(1)
        );
     end generate MUL_LAYER;

    -- Second layer
    -- Fixed point format extension
    EXT_LAYER: FP_Extender_array
    generic map(
        INPUT_SIZE => INPUT_PAIRS_NUMBER,
        IN_INTEGER_PART => C_MUL_OUTPUT_INTEGER_PART,
        IN_FRACTIONAL_PART => C_MUL_OUTPUT_FRACTIONAL_PART,
        OUT_INTEGER_PART => C_ADD_ARRAY_OUTPUT_INTEGER_PART,
        OUT_FRACTIONAL_PART => C_ADD_ARRAY_OUTPUT_FRACTIONAL_PART
    )
    port map(
        i_clk => i_clk,
        i_rstn => i_rstn,
        i_data => s_FP_Mul_output_array,
        i_valid => s_propagating_valid(1),
        o_data => s_FP_Add_array_input_array,
        o_ready => s_propagating_valid(2)
    );

    -- Third layer 
    -- Addition
    ADD_LAYER: FP_Add_Array(FP_Add_Array_parallel_arch)
    generic map(
        INTEGER_PART    => C_ADD_ARRAY_OUTPUT_INTEGER_PART,
        FRACTIONAL_PART => C_ADD_ARRAY_OUTPUT_FRACTIONAL_PART,
        INPUT_SIZE      => INUPT_PAIRS_NUMBER
    )
    port map(
        i_clk   => i_clk,
        i_rstn  => i_rstn,
        i_valid => s_propagating_valid(2),
        i_data  => s_FP_Add_array_input_array,
        o_ready => s_propagating_valid(3),
        o_data  => s_FP_Add_array_output
    );

    -- Fourth layer
    -- Accumulation
    ACC_LAYER: FP_Acc
    generic map(        
        IN_INTEGER_PART     => C_ADD_ARRAY_OUTPUT_INTEGER_PART,
        IN_FRACTIONAL_PART  => C_ADD_ARRAY_OUTPUT_FRACTIONAL_PART,
        OUT_INTEGER_PART    => C_ACC_INTEGER_PART,
        OUT_FRACTIONAL_PART => C_ACC_FRACTIONAL_PART
    )
    port map(
        i_clk  => i_clk,
        i_rstn => i_rstn,
        i_en   => s_propagating_valid(3),
        i_zero => i_zero,
        i_data => s_FP_Add_array_output,
        o_ready => s_propagating_valid(4),
        o_data => s_FP_Acc_output
    );

    -- Fifth layer
    -- Activation
    ACT_LAYER: Activation_Function(relu)
    generic map(
        DATA_WIDTH => C_ACC_INTEGER_PART + C_ACC_FRACTIONAL_PART
    )
    port map(
        i_clk => i_clk,
        i_rstn => i_rstn,
        i_valid => s_propagating_valid(4),
        i_data => s_FP_Acc_output,
        o_data => s_Activation_output,
        o_ready => s_done
    );

        process(i_clk) begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_data <= (others => '0');
                s_start_dly <= '0';
                s_busy <= '0';
                s_out_data <= (others => '0');
            else
                if i_start = '1' and s_start_dly = '0' then
                    s_data <= i_data;
                    s_propagating_en(0) <= '1';
                    s_busy <= '1';
                    s_out_data <= s_out_data;
                else
                    if s_busy = '1' and s_done = '1' then
                        s_busy <= '0';
                        s_out_data <= s_activation_output;
                    else
                        s_busy <= s_busy;
                        s_out_data <= s_out_data;
                    end if ;
                    s_data <= s_data;
                    s_propagating_en(0) <= '0';
                end if;

                s_start_dly <= i_start;
            end if;
        end if;
    end process;

    o_data <= s_out_data;
    o_busy <= s_busy;

end architecture;