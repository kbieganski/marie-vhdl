library ieee;
use ieee.std_logic_1164.all;
use work.global_constants.all;

package utility is
	function encode_alu_cmd(alu_id: std_logic_vector(3 downto 0); cmd: std_logic_vector(2 downto 0)) return std_logic_vector;
	function encode_alu_result(alu_id: std_logic_vector(3 downto 0); result: boolean) return std_logic_vector;
	function encode_ram_cmd(ram_id: std_logic_vector(3 downto 0); cmd: std_logic) return std_logic_vector;
	function encode_send_cmd(src_id: std_logic_vector(3 downto 0); dest_id: std_logic_vector(3 downto 0)) return std_logic_vector;
	function encode_ui_cmd(ui_id: std_logic_vector(3 downto 0); cmd: std_logic) return std_logic_vector;
	function decode_alu_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector;
	function decode_alu_result(bus_value: std_logic_vector(word_width - 1 downto 0)) return boolean;
	function decode_ram_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic;
	function decode_send_src(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector;
	function decode_send_dest(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector;
	function decode_ui_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic;
	function is_cmd_for(bus_value: std_logic_vector(word_width - 1 downto 0); id: std_logic_vector(3 downto 0)) return boolean;
	function is_send_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return boolean;

end package;

package body utility is
	function encode_alu_cmd(alu_id: std_logic_vector(3 downto 0); cmd: std_logic_vector(2 downto 0)) return std_logic_vector is
		variable enc: std_logic_vector(word_width - 1 downto 0);
	begin
		enc(word_width - 1) := '0';
		enc(word_width - 2 downto word_width - 4) := cmd;
		enc(word_width - 5 downto 4) := (others => '0');
		enc(3 downto 0) := alu_id;
		return enc;
	end function;

	function encode_alu_result(alu_id: std_logic_vector(3 downto 0); result: boolean) return std_logic_vector is
		variable enc: std_logic_vector(word_width - 1 downto 0);
	begin
		enc(word_width - 1) := '0';
		if result then
			enc(word_width - 2 downto 4) := (others => '1');
		else
			enc(word_width - 2 downto 4) := (others => '0');
		end if;
		enc(3 downto 0) := alu_id;
		return enc;
	end function;

	function encode_ram_cmd(ram_id: std_logic_vector(3 downto 0); cmd: std_logic) return std_logic_vector is
		variable enc: std_logic_vector(word_width - 1 downto 0);
	begin
		enc(word_width - 1) := '0';
		enc(word_width - 2) := cmd;
		enc(word_width - 3 downto 4) := (others => '0');
		enc(3 downto 0) := ram_id;
		return enc;
	end function;

	function encode_send_cmd(src_id: std_logic_vector(3 downto 0); dest_id: std_logic_vector(3 downto 0)) return std_logic_vector is
		variable enc: std_logic_vector(word_width - 1 downto 0);
	begin
		enc(word_width - 1) := '1';
		enc(3 downto 0) := src_id;
		enc(7 downto 4) := dest_id;
		if word_width > 9 then
			enc(word_width - 2 downto 8) := (others => '0');
		end if;
		return enc;
	end function;

	function encode_ui_cmd(ui_id: std_logic_vector(3 downto 0); cmd: std_logic) return std_logic_vector is
		variable enc: std_logic_vector(word_width - 1 downto 0);
	begin
		enc(word_width - 1) := '0';
		enc(word_width - 2) := cmd;
		enc(word_width - 3 downto 4) := (others => '0');
		enc(3 downto 0) := ui_id;
		return enc;
	end function;

	function decode_alu_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector is
	begin
		return bus_value(word_width - 2 downto word_width - 4);
	end function;

	function decode_alu_result(bus_value: std_logic_vector(word_width - 1 downto 0)) return boolean is
	begin
		return bus_value(word_width - 2 downto 4) = (word_width - 2 downto 4 => '1');
	end function;

	function decode_ram_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic is
	begin
		return bus_value(word_width - 2);
	end function;

	function decode_send_src(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector is
	begin
		return bus_value(3 downto 0);
	end function;

	function decode_send_dest(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic_vector is
	begin
		return bus_value(7 downto 4);
	end function;

	function decode_ui_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return std_logic is
	begin
		return bus_value(word_width - 2);
	end function;

	function is_cmd_for(bus_value: std_logic_vector(word_width - 1 downto 0); id: std_logic_vector(3 downto 0)) return boolean is
	begin
		return bus_value(3 downto 0) = id;
	end function;

	function is_send_cmd(bus_value: std_logic_vector(word_width - 1 downto 0)) return boolean is
	begin
		return bus_value(word_width - 1) = '1';
	end function;

end package body;
