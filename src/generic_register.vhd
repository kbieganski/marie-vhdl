library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_register is
    generic
        (identifier:     std_logic_vector(3 downto 0);
         register_width: natural;
		 bus_width:      natural);
    port
        (system_bus: inout std_logic_vector(bus_width - 1 downto 0);
         clk:        in    std_logic;
         aux_write:  in    std_logic_vector(register_width - 1 downto 0);
         aux_read:   out   std_logic_vector(register_width - 1 downto 0));
end generic_register;

architecture behavioral of generic_register is
    signal value: std_logic_vector(register_width - 1 downto 0);
    signal input: std_logic_vector(bus_width - 1 downto 0);

    type state_t is (idle, load, send, sleep_3, sleep_2, sleep_1);
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

    state_logic: process(curr_state, input, aux_write)
    begin
        if aux_write /= (register_width - 1 downto 0 => 'Z') then
			value <= aux_write;
		end if;
        case curr_state is
            when idle =>
				sending <= '0';
				if input(bus_width - 1) = '1' then
					if input(3 downto 0) = identifier then
						next_state <= send;
					elsif input(7 downto 4) = identifier then
						next_state <= load;
					else
						next_state <= sleep_3;
					end if;
				end if;
            when load =>
				value <= input(register_width - 1 downto 0);
				next_state <= sleep_2;
            when send =>
				sending <= '1';
				next_state <= sleep_2;
			when sleep_3 =>
                next_state <= sleep_2;
			when sleep_2 =>
				sending <= '0';
                next_state <= sleep_1;
			when sleep_1 =>
                next_state <= idle;
        end case;
    end process;

    input <= system_bus when sending = '0' else (others => 'Z');
    system_bus(register_width - 1 downto 0) <= value when sending = '1' else (others => 'Z');
	aux_read <= value;

end behavioral;
