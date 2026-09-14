library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.npu_config.all;
use work.npu_types.all;

entity npu_sram is
    port (
        -- Port A
        clk_a      : in  std_logic;
        rstn_a     : in  std_logic;
        en_a       : in  std_logic;
        we_a       : in  std_logic;
        addr_a     : in  std_logic_vector(C_SRAM_ADDR_WIDTH - 1 downto 0);
        data_a_in  : in  std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
        data_a_out : out std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);

        -- Port B
        clk_b      : in  std_logic;
        rstn_b     : in  std_logic;
        en_b       : in  std_logic;
        we_b       : in  std_logic;
        addr_b     : in  std_logic_vector(C_SRAM_ADDR_WIDTH - 1 downto 0);
        data_b_in  : in  std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
        data_b_out : out std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0)
    );
end entity npu_sram;

architecture npu_sram_behav of npu_sram is
    type ram_type is array (0 to (2**C_SRAM_ADDR_WIDTH) - 1) of std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);

    -- Typ chroniony (protected type) do bezpiecznej obsługi shared variable i resetu całej pamięci
    type ram_protected_t is protected
        procedure write(addr : in integer; data : in std_logic_vector);
        impure function read(addr : in integer) return std_logic_vector;
        procedure reset_ram;
    end protected ram_protected_t;

    type ram_protected_t is protected body
        variable mem : ram_type := (others => (others => '0'));

        procedure write(addr : in integer; data : in std_logic_vector) is
        begin
            mem(addr) := data;
        end procedure;

        impure function read(addr : in integer) return std_logic_vector is
        begin
            return mem(addr);
        end function;

        procedure reset_ram is
        begin
            mem := (others => (others => '0'));
        end procedure;
    end protected body ram_protected_t;

    shared variable ram : ram_protected_t;

    type pipeline_type is array (0 to C_SRAM_READ_LATENCY - 1) of std_logic_vector(C_SRAM_DATA_WIDTH - 1 downto 0);
    signal pipe_a : pipeline_type := (others => (others => '0'));
    signal pipe_b : pipeline_type := (others => (others => '0'));

begin

    -- Obsługa Portu A
    process(clk_a, rstn_a)
    begin
        if rstn_a = '0' then
            pipe_a <= (others => (others => '0'));
            ram.reset_ram;
        elsif rising_edge(clk_a) then
            if en_a = '1' then
                if we_a = '1' then
                    ram.write(to_integer(unsigned(addr_a)), data_a_in);
                end if;

                pipe_a(0) <= ram.read(to_integer(unsigned(addr_a)));

                for i in 1 to C_SRAM_READ_LATENCY - 1 loop
                    pipe_a(i) <= pipe_a(i-1);
                end loop;
            end if;
        end if;
    end process;

    data_a_out <= pipe_a(C_SRAM_READ_LATENCY - 1);

    -- Obsługa Portu B
    process(clk_b, rstn_b)
    begin
        if rstn_b = '0' then
            pipe_b <= (others => (others => '0'));
            ram.reset_ram;
        elsif rising_edge(clk_b) then
            if en_b = '1' then
                if we_b = '1' then
                    ram.write(to_integer(unsigned(addr_b)), data_b_in);
                end if;

                pipe_b(0) <= ram.read(to_integer(unsigned(addr_b)));

                for i in 1 to C_SRAM_READ_LATENCY - 1 loop
                    pipe_b(i) <= pipe_b(i-1);
                end loop;
            end if;
        end if;
    end process;

    data_b_out <= pipe_b(C_SRAM_READ_LATENCY - 1);

end architecture npu_sram_behav;