library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arithmetic_logic_unit is
	generic
		(identifier: std_logic_vector(3 downto 0);
		 word_width: natural);
	port
		(system_bus:		inout std_logic_vector(word_width - 1 downto 0);
		 clk:				in	  std_logic;
		 accumulator_read:	in	  std_logic_vector(word_width - 1 downto 0);
		 accumulator_write: out	  std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
		 memory_buffer:		in	  std_logic_vector(word_width - 1 downto 0));
end arithmetic_logic_unit;

architecture behavioral of arithmetic_logic_unit is
	signal input:  std_logic_vector(word_width - 1 downto 0);
	signal output: std_logic_vector(word_width - 1 downto 0);

	type state_t is (idle, add, subtract, less, equal, greater, sleep_2, sleep_1);
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
					if input(word_width - 2 downto word_width - 4) = "000" then
						next_state <= add;
					elsif input(word_width - 2 downto word_width - 4) = "001" then
						next_state <= subtract;
					elsif input(word_width - 2 downto word_width - 4) = "100" then
						next_state <= less;
					elsif input(word_width - 2 downto word_width - 4) = "101" then
						next_state <= equal;
					elsif input(word_width - 2 downto word_width - 4) = "110" then
						next_state <= greater;
					end if;
				elsif input(word_width - 1) = '1' then
					next_state <= sleep_2;
				end if;
			when add =>
				accumulator_write <= std_logic_vector(signed(accumulator_read) + signed(memory_buffer));
				next_state <= sleep_1;
			when subtract =>
				accumulator_write <= std_logic_vector(signed(accumulator_read) - signed(memory_buffer));
				next_state <= sleep_1;
			when less =>
				sending <= '1';
				if signed(accumulator_read) < 0 then
					output(word_width - 2 downto 4) <= (others => '1');
				else
					output(word_width - 2 downto 4) <= (others => '0');
				end if;
				output(word_width - 1) <= '0';
				output(3 downto 0) <= identifier;
				next_state <= sleep_1;
			when equal =>
				sending <= '1';
				if signed(accumulator_read) = 0 then
					output(word_width - 2 downto 4) <= (others => '1');
				else
					output(word_width - 2 downto 4) <= (others => '0');
				end if;
				output(word_width - 1) <= '0';
				output(3 downto 0) <= identifier;
				next_state <= sleep_1;
			when greater =>
				sending <= '1';
				if signed(accumulator_read) > 0 then
					output(word_width - 2 downto 4) <= (others => '1');
				else
					output(word_width - 2 downto 4) <= (others => '0');
				end if;
				output(word_width - 1) <= '0';
				output(3 downto 0) <= identifier;
				next_state <= sleep_1;
			when sleep_2 =>
				next_state <= sleep_1;
			when sleep_1 =>
				sending <= '0';
				accumulator_write <= (others => 'Z');
				next_state <= idle;
		end case;
	end process;

	input <= system_bus when sending = '0' else (others => 'Z');
	system_bus <= output when sending = '1' else (others => 'Z');

end behavioral;
