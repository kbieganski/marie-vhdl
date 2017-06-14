library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_constants.all;
use work.utility.all;
use std.env.all;
use std.textio.all;

entity marie is
end marie;

architecture behavioral of marie is
	component controller is
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
			 program_counter_write: out   std_logic_vector(word_width - 5 downto 0);
			 instruction:           in    std_logic_vector(word_width - 1 downto 0);
			 running:               in    std_logic);
	end component;

	component arithmetic_logic_unit is
		generic
			(identifier: std_logic_vector(3 downto 0));
		port
			(system_bus:        inout std_logic_vector(word_width - 1 downto 0);
			 clk:               in    std_logic;
			 accumulator_read:  in    std_logic_vector(word_width - 1 downto 0);
			 accumulator_write: out   std_logic_vector(word_width - 1 downto 0);
			 memory_buffer:     in    std_logic_vector(word_width - 1 downto 0));
	end component;

	component random_access_memory is
		generic
			(identifier:       std_logic_vector(3 downto 0);
			 memory_buffer_id: std_logic_vector(3 downto 0));
		port
			(system_bus:     inout std_logic_vector(word_width - 1 downto 0);
			 clk:            in    std_logic;
			 memory_address: in    std_logic_vector(address_width - 1 downto 0));
	end component;

	component generic_register
		generic
			(identifier:     std_logic_vector(3 downto 0);
			 register_width: natural);
		port
			(system_bus: inout std_logic_vector(bus_width - 1 downto 0);
			 clk:        in    std_logic;
			 aux_write:  in    std_logic_vector(register_width - 1 downto 0);
			 aux_read:   out   std_logic_vector(register_width - 1 downto 0));
	end component;

	constant clk_period: time := 10 ns;
	constant ctrlr_id:   std_logic_vector(3 downto 0) := x"0";
	constant alu_id:     std_logic_vector(3 downto 0) := x"1";
	constant ram_id:     std_logic_vector(3 downto 0) := x"2";
	constant acc_id:     std_logic_vector(3 downto 0) := x"3";
	constant mar_id:     std_logic_vector(3 downto 0) := x"4";
	constant mbr_id:     std_logic_vector(3 downto 0) := x"5";
	constant pc_id:      std_logic_vector(3 downto 0) := x"6";
	constant ir_id:      std_logic_vector(3 downto 0) := x"7";
	constant in_id:      std_logic_vector(3 downto 0) := x"8";
	constant out_id:     std_logic_vector(3 downto 0) := x"9";

	signal clk:     std_logic := '0';
	signal running: std_logic := '0';

	signal system_bus:    std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_acc:  std_logic_vector(word_width - 1 downto 0);
	signal aux_write_acc: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mar:  std_logic_vector(address_width - 1 downto 0);
	signal aux_write_mar: std_logic_vector(address_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mbr:  std_logic_vector(word_width - 1 downto 0);
	signal aux_write_mbr: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_pc:   std_logic_vector(address_width - 1 downto 0);
	signal aux_write_pc:  std_logic_vector(address_width - 1 downto 0) := (others => 'Z');
	signal aux_read_ir:   std_logic_vector(word_width - 1 downto 0);
	signal aux_write_ir:  std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
    signal aux_read_in:   std_logic_vector(word_width / 2 - 1 downto 0);
	signal aux_write_in:  std_logic_vector(word_width / 2 - 1 downto 0) := (others => 'Z');
    signal aux_read_out:  std_logic_vector(word_width / 2 - 1 downto 0);
	signal aux_write_out: std_logic_vector(word_width / 2 - 1 downto 0) := (others => 'Z');

	procedure load_value(signal sb:	 out std_logic_vector(bus_width - 1 downto 0);
	                     signal mar: out std_logic_vector(address_width - 1 downto 0);
	                     signal mbr: out std_logic_vector(word_width - 1 downto 0);
	                     i: integer; value: std_logic_vector(word_width - 1 downto 0)) is
	begin
		mar <= std_logic_vector(to_signed(i, address_width));
		mbr <= value;
		wait for clk_period;
		mar <= (others => 'Z');
		mbr <= (others => 'Z');
		sb <= encode_ram_cmd(ram_id, '0');
		wait for clk_period;
		sb <= (others => 'Z');
		wait for 2 * clk_period;
	end;

	procedure load_value(signal sb:	 out std_logic_vector(bus_width - 1 downto 0);
	                     signal mar: out std_logic_vector(address_width - 1 downto 0);
	                     signal mbr: out std_logic_vector(word_width - 1 downto 0);
	                     i: integer; value: integer) is
	begin
		load_value(sb, mar, mbr, i, std_logic_vector(to_signed(value, word_width)));
	end;

	procedure load_instruction(signal sb:  out std_logic_vector(bus_width - 1 downto 0);
	                           signal mar: out std_logic_vector(address_width - 1 downto 0);
	                           signal mbr: out std_logic_vector(word_width - 1 downto 0);
	                           i: integer; op: std_logic_vector(3 downto 0)) is
		variable instruction: std_logic_vector(word_width - 1 downto 0);
	begin
		instruction(word_width - 1 downto word_width - 4) := op;
		instruction(word_width - 5 downto 0) := (others => '0');
		load_value(sb, mar, mbr, i, instruction);
	end;

	procedure load_instruction(signal sb:  out std_logic_vector(bus_width - 1 downto 0);
	                           signal mar: out std_logic_vector(address_width - 1 downto 0);
	                           signal mbr: out std_logic_vector(word_width - 1 downto 0);
	                           i: integer; op: std_logic_vector(3 downto 0); arg: integer) is
		variable instruction: std_logic_vector(word_width - 1 downto 0);
	begin
		instruction(word_width - 1 downto word_width - 4) := op;
		if op = x"8" then
			instruction(word_width - 5 downto word_width - 6) := std_logic_vector(to_signed(arg, 2));
			instruction(word_width - 7 downto 0) := (others => '0');
		else
			instruction(word_width - 5 downto 0) := std_logic_vector(to_signed(arg, address_width));
		end if;
		load_value(sb, mar, mbr, i, instruction);
	end;

	procedure load_program(signal sb:  out std_logic_vector(bus_width - 1 downto 0);
	                       signal mar: out std_logic_vector(address_width - 1 downto 0);
	                       signal mbr: out std_logic_vector(word_width - 1 downto 0);
	                       filename: string) is
		file	 code: text open read_mode is filename;
		variable loc:  line;
		variable i:	   integer := 0;
	begin
		wait for clk_period;
		while not endfile(code) loop
			readline(code, loc);
			if loc.all'length >= 5 and loc(1 to 5) = "Load " then
				load_instruction(sb, mar, mbr, i, x"1", integer'value(loc(6 to loc.all'length)));
			elsif loc.all'length >= 6 and loc(1 to 6) = "Store " then
				load_instruction(sb, mar, mbr, i, x"2", integer'value(loc(7 to loc.all'length)));
			elsif loc.all'length >= 4 and loc(1 to 4) = "Add " then
				load_instruction(sb, mar, mbr, i, x"3", integer'value(loc(5 to loc.all'length)));
			elsif loc.all'length >= 5 and loc(1 to 5) = "Subt " then
				load_instruction(sb, mar, mbr, i, x"4", integer'value(loc(6 to loc.all'length)));
			elsif loc.all'length >= 5 and loc(1 to 5) = "Input" then
				load_instruction(sb, mar, mbr, i, x"5");
			elsif loc.all'length >= 6 and loc(1 to 6) = "Output" then
				load_instruction(sb, mar, mbr, i, x"6");
			elsif loc.all'length >= 4 and loc(1 to 4) = "Halt" then
				load_instruction(sb, mar, mbr, i, x"7");
			elsif loc.all'length >= 9 and loc(1 to 9) = "Skipcond " then
				load_instruction(sb, mar, mbr, i, x"8", integer'value(loc(10 to loc.all'length)));
			elsif loc.all'length >= 5 and loc(1 to 5) = "Jump " then
				load_instruction(sb, mar, mbr, i, x"9", integer'value(loc(6 to loc.all'length)));
			else
				load_value(sb, mar, mbr, i, integer'value(loc(1 to loc.all'length)));
			end if;
			i := i + 1;
		end loop;
	end;

