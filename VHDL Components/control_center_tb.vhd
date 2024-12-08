library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_center_tb is
end control_center_tb;

architecture Behavioral of control_center_tb is
    component control_center
        Port (
            CLK              : in std_logic;
            RESET            : in std_logic;
            instruction      : in std_logic_vector(7 downto 0);
            active_report    : out std_logic_vector(63 downto 0)
        );
    end component;
    
    --sinyal untuk input
    signal CLK           : std_logic := '0';
    signal RESET         : std_logic := '0';
    signal instruction   : std_logic_vector(7 downto 0) := (others => '0');
    
    --sinyal untuk output
    signal active_report : std_logic_vector(63 downto 0);
    
    constant CLK_period  : time := 10 ns;
    
    --instruction yang akan dites
    type instruction_array is array(0 to 2) of std_logic_vector(7 downto 0);
    constant TEST_INSTRUCTIONS : instruction_array := (
        "01000001",  -- station 1, idle
        "10000010",  -- station 2, run all
        "11000110"   -- station 3, run temp only
    );
    
begin
    --uut (unit under test), yakni control_center
    uut: control_center 
        PORT MAP (
        CLK => CLK,
        RESET => RESET,
        instruction => instruction,
        active_report => active_report
    );

    -- proses clock
    CLK_process: process
    begin
        CLK <= '0';
        wait for CLK_period/2;
        CLK <= '1';
        wait for CLK_period/2;
    end process;

    -- proses stimulus
    stim_proc: process
    begin
        -- akan reset selama 100ns
        RESET <= '1';
        wait for 100 ns;
        RESET <= '0';

        wait for CLK_period * 5;
        
        -- memberikan instruksi secara berurutan
        for i in TEST_INSTRUCTIONS'range loop
            instruction <= TEST_INSTRUCTIONS(i);
            wait for CLK_period;
            
            instruction <= (others => '0');
            
            wait for CLK_period * 20;
        end loop;
        
        --melanjutkan simulasi untuk waktu yang cukup lama
        wait for CLK_period * 1000;
        
        -- End simulation
        report "Simulation completed" severity failure;
    end process;
 
end Behavioral;