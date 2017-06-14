library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;
use work.global_constants.all;
use work.utility.all;

entity controller is
	generic
		(identifier:         std_logic_vector(3 downto 0);
		 program_counter_id: std_logic_vector(3 downto 0);
		 instruction_reg_id: std_logic_vector(3 downto 0);
		 alu_id:             std_logic_vector(3 downto 0);
		 ram_id:             std_logic_vector(3 downto 0);
		 accumulator_id:     std_logic_vector(3 downto 0);
		 memory_address_id:  std_logic_vector(3 downto 0);
		 memory_buffer_id:   std_logic_vector(3 downto 0));
	port
		(system_bus:            inout std_logic_vector(word_width - 1 downto 0);
		 clk:                   in    std_logic;
		 program_counter_read:  in    std_logic_vector(word_width - 5 downto 0);
		 program_counter_write: out   std_logic_vector(word_width - 5 downto 0) := (others => 'Z');
		 instruction:           in    std_logic_vector(word_width - 1 downto 0);
		 running:               in    std_logic);
end controller;

architecture behavioral of controller is
	signal input:  std_logic_vector(word_width - 1 downto 0);
	signal output: std_logic_vector(word_width - 1 downto 0);

	signal sending: std_logic := '0';

	procedure wait_cycles(cycles: natural) is
	begin
		for i in 1 to cycles loop
			wait until rising_edge(clk);
			wait until falling_edge(clk);
		end loop;
	end procedure;

	procedure load_to_memory_buffer(signal output: out std_logic_vector(word_width - 1 downto 0); signal sending: out std_logic; address: std_logic_vector(address_width - 1 downto 0)) is
	begin
		sending <= '1';
		output <= encode_send_cmd(identifier, memory_address_id);
		wait_cycles(1);
		output(word_width - 1 downto address_width) <= (others => '0');
		output(address_width - 1 downto 0) <= address;
		wait_cycles(2);
		sending <= '0';
		wait_cycles(1);

		sending <= '1';
		output <= encode_ram_cmd(ram_id, '1');
		wait_cycles(1);
		sending <= '0';
		wait_cycles(3);
	end procedure;

begin
	state_logic: process
		variable opcode: std_logic_vector(3 downto 0);
		variable oparg:	 std_logic_vector(address_width - 1 downto 0);
	begin
        wait until running = '1';
		program_counter_write <= (others => '0');
		loop
			wait_cycles(1);
			program_counter_write <= (others => 'Z');

			sending <= '1';
			output <= encode_send_cmd(program_counter_id, memory_address_id);
			wait_cycles(1);
			sending <= '0';
			wait_cycles(3);

			sending <= '1';
			output <= encode_ram_cmd(ram_id, '1');
			wait_cycles(1);
			sending <= '0';
			wait_cycles(3);

			sending <= '1';
			output <= encode_send_cmd(memory_buffer_id, instruction_reg_id);
			wait_cycles(1);
			sending <= '0';
			wait_cycles(3);

			opcode := instruction(word_width - 1 downto address_width);
			oparg  := instruction(address_width - 1 downto 0);

			if opcode = x"1" then -- Load
				load_to_memory_buffer(output, sending, oparg);
				sending <= '1';
				output <= encode_send_cmd(memory_buffer_id, accumulator_id);
				wait_cycles(1);
				sending <= '0';
				wait_cycles(3);
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);

			elsif opcode = x"2" then -- Store
				sending <= '1';
				output <= encode_send_cmd(identifier, memory_address_id);
				wait_cycles(1);
				output(word_width - 1 downto address_width) <= (others => '0');
				output(address_width - 1 downto 0) <= oparg;
				wait_cycles(1);
				sending <= '0';
				wait_cycles(2);

				sending <= '1';
				output <= encode_send_cmd(accumulator_id, memory_buffer_id);
				wait_cycles(1);
				sending <= '0';
				wait_cycles(3);

				sending <= '1';
				output <= encode_ram_cmd(ram_id, '0');
				wait_cycles(1);
				sending <= '0';
				wait_cycles(3);
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);

			elsif opcode = x"3" then -- Add
				load_to_memory_buffer(output, sending, oparg);
				sending <= '1';
				output <= encode_alu_cmd(alu_id, "000");
				wait_cycles(1);
				sending <= '0';
				wait_cycles(3);
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);

			elsif opcode = x"4" then -- Subt
				load_to_memory_buffer(output, sending, oparg);
				sending <= '1';
				output <= encode_alu_cmd(alu_id, "001");
				wait_cycles(1);
				sending <= '0';
				wait_cycles(3);
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);

			elsif opcode = x"5" then -- Input
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);
			elsif opcode = x"6" then -- Output
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);
			elsif opcode = x"7" then -- Halt
				finish(0);
			elsif opcode = x"8" then -- Skipcond
				sending <= '1';
				output <= encode_alu_cmd(alu_id, "1" & oparg(address_width - 1 downto address_width - 2));
				wait_cycles(1);
				sending <= '0';
				wait until rising_edge(clk);
				if decode_alu_result(input) then
					program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);
				end if;
				wait until falling_edge(clk);
				program_counter_write <= (others => 'Z');
				wait_cycles(2);
				program_counter_write <= std_logic_vector(unsigned(program_counter_read) + 1);

			elsif opcode = x"9" then -- Jump
				program_counter_write <= oparg;
				wait_cycles(1);
				program_counter_write <= (others => 'Z');
			end if;
		end loop;
	end process;

	input <= system_bus when sending = '0' else (others => 'Z');
	system_bus <= output when sending = '1' else (others => 'Z');

end behavioral;
