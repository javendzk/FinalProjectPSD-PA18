library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_center_tb is
end control_center_tb;

architecture behavior of Testbench is

    signal CLK         : std_logic := '0';
    signal RESET       : std_logic := '0';
    signal packet_in   : std_logic_vector(63 downto 0);
    signal data_ready  : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin
    uut: entity work.control_center
        Port map (
            CLK => CLK,
            RESET => RESET,
            packet_in => packet_in,
            data_ready => data_ready,
        );

    CLK_GEN: process
    begin
        CLK <= '0';
        wait for CLK_PERIOD/2;
        CLK <= '1';
        wait for CLK_PERIOD/2;
    end process;

    STIMULUS: process
    begin
        RESET <= '1';
        wait for 20 ns;
        RESET <= '0';

        packet_in <= "1101000000011100000000000000000000000000000000000000000000000000"; 
        data_ready <= '1';
        wait for CLK_PERIOD;

        packet_in <= "0101000000010101000000000000000000000000000000000000000000000000"; 
        data_ready <= '1';
        wait for CLK_PERIOD;

        wait for 100 ns;
        $stop; 
    end process;

end behavior;
