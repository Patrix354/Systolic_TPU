library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SRAM_dual_port is
    generic (
        DATA_WIDTH : integer := 8;    -- szerokość słowa
        ADDR_WIDTH : integer := 8     -- szerokość adresu (2^ADDR_WIDTH komórek)
    );
    port (
        clk   : in  std_logic;

        -- Port A
        we_a  : in  std_logic;
        addr_a: in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_a : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_a: out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Port B
        we_b  : in  std_logic;
        addr_b: in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din_b : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout_b: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end SRAM_dual_port;

architecture rtl of SRAM_dual_port is

    type ram_type is array (0 to 2**ADDR_WIDTH - 1)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal ram : ram_type := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- Port A
            if we_a = '1' then
                ram(to_integer(unsigned(addr_a))) <= din_a;
                dout_a <= din_a; -- write-first
            else
                dout_a <= ram(to_integer(unsigned(addr_a)));
            end if;

            -- Port B
            if we_b = '1' then
                ram(to_integer(unsigned(addr_b))) <= din_b;
                dout_b <= din_b; -- write-first
            else
                dout_b <= ram(to_integer(unsigned(addr_b)));
            end if;

        end if;
    end process;

end rtl;

