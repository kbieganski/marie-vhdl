library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.global_constants.all;
use work.utility.all;

entity user_interface is
	generic
		(identifier: std_logic_vector(3 downto 0));
	port
		(system_bus:  in  std_logic_vector(word_width - 1 downto 0);
		 clk:         in  std_logic;
		 input_write: out std_logic_vector(io_width - 1 downto 0) := (others => 'Z');
		 output_read: in  std_logic_vector(io_width - 1 downto 0));
end user_interface;

architecture behavioral of user_interface is
	type state_t is (idle, read_stdin, write_stdout, sleep_3, sleep_2, sleep_1);
	signal curr_state: state_t;
	signal next_state: state_t := idle;

begin
	state_advance: process(clk)
	begin
		if falling_edge(clk) then
			curr_state <= next_state;
		end if;
	end process;

	state_logic: process(curr_state, system_bus)
		variable in_line:  line;
		variable out_line: line;
	begin
		case curr_state is
			when idle =>
				if is_send_cmd(system_bus) then
					next_state <= sleep_3;
				elsif is_cmd_for(system_bus, identifier) then
					if decode_ui_cmd(system_bus) = '0' then next_state <= read_stdin;
					else next_state <= write_stdout;
					end if;
				end if;
			when read_stdin =>
				readline(input, in_line);
				input_write <= std_logic_vector(to_signed(integer'value(in_line(1 to in_line.all'length)), io_width));
				next_state <= sleep_2;
			when write_stdout =>
				write(out_line, to_integer(signed(output_read)));
				writeline(output, out_line);
				next_state <= sleep_2;
			when sleep_3 =>
				next_state <= sleep_2;
			when sleep_2 =>
				input_write <= (others => 'Z');
				next_state <= sleep_1;
			when sleep_1 =>
				next_state <= idle;
		end case;
	end process;

end behavioral;
