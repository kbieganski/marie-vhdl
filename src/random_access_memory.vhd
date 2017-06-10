library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_constants.all;
use work.utility.all;

entity random_access_memory is
	generic
		(identifier:	   std_logic_vector(3 downto 0);
		 memory_buffer_id: std_logic_vector(3 downto 0));
	port
		(system_bus:	 inout std_logic_vector(word_width - 1 downto 0);
		 clk:			 in	   std_logic;
		 memory_address: in	   std_logic_vector(address_width - 1 downto 0));
end random_access_memory;

architecture behavioral of random_access_memory is
	type value_array_t is array (0 to 2 ** address_width - 1)
		of std_logic_vector(word_width - 1 downto 0);
	signal values: value_array_t;

	signal input:  std_logic_vector(word_width - 1 downto 0);
	signal output: std_logic_vector(word_width - 1 downto 0);

	type state_t is (idle, store_call, store_send, load_call, load_send, sleep_2, sleep_1);
	signal curr_state: state_t;
	signal next_state: state_t := idle;

	signal sending: std_logic := '0';

begin
	state_advance: process(clk)
	begin
		if falling_edge(clk) then
			curr_state <= next_state;
		end if;
	end process;

	state_logic: process(curr_state, input)
	begin
		case curr_state is
			when idle =>
				sending <= '0';
				if is_cmd_for(input, identifier) then
					if decode_ram_cmd(input) = '0' then
						next_state <= store_call;
					else
						next_state <= load_call;
					end if;
				elsif is_send_cmd(input) then
					next_state <= sleep_2;
				end if;
			when store_call =>
				sending <= '1';
				output <= encode_send_cmd(memory_buffer_id, identifier);
				next_state <= store_send;
			when store_send =>
				sending <= '0';
				values(to_integer(unsigned(memory_address))) <= input;
				next_state <= sleep_1;
			when load_call =>
				sending <= '1';
				output <= encode_send_cmd(identifier, memory_buffer_id);
				next_state <= load_send;
			when load_send =>
				output <= values(to_integer(unsigned(memory_address)));
				next_state <= sleep_1;
			when sleep_2 =>
				next_state <= sleep_1;
			when sleep_1 =>
				sending <= '0';
				next_state <= idle;
		end case;
	end process;

	input <= system_bus when sending = '0' else (others => 'Z');
	system_bus <= output when sending = '1' else (others => 'Z');

end behavioral;
