library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.npu_types.all;
use work.npu_config.all;

entity npu_systolic_array is
    port (
        i_clk   : in std_logic;
        i_rstn   : in std_logic;
        i_clr : in std_logic;
        i_w : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        i_w_en : in std_logic_vector(C_ARRAY_SIZE-1 downto 0);
        i_en : in std_logic;
        i_data : in QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_data : out QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
        o_en : out std_logic
    );
end entity;

architecture npu_systolic_array_rtl of npu_systolic_array is 

    signal s_x_pe_outputs : QFormat_Array(C_ARRAY_SIZE**2 - 1 downto 0)(C_DATA_WIDTH - 1 downto 0);
    signal s_x_pe_inputs : QFormat_Array(C_ARRAY_SIZE**2 - 1 downto 0)(C_DATA_WIDTH - 1 downto 0);
    signal s_data_in_delayed : QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);

    signal s_y_pe_outputs : QFormat_Array(C_ARRAY_SIZE**2 - 1 downto 0)(C_DATA_WIDTH - 1 downto 0);
    signal s_y_pe_inputs : QFormat_Array(C_ARRAY_SIZE**2 - 1 downto 0)(C_DATA_WIDTH - 1 downto 0);

    signal s_en_pe_inputs : std_logic_vector(C_ARRAY_SIZE**2 - 1 downto 0);
    signal s_en_pe_outputs : std_logic_vector(C_ARRAY_SIZE**2 - 1 downto 0);
    signal s_en_in_delayed : std_logic_vector(C_ARRAY_SIZE-1 downto 0);

    signal s_en_array_output : std_logic_vector(C_ARRAY_SIZE-1 downto 0);
    signal s_data_array_output : QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);

    signal s_en_out_delayed : std_logic_vector(C_ARRAY_SIZE-1 downto 0);
    signal s_data_out_delayed : QFormat_Array(C_ARRAY_SIZE-1 downto 0)(C_DATA_WIDTH - 1 downto 0);
begin

    u_in_delay : entity work.npu_systolic_array_delay
    port map (
        i_clk => i_clk,
        i_rstn => i_rstn,
        i_en => (others => i_en),
        i_data => i_data,
        o_en => s_en_in_delayed,
        o_data => s_data_in_delayed
    );


    u_out_delay : entity work.npu_systolic_array_delay
    port map (
        i_clk => i_clk,
        i_rstn => i_rstn,
        i_en => s_en_array_output,
        i_data => s_data_array_output,
        o_en => s_en_out_delayed,
        o_data => s_data_out_delayed
    );

    gen_rows : for row in 0 to C_ARRAY_SIZE - 1 generate

        gen_cols : for col in 0 to C_ARRAY_SIZE - 1 generate

            u_pe : entity work.npu_pe
            port map (
                i_clk => i_clk,
                i_rstn => i_rstn,
                i_en => s_en_pe_inputs(row * C_ARRAY_SIZE + col),
                i_w_en => i_w_en(col),
                i_w => i_w(row),
                i_x => s_x_pe_inputs(row * C_ARRAY_SIZE + col),
                i_y => s_y_pe_inputs(row * C_ARRAY_SIZE + col),
                o_x => s_x_pe_outputs(row * C_ARRAY_SIZE + col),
                o_y => s_y_pe_outputs(row * C_ARRAY_SIZE + col),
                o_en => s_en_pe_outputs(row * C_ARRAY_SIZE + col)
            );

        end generate gen_cols;

    end generate gen_rows;

    process (all)
    begin
        for row in 0 to C_ARRAY_SIZE - 1 loop
            for col in 0 to C_ARRAY_SIZE - 1 loop

                if col = 0 then
                    s_en_pe_inputs(row * C_ARRAY_SIZE + col) <= s_en_in_delayed(row);
                else
                    s_en_pe_inputs(row * C_ARRAY_SIZE + col) <= s_en_pe_outputs(row * C_ARRAY_SIZE + (col - 1));
                end if;

                if row = 0 then
                    s_y_pe_inputs(row * C_ARRAY_SIZE + col) <= (others => '0');
                else
                    s_y_pe_inputs(row * C_ARRAY_SIZE + col) <= s_y_pe_outputs((row - 1) * C_ARRAY_SIZE + col);
                end if;

                if col = 0 then
                    s_x_pe_inputs(row * C_ARRAY_SIZE + col) <= s_data_in_delayed(row);
                else
                    s_x_pe_inputs(row * C_ARRAY_SIZE + col) <= s_x_pe_outputs(row * C_ARRAY_SIZE + (col - 1));
                end if;

            end loop;
        end loop;

        for i in 0 to C_ARRAY_SIZE - 1 loop
            s_en_array_output((C_ARRAY_SIZE - 1) - i) <= s_en_pe_outputs((C_ARRAY_SIZE - 1) * C_ARRAY_SIZE + i);
            s_data_array_output((C_ARRAY_SIZE - 1) - i) <= s_y_pe_outputs((C_ARRAY_SIZE - 1) * C_ARRAY_SIZE + i);

            o_data(i) <= s_data_out_delayed((C_ARRAY_SIZE - 1) - i);
        end loop;
        o_en <= s_en_out_delayed(0);
    end process;
    
end architecture;