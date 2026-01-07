library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MAC_Cell is
    port (
        X : in std_logic;
        Y : out std_logic
    );
end entity;

architecture MAC_Cell_arch of MAC_Cell is 

    component SRAM_dual_port is
        generic (
            DATA_WIDTH : integer := 8;    
            ADDR_WIDTH : integer := 8
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
    end component;


    component MAC_Core is
    generic (
        INPUT_PAIRS_NUMBER  : integer := 16;
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
        i_data : in QFormat_Array((2*INPUT_PAIRS_NUMBER)-1 downto 0)(IN_INTEGER_PART + IN_FRACTIONAL_PART - 1 downto 0);
        o_data : out QFormat(OUT_INTEGER_PART + OUT_FRACTIONAL_PART - 1 downto 0);
        o_done : out std_logic
    );
    end component;

begin
    
end architecture;