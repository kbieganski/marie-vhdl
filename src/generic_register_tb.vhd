library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_register_tb is
end generic_register_tb;

architecture behavioral of generic_register_tb is
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
    constant bus_width:  natural := 16;

    signal clk: std_logic := '0';

    signal system_bus:  std_logic_vector(bus_width - 1 downto 0) := (others => 'Z');
    signal aux_write_a: std_logic_vector(bus_width - 1 downto 0) := (others => 'Z');
    signal aux_write_b: std_logic_vector(bus_width - 1 downto 0) := (others => 'Z');
    signal aux_read_a:  std_logic_vector(bus_width - 1 downto 0);
    signal aux_read_b:  std_logic_vector(bus_width - 1 downto 0);

begin
    uut_a: generic_register
        generic map
        (identifier     => x"A",
         register_width => bus_width,
         bus_width      => bus_width)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_a,
         aux_read   => aux_read_a);

    uut_b: generic_register
        generic map
        (identifier     => x"B",
         register_width => bus_width,
         bus_width      => bus_width)
        port map
        (system_bus => system_bus,
         clk        => clk,
         aux_write  => aux_write_b,
         aux_read   => aux_read_b);

    clock: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stimulus: process
        constant test_value1: std_logic_vector(bus_width - 1 downto 0) := x"CDEF";
        constant test_value2: std_logic_vector(bus_width - 1 downto 0) := x"FEDC";
    begin
        aux_write_a <= test_value1;
        wait for clk_period;
        aux_write_a <= (others => 'Z');

        system_bus(bus_width - 1) <= '1';
        system_bus(3 downto 0) <= x"A";
        system_bus(7 downto 4) <= x"B";
        system_bus(bus_width - 2 downto 8) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');

        wait for clk_period;
        assert aux_read_b = test_value1 report "Incorrect value in receiving register (B)";

        wait for clk_period;

        aux_write_b <= test_value2;
        wait for clk_period;
        aux_write_b <= (others => 'Z');

        system_bus(bus_width - 1) <= '1';
        system_bus(3 downto 0) <= x"B";
        system_bus(7 downto 4) <= x"A";
        system_bus(bus_width - 2 downto 8) <= (others => '0');
        wait for clk_period;
        system_bus <= (others => 'Z');

        wait for clk_period;
        assert aux_read_a = test_value2 report "Incorrect value in receiving register (A)";

        wait;
    end process;

end behavioral;
