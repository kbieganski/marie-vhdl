library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_constants.all;
use work.utility.all;

entity arithmetic_logic_unit is
	generic
		(identifier: std_logic_vector(3 downto 0));
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

	type state_t is (idle, add, subtract, lt_0, eq_0, gt_0, sleep_2, sleep_1);
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
					if decode_alu_cmd(input) = "000" then next_state <= add;
					elsif decode_alu_cmd(input) = "001" then next_state <= subtract;
					elsif decode_alu_cmd(input) = "100" then next_state <= lt_0;
					elsif decode_alu_cmd(input) = "101" then next_state <= eq_0;
					elsif decode_alu_cmd(input) = "110" then next_state <= gt_0;
					end if;
				elsif is_send_cmd(input) then
					next_state <= sleep_2;
				end if;
			when add =>
				accumulator_write <= std_logic_vector(signed(accumulator_read) + signed(memory_buffer));
				next_state <= sleep_1;
			when subtract =>
				accumulator_write <= std_logic_vector(signed(accumulator_read) - signed(memory_buffer));
				next_state <= sleep_1;
			when lt_0 =>
				sending <= '1';
				output <= encode_alu_result(identifier, signed(accumulator_read) < 0);
				next_state <= sleep_1;
			when eq_0 =>
				sending <= '1';
				output <= encode_alu_result(identifier, signed(accumulator_read) = 0);
				next_state <= sleep_1;
			when gt_0 =>
				sending <= '1';
				output <= encode_alu_result(identifier, signed(accumulator_read) > 0);
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
