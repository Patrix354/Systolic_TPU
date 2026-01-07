-------------------------------------------------------------------------------
-- Title      : Types
-- Project    : MAC Cell
-- File       : Types.vhdl
-- Author     : Laura Korycka
--
-- Description:
--   This package defines common data types used across the project.
--   It includes type aliases for fixed-point (Q-format) arithmetic as well as
--   structured types used for communication and control between modules.
--
--   The package centralizes type definitions to ensure consistency and
--   readability across arithmetic blocks and system-level interconnect logic.
--
-- Declarations:
--   QFormat         - Subtype of 'signed' representing a fixed-point number
--                     in Q-format. Bit width is defined by the using modules
--                     (e.g., via generics).
--   QFormat_Array   - Unconstrained array type for vectors of Q-format values,
--                     useful for parallel or multi-element operations.
--   NoC_connect     - Record type defining a simple NoC-style interface,
--                     including clocking, control signals, address, data
--                     channels, and operation encoding.
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Types is

    subtype QFormat is signed;
    type QFormat_Array is array (natural range <>) of signed;

    type NoC_connect is record
    clk : std_logic;
    rstn : std_logic;
    valid : std_logic;
    address : std_logic_vector(15 downto 0);
    m_data : std_logic_vector(63 downto 0);
    s_data : std_logic_vector(63 downto 0);
    ready : std_logic;
    operation : std_logic_vector(3 downto 0);
    end record NoC_connect;

end package Types;