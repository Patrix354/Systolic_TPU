library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Types is

    -- Common NoC bus widths used by all NoC_* record fields
    constant C_NOC_DATA_WIDTH : integer := 16;
    constant C_NOC_ADDR_WIDTH : integer := 8;

    -- NoC operation codes used in the master request channel
    type NoC_op is (NoC_NOP, NoC_WRITE, NoC_READ, NoC_EXECUTE, NoC_END);
    type NoC_tree_node_state is (NoC_IDLE, NoC_TRANSACTION);
    type NoC_ready_signal_state is (NoC_UNACTIVE_IDLE, NoC_TRANSACTION_IDLE, NoC_TRANSACTION_PENDING);
    -- Generic fixed-point container (Q-format). Width is defined at the point of use
    subtype QFormat is signed;

    -- Unconstrained vector-of-Q-format values for parallel datapaths
    type QFormat_Array is array (natural range <>) of signed;

    -- NoC master request channel:
    --   valid     : request is present and fields are stable
    --   address   : target address on the NoC
    --   data      : write payload or operand data (depending on operation)
    --   operation : request type (write/read/execute)
    type NoC_connect_master is record
        valid : std_logic;
        address : std_logic_vector(C_NOC_ADDR_WIDTH-1 downto 0);
        data : std_logic_vector(C_NOC_DATA_WIDTH-1 downto 0);
        operation : NoC_op;
    end record NoC_connect_master;

    -- NoC slave response channel:
    --   data  : response data
    --   ready : AXI-style valid/ready handshake convention
    --   read_ready : handshake used while read operation
    type NoC_connect_slave is record
        data : std_logic_vector(C_NOC_DATA_WIDTH-1 downto 0);
        ready : std_logic;
        active : std_logic;
        read_ready : std_logic;
    end record NoC_connect_slave;

    -- Bundles of multiple NoC interfaces
    type NoC_connect_slave_array is array (natural range <>) of NoC_connect_slave;
    type NoC_connect_master_array is array (natural range <>) of NoC_connect_master;

    -- TODO : Spytać się łuczyka o user guide do bloku SRAM w używanej technologii 
    type SRAM_connect_master is record
        s_data : std_logic_vector(C_NOC_DATA_WIDTH-1 downto 0);
        ready : std_logic;
    end record SRAM_connect_master;

end package Types;
