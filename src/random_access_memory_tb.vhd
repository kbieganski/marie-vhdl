library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;
use work.global_constants.all;
use work.utility.all;

entity random_access_memory_tb is
end random_access_memory_tb;

architecture behavioral of random_access_memory_tb is
	component random_access_memory is
		generic
			(identifier:	   std_logic_vector(3 downto 0);
			 memory_buffer_id: std_logic_vector(3 downto 0));
		port
			(system_bus:	 inout std_logic_vector(word_width - 1 downto 0);
			 clk:			 in	   std_logic;
			 memory_address: in	   std_logic_vector(address_width - 1 downto 0));
	end component;

	component generic_register
		generic
			(identifier:	 std_logic_vector(3 downto 0);
			 register_width: natural);
		port
			(system_bus: inout std_logic_vector(bus_width - 1 downto 0);
			 clk:		 in	   std_logic;
			 aux_write:	 in	   std_logic_vector(register_width - 1 downto 0);
			 aux_read:	 out   std_logic_vector(register_width - 1 downto 0));
	end component;

	constant clk_period: time := 10 ns;

	signal clk: std_logic := '0';

	signal system_bus:	  std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_write_mar: std_logic_vector(address_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mar:  std_logic_vector(address_width - 1 downto 0);
	signal aux_write_mbr: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mbr:  std_logic_vector(word_width - 1 downto 0);

begin
	uut_ram: random_access_memory
		generic map
		(identifier		  => x"0",
		 memory_buffer_id => x"B")
		port map
		(system_bus		=> system_bus,
		 clk			=> clk,
		 memory_address => aux_read_mar);

	uut_mar: generic_register
		generic map
		(identifier		=> x"A",
		 register_width => address_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_mar,
		 aux_read	=> aux_read_mar);

	uut_mbr: generic_register
		generic map
		(identifier		=> x"B",
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_mbr,
		 aux_read	=> aux_read_mbr);

	clock: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	stimulus: process
		constant max_address: natural := 2 ** address_width - 1;
	begin
		for i in 0 to max_address loop
			aux_write_mar <= std_logic_vector(to_unsigned(i, address_width));
			aux_write_mbr <= std_logic_vector(to_unsigned(max_address - i, word_width));
			system_bus <= encode_ram_cmd(x"0", '0');
			wait for clk_period;
			aux_write_mar <= (others => 'Z');
			aux_write_mbr <= (others => 'Z');
			system_bus <= (others => 'Z');
			wait for 3 * clk_period;
		end loop;

		wait for clk_period;

		for i in 0 to 2 ** address_width - 1 loop
			aux_write_mar <= std_logic_vector(to_unsigned(i, address_width));
			system_bus <= encode_ram_cmd(x"0", '1');
			wait for clk_period;
			aux_write_mar <= (others => 'Z');
			system_bus <= (others => 'Z');
			wait for 2.5 * clk_period;
			assert aux_read_mbr = std_logic_vector(to_unsigned(max_address - i, word_width)) report "Incorrect value at address " & integer'image(i);
			wait for 0.5 * clk_period;
		end loop;

        finish(0);
	end process;

end behavioral;
