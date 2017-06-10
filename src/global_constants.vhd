library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package global_constants is
	constant word_width:    natural := 16;
	constant bus_width:     natural := word_width;
	constant address_width: natural := word_width - 4;
end global_constants;
