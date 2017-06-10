library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_constants.all;
use work.utility.all;

entity controller_tb is
end controller_tb;

architecture behavioral of controller_tb is
	component controller is
		generic
			(identifier:		 std_logic_vector(3 downto 0);
			 program_counter_id: std_logic_vector(3 downto 0);
			 instruction_reg_id: std_logic_vector(3 downto 0);
			 alu_id:			 std_logic_vector(3 downto 0);
			 ram_id:			 std_logic_vector(3 downto 0);
			 accumulator_id:	 std_logic_vector(3 downto 0);
			 memory_address_id:	 std_logic_vector(3 downto 0);
			 memory_buffer_id:	 std_logic_vector(3 downto 0));
		port
			(system_bus:			inout std_logic_vector(word_width - 1 downto 0);
			 clk:					in	  std_logic;
			 program_counter_read:	in	  std_logic_vector(word_width - 5 downto 0);
			 program_counter_write: out	  std_logic_vector(word_width - 5 downto 0);
			 instruction:			in	  std_logic_vector(word_width - 1 downto 0));
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
	constant ctrlr_id:	 std_logic_vector(3 downto 0) := x"0";
	constant alu_id:	 std_logic_vector(3 downto 0) := x"1";
	constant ram_id:	 std_logic_vector(3 downto 0) := x"2";
	constant acc_id:	 std_logic_vector(3 downto 0) := x"3";
	constant mar_id:	 std_logic_vector(3 downto 0) := x"4";
	constant mbr_id:	 std_logic_vector(3 downto 0) := x"5";
	constant pc_id:		 std_logic_vector(3 downto 0) := x"6";
	constant ir_id:		 std_logic_vector(3 downto 0) := x"7";

	signal clk: std_logic := '0';

	signal system_bus:	  std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_acc:  std_logic_vector(word_width - 1 downto 0);
	signal aux_write_acc: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mar:  std_logic_vector(address_width - 1 downto 0);
	signal aux_write_mar: std_logic_vector(address_width - 1 downto 0) := (others => 'Z');
	signal aux_read_mbr:  std_logic_vector(word_width - 1 downto 0);
	signal aux_write_mbr: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
	signal aux_read_pc:	  std_logic_vector(address_width - 1 downto 0);
	signal aux_write_pc:  std_logic_vector(address_width - 1 downto 0) := (others => 'Z');
	signal aux_read_ir:	  std_logic_vector(word_width - 1 downto 0);
	signal aux_write_ir:  std_logic_vector(word_width - 1 downto 0) := (others => 'Z');

	procedure fetch_decode(signal system_bus: std_logic_vector(word_width - 1 downto 0); signal aux_write_mbr: out std_logic_vector(word_width - 1 downto 0); instruction: std_logic_vector(word_width - 1 downto 0)) is
	begin
		wait for 1.5 * clk_period;
		assert system_bus = encode_send_cmd(pc_id, mar_id) report "Incorrect command; should request sending from PC to MAR";
		wait for 4 * clk_period;
		assert system_bus = encode_ram_cmd(ram_id, '1') report "Incorrect command; should request loading from RAM";
		wait for 3.5 * clk_period;
		aux_write_mbr <= instruction;
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(mbr_id, ir_id) report "Incorrect command; should request sending from MBR to IR";
		wait for 0.5 * clk_period;
		aux_write_mbr <= (others => 'Z');
		wait for 3 * clk_period;
	end procedure;