begin
	uut_ctrlr: controller
		generic map
		(identifier         => ctrlr_id,
		 program_counter_id => pc_id,
		 instruction_reg_id => ir_id,
		 alu_id             => alu_id,
		 ram_id             => ram_id,
		 accumulator_id     => acc_id,
		 memory_address_id  => mar_id,
		 memory_buffer_id   => mbr_id)
		port map
		(system_bus            => system_bus,
		 clk                   => clk,
		 program_counter_read  => aux_read_pc,
		 program_counter_write => aux_write_pc,
		 instruction           => aux_read_ir,
		 running               => running);

	uut_alu: arithmetic_logic_unit
		generic map
		(identifier => alu_id)
		port map
		(system_bus        => system_bus,
		 clk               => clk,
		 accumulator_read  => aux_read_acc,
		 accumulator_write => aux_write_acc,
		 memory_buffer     => aux_read_mbr);

	uut_ram: random_access_memory
		generic map
		(identifier       => ram_id,
		 memory_buffer_id => mbr_id)
		port map
		(system_bus     => system_bus,
		 clk            => clk,
		 memory_address => aux_read_mar);

	uut_acc: generic_register
		generic map
		(identifier     => acc_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk        => clk,
		 aux_write  => aux_write_acc,
		 aux_read   => aux_read_acc);

	uut_mar: generic_register
		generic map
		(identifier     => mar_id,
		 register_width => address_width)
		port map
		(system_bus => system_bus,
		 clk        => clk,
		 aux_write  => aux_write_mar,
		 aux_read   => aux_read_mar);

	uut_mbr: generic_register
		generic map
		(identifier     => mbr_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk        => clk,
		 aux_write  => aux_write_mbr,
		 aux_read   => aux_read_mbr);

	uut_pc: generic_register
		generic map
		(identifier     => pc_id,
		 register_width => address_width)
		port map
		(system_bus => system_bus,
		 clk        => clk,
		 aux_write  => aux_write_pc,
		 aux_read   => aux_read_pc);

	uut_ir: generic_register
		generic map
		(identifier     => ir_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk        => clk,
		 aux_write  => aux_write_ir,
		 aux_read   => aux_read_ir);

	uut_in: generic_register
        generic map
        (identifier     => in_id,
         register_width => word_width / 2)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_in,
         aux_read   => aux_read_in);

	uut_out: generic_register
        generic map
        (identifier     => out_id,
         register_width => word_width / 2)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_out,
         aux_read   => aux_read_out);

	clock: process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process;

	stimulus: process
	begin
		load_program(system_bus, aux_write_mar, aux_write_mbr, "STD_INPUT");
		running <= '1';
		wait;
	end process;

end behavioral;
