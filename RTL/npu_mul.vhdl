library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.math_complex.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_mul is
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_valid     : in std_logic;
        i_a     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        i_b     : in QFormat(C_DATA_WIDTH - 1 downto 0);
        o_ready : out std_logic;
        o_y     : out QFormat(C_DATA_WIDTH - 1 downto 0)
    );
end entity;

architecture npu_mul_behav of npu_mul is
    signal s_active : std_logic; 
    signal s_a : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_b : QFormat(C_DATA_WIDTH - 1 downto 0);
    signal s_y : QFormat( 2 * C_DATA_WIDTH - 1 downto 0);
begin
    
    o_y <= s_y(C_DATA_WIDTH - 1 downto 0);

    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rstn = '0' then
                s_y <= (others => '0');
                o_ready <= '0';
                s_a <= (others => '0');
                s_b <= (others => '0');
                s_active <= '0';
            else
                if i_valid = '1' then
                    s_a <= i_a;
                    s_b <= i_b;
                    s_active <= '1';
                else
                    s_a <= s_a;
                    s_b <= s_b;
                    s_active <= '0';
                end if;

                if s_active = '1' then
                    s_y <= s_a * s_b;
                    o_ready <= '1';
                else
                    s_y <= s_y;
                    o_ready <= '0';
                end if;

            end if;
        end if;

    end process;

end architecture;

architecture npu_mul_rtl of npu_mul is 
    constant C_INPUT_BIT_LEN : natural := C_DATA_WIDTH;
    constant C_OUTPUT_BIT_LEN : natural := 2 * C_INPUT_BIT_LEN;
    constant C_IN_FRACTIONAL_PART : natural := C_FRACTIONAL_PART;
    constant C_IN_INTEGER_PART : natural := C_INTEGER_PART;
    constant C_OUT_FRACTIONAL_PART : natural := 2 * C_FRACTIONAL_PART;
    constant C_OUT_INTEGER_PART : natural := 2 * C_INTEGER_PART;
    
    constant C_LEADING_ZEROS : std_logic_vector((C_OUTPUT_BIT_LEN - C_INPUT_BIT_LEN - 1) downto 0) := 
    (others => '0'); 
    constant C_LEADING_ONES : std_logic_vector((C_OUTPUT_BIT_LEN - C_INPUT_BIT_LEN - 1) downto 0) := 
    (others => '1'); 

    signal s_b : QFormat(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_en_pipe : std_logic_vector(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_neg_pipe : std_logic_vector(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_a_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_b_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);
    signal s_y_pipe : QFormat_Array(C_INPUT_BIT_LEN - 1 downto 0)(C_OUTPUT_BIT_LEN - 1 downto 0);
    signal s_y_short : QFormat(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_y_short_modulus : QFormat(C_INPUT_BIT_LEN - 1 downto 0);
    signal s_fraction_lost : std_logic;

begin

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_rstn = '0') then

        for i in C_INPUT_BIT_LEN-1 downto 0 loop
            s_b_pipe(i) <= (others => '0');
            s_a_pipe(i) <= (others => '0');
            s_y_pipe(i) <= (others => '0');
        end loop;
        s_en_pipe <= (others => '0');
        s_neg_pipe <= (others => '0');
      else

        if((i_a(C_INPUT_BIT_LEN - 1) = '1' and i_b(C_INPUT_BIT_LEN - 1) = '1') or 
        (i_a(C_INPUT_BIT_LEN - 1) = '0' and i_b(C_INPUT_BIT_LEN - 1) = '0')) then
            s_neg_pipe(0) <= '0';
        else
            s_neg_pipe(0) <= '1';
        end if;

        if(i_a(C_INPUT_BIT_LEN - 1) = '1') then
            s_a_pipe(0) <= (not i_a) + '1';
        else
            s_a_pipe(0) <= i_a;
        end if;

        s_b_pipe(0) <= QFormat(C_LEADING_ZEROS & std_logic_vector(s_b));

        s_en_pipe(0) <= i_valid;

        s_y_pipe(0) <= (others => '0');
        

        for i in C_INPUT_BIT_LEN-1 downto 1 loop 
            s_b_pipe(i) <= s_b_pipe(i-1) sll 1;
            s_a_pipe(i) <= s_a_pipe(i-1) srl 1;
        end loop;
        
        for i in C_INPUT_BIT_LEN-1 downto 1 loop
            if(s_a_pipe(i-1)(0) = '1') then
                s_y_pipe(i) <= s_y_pipe(i-1) + s_b_pipe(i-1);
            else 
                s_y_pipe(i) <= s_y_pipe(i-1);
            end if;
        end loop;

        for i in C_INPUT_BIT_LEN-1 downto 1 loop
            s_en_pipe(i) <= s_en_pipe(i-1);
            s_neg_pipe(i) <= s_neg_pipe(i-1);
        end loop;

      end if;
    end if;

  end process;

    comb_proc : process( all )
        variable v_CONCATENATE : std_logic_vector(1 downto 0);
    begin
        v_CONCATENATE := s_neg_pipe(C_INPUT_BIT_LEN - 1) & s_fraction_lost;
        
        s_y_short <= s_y_pipe(C_INPUT_BIT_LEN - 1)(C_DATA_WIDTH + C_IN_FRACTIONAL_PART - 1 downto C_IN_FRACTIONAL_PART);
        o_ready <= s_en_pipe(C_INPUT_BIT_LEN - 1);
        s_fraction_lost <= '1' when s_y_pipe(C_INPUT_BIT_LEN - 1)(C_IN_FRACTIONAL_PART - 1 downto 0) /= 0 else '0';

        case( v_CONCATENATE ) is
            when "00" => o_y <= s_y_short;
            when "01" => o_y <= s_y_short;
            when "10" => o_y <= (not s_y_short) + 1;
            when "11" => o_y <= (not (s_y_short + 1)) + 1;
            when others => o_y <= (others => '0');
        end case ;

        case(i_b(C_INPUT_BIT_LEN - 1)) is
        
            when '1' => s_b <= (not i_b) + 1;
            when '0' => s_b <= i_b;
            when others => s_b <= (others => '0');        
        end case ;
    end process ; -- comb_proc

end architecture npu_mul_rtl;