begin
	uut_ctrlr: controller
		generic map
		(identifier			=> ctrlr_id,
		 program_counter_id => pc_id,
		 instruction_reg_id => ir_id,
		 alu_id				=> alu_id,
		 ram_id				=> ram_id,
		 accumulator_id		=> acc_id,
		 memory_address_id	=> mar_id,
		 memory_buffer_id	=> mbr_id)
		port map
		(system_bus			   => system_bus,
		 clk				   => clk,
		 program_counter_read  => aux_read_pc,
		 program_counter_write => aux_write_pc,
		 instruction		   => aux_read_mbr);

	uut_acc: generic_register
		generic map
		(identifier		=> acc_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_acc,
		 aux_read	=> aux_read_acc);

	uut_mar: generic_register
		generic map
		(identifier		=> mar_id,
		 register_width => address_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_mar,
		 aux_read	=> aux_read_mar);

	uut_mbr: generic_register
		generic map
		(identifier		=> mbr_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_mbr,
		 aux_read	=> aux_read_mbr);

	uut_pc: generic_register
		generic map
		(identifier		=> pc_id,
		 register_width => address_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_pc,
		 aux_read	=> aux_read_pc);

	uut_ir: generic_register
		generic map
		(identifier		=> ir_id,
		 register_width => word_width)
		port map
		(system_bus => system_bus,
		 clk		=> clk,
		 aux_write	=> aux_write_ir,
		 aux_read	=> aux_read_ir);

	clock: process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	stimulus: process
	begin
		-- Test Load
		fetch_decode(system_bus, aux_write_mbr, x"1ABC");
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(ctrlr_id, mar_id) report "Incorrect command; should be sending to MAR";
		wait for clk_period;
		assert system_bus = x"0ABC" report "Incorrect value sent to MAR";
		wait for 3 * clk_period;
		assert system_bus = encode_ram_cmd(ram_id, '1') report "Incorrect command; should request loading from RAM";
		wait for 3.5 * clk_period;
		aux_write_mbr <= x"CDEF";
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(mbr_id, acc_id) report "Incorrect command; should request sending from MBR to ACC";
		wait for 0.5 * clk_period;
		aux_write_mbr <= (others => 'Z');

		-- Test Store
		wait for 3 * clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"2ABC");
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(ctrlr_id, mar_id) report "Incorrect command; should be sending to MAR";
		wait for clk_period;
		assert system_bus = x"0ABC" report "Incorrect value sent to MAR";
		wait for 2.5 * clk_period;
		aux_write_mbr <= x"CDEF";
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(acc_id, mbr_id) report "Incorrect command; should request sending from ACC to MBR";
		wait for 0.5 * clk_period;
		aux_write_mbr <= (others => 'Z');
		wait for 3.5 * clk_period;
		assert system_bus = encode_ram_cmd(ram_id, '0') report "Incorrect command; should request storing to RAM";
		wait for 0.5 * clk_period;

		-- Test Add
		wait for 3 * clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"3ABC");
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(ctrlr_id, mar_id) report "Incorrect command; should be sending to MAR";
		wait for clk_period;
		assert system_bus = x"0ABC" report "Incorrect value sent to MAR";
		wait for 3 * clk_period;
		assert system_bus = encode_ram_cmd(ram_id, '1') report "Incorrect command; should request loading from RAM";
		wait for 3.5 * clk_period;
		aux_write_mbr <= x"CDEF";
		wait for 0.5 * clk_period;
		assert system_bus = encode_alu_cmd(alu_id, "000") report "Incorrect command; should request addition from ALU";
		wait for 0.5 * clk_period;
		aux_write_mbr <= (others => 'Z');

		-- Test Subt
		wait for 3 * clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"4ABC");
		wait for 0.5 * clk_period;
		assert system_bus = encode_send_cmd(ctrlr_id, mar_id) report "Incorrect command; should be sending to MAR";
		wait for clk_period;
		assert system_bus = x"0ABC" report "Incorrect value sent to MAR";
		wait for 3 * clk_period;
		assert system_bus = encode_ram_cmd(ram_id, '1') report "Incorrect command; should request loading from RAM";
		wait for 3.5 * clk_period;
		aux_write_mbr <= x"CDEF";
		wait for 0.5 * clk_period;
		assert system_bus = encode_alu_cmd(alu_id, "001") report "Incorrect command; should request subtraction from ALU";
		wait for 0.5 * clk_period;
		aux_write_mbr <= (others => 'Z');

		-- Test Skipcond
		wait for 3 * clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"8400");
		wait for 0.5 * clk_period;
		assert system_bus = encode_alu_cmd(alu_id, "101") report "Incorrect command; should be asking ALU if ACC = 0";
		wait for 0.5 * clk_period;
		system_bus <= encode_alu_result(alu_id, true);
		wait for clk_period;
		system_bus <= (others => 'Z');
		wait for 0.5 * clk_period;
		assert unsigned(aux_read_pc) = 5 report "Incorrect value of PC; should equal 5";
		wait for 0.5 * clk_period;

		-- Test Jump
		wait for clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"9ABC");
		wait for 0.5 * clk_period;
		assert aux_read_pc = x"ABC" report "Incorrect value of PC; should equal ABC";

		-- Test Halt
		wait for 0.5 * clk_period;
		fetch_decode(system_bus, aux_write_mbr, x"7000");
	end process;

end behavioral;
