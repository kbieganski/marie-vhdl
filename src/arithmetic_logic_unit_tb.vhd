library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arithmetic_logic_unit_tb is
end arithmetic_logic_unit_tb;

architecture behavioral of arithmetic_logic_unit_tb is
    component arithmetic_logic_unit is
        generic
            (identifier:       std_logic_vector(3 downto 0);
             word_width:       natural);
        port
            (system_bus:        inout std_logic_vector(word_width - 1 downto 0);
             clk:               in    std_logic;
             accumulator_read:  in    std_logic_vector(word_width - 1 downto 0);
             accumulator_write: out   std_logic_vector(word_width - 1 downto 0);
             memory_buffer:     in    std_logic_vector(word_width - 1 downto 0));
    end component;

    component generic_register
        generic
            (identifier:     std_logic_vector(3 downto 0);
             register_width: natural;
             bus_width:      natural);
        port
            (system_bus: inout std_logic_vector(bus_width - 1 downto 0);
             clk:        in    std_logic;
             aux_write:  in    std_logic_vector(register_width - 1 downto 0);
             aux_read:   out   std_logic_vector(register_width - 1 downto 0));
    end component;

    constant clk_period: time    := 10 ns;
    constant word_width: natural := 16;

    signal clk: std_logic := '0';

    signal system_bus:    std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
    signal aux_read_acc:  std_logic_vector(word_width - 1 downto 0);
    signal aux_write_acc: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');
    signal aux_read_mbr:  std_logic_vector(word_width - 1 downto 0);
    signal aux_write_mbr: std_logic_vector(word_width - 1 downto 0) := (others => 'Z');

begin
    uut_alu: arithmetic_logic_unit
        generic map
        (identifier => x"0",
         word_width => word_width)
        port map
        (system_bus        => system_bus,
         clk               => clk,
         accumulator_read  => aux_read_acc,
         accumulator_write => aux_write_acc,
         memory_buffer     => aux_read_mbr);

    uut_acc: generic_register
        generic map
        (identifier     => x"A",
         register_width => word_width,
         bus_width      => word_width)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_acc,
         aux_read   => aux_read_acc);

    uut_mbr: generic_register
        generic map
        (identifier     => x"B",
         register_width => word_width,
         bus_width      => word_width)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_mbr,
         aux_read   => aux_read_mbr);

    clock: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stimulus: process
        constant test_value1:     std_logic_vector(word_width - 1 downto 0) := x"0065";
        constant test_value2:     std_logic_vector(word_width - 1 downto 0) := x"009B";
        constant test_value_neg:  std_logic_vector(word_width - 1 downto 0) := x"FFFF";
        constant test_value_zero: std_logic_vector(word_width - 1 downto 0) := x"0000";
        constant test_value_pos:  std_logic_vector(word_width - 1 downto 0) := x"0001";
    begin
        aux_write_acc <= test_value1;
        aux_write_mbr <= test_value2;
        wait for clk_period;
        aux_write_acc <= (others => 'Z');
        aux_write_mbr <= (others => 'Z');
        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "000";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period;
        assert aux_read_acc = std_logic_vector(signed(test_value1) + signed(test_value2)) report "Incorrect result of addition";

        wait for clk_period;

        aux_write_acc <= test_value1;
        aux_write_mbr <= test_value2;
        wait for clk_period;
        aux_write_acc <= (others => 'Z');
        aux_write_mbr <= (others => 'Z');
        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "001";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period;
        assert aux_read_acc = std_logic_vector(signed(test_value1) - signed(test_value2)) report "Incorrect result of addition";

        wait for clk_period;

        aux_write_acc <= test_value_neg;
        wait for clk_period;
        aux_write_acc <= (others => 'Z');

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "100";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '1') report "False negative result of checking if number is less than 0";

        wait for 1.5 * clk_period;

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "101";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '0') report "False positive result of checking if number is equal to 0";

        wait for 1.5 * clk_period;

        aux_write_acc <= test_value_zero;
        wait for clk_period;
        aux_write_acc <= (others => 'Z');

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "101";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '1') report "False negative result of checking if number is equal to 0";

        wait for 1.5 * clk_period;

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "110";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '0') report "False positive result of checking if number is greater than 0";

        wait for 1.5 * clk_period;

        aux_write_acc <= test_value_pos;
        wait for clk_period;
        aux_write_acc <= (others => 'Z');

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "110";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '1') report "False negative result of checking if number is greater than 0";

        wait for 1.5 * clk_period;

        system_bus(word_width - 1) <= '0';
        system_bus(word_width - 2 downto word_width - 4) <= "100";
        system_bus(word_width - 5 downto 0) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');
        wait for clk_period / 2;
        assert system_bus(word_width - 2 downto 4) = (word_width - 2 downto 4 => '0') report "False positive result of checking if number is less than 0";

        wait;
    end process;

end behavioral;
