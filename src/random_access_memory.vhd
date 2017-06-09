library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random_access_memory is
    generic
        (identifier:       std_logic_vector(3 downto 0);
		 memory_buffer_id: std_logic_vector(3 downto 0);
         word_width:       natural;
		 address_width:    natural);
    port
        (system_bus:     inout std_logic_vector(word_width - 1 downto 0);
         clk:            in    std_logic;
		 memory_address: in    std_logic_vector(address_width - 1 downto 0));
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
				if input(3 downto 0) = identifier then
					if input(word_width - 2) = '0' then
						next_state <= store_call;
					elsif input(word_width - 2) = '1' then
						next_state <= load_call;
					end if;
				elsif input(word_width - 1) = '1' then
					next_state <= sleep_2;
				end if;
            when store_call =>
				sending <= '1';
				output(3 downto 0) <= memory_buffer_id;
				output(7 downto 4) <= identifier;
				output(word_width - 2 downto 8) <= (others => '0');
				output(word_width - 1) <= '1';
				next_state <= store_send;
            when store_send =>
				sending <= '0';
				values(to_integer(unsigned(memory_address))) <= input;
                next_state <= sleep_1;
			when load_call =>
				sending <= '1';
				output(3 downto 0) <= identifier;
				output(7 downto 4) <= memory_buffer_id;
				output(word_width - 2 downto 8) <= (others => '0');
				output(word_width - 1) <= '1';
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
