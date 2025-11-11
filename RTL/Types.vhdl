-------------------------------------------------------------------------------
-- Title      : Types
-- Project    : MAC Cell
-- File       : Types.vhdl
-- Author     : Laura Korycka
-- Description:
--   This package defines common data types used across the fixed-point
--   arithmetic modules. It provides type aliases for Q-format numbers
--   and arrays of such values, allowing for consistent and parameterizable
--   design of arithmetic blocks.
--
-- Declarations:
--   QFormat        - Subtype of 'signed' representing a fixed-point number
--                    in Q-format (integer and fractional parts defined by generics).
--   QFormat_Array  - Array type for handling vectors of Q-format numbers,
--                    used in multi-element operations.
--
-- Notes:
--   - The QFormat subtype does not specify bit width; it must be defined
--     by the modules that use it (e.g., through generics).
--
-- Revision history:
--   31-10-2025 : Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Types is

    subtype QFormat is signed;
    type QFormat_Array is array (natural range <>) of signed;

end package Types;