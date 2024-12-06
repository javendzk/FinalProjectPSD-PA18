library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity control_center_reporter is
end control_center_reporter;

architecture Behavioral of control_center_reporter is
    component control_center
        Port (
            CLK              : in std_logic;
            RESET            : in std_logic;
            instruction      : in std_logic_vector(7 downto 0);
            active_report    : out std_logic_vector(63 downto 0)
        );
    end component;
    
    signal CLK : std_logic := '0';
    signal RESET : std_logic := '0';
    --signal packet_in : std_logic_vector(63 downto 0) := (others => '0');
    signal instruction : std_logic_vector(7 downto 0) := (others => '0');
    
    signal active_report : std_logic_vector(63 downto 0);
    
    constant CLK_period : time := 10 ns;
    
    file output_file : text open write_mode is "control_center_report.csv";
    
    procedure write_csv_header(file output_file : text) is
        variable csv_line : line;
    begin
        write(csv_line, string'("Source,Status,Opcode,Timestamp,Temp Data,Light Data,Moisture Data"));
        writeline(output_file, csv_line);
    end procedure;
    
    procedure write_packet_to_csv(
        file output_file : text;
        signal active_report : in std_logic_vector(63 downto 0)
    ) is
        variable csv_line : line;
        variable source_v : std_logic_vector(1 downto 0);
        variable status_v : std_logic_vector(1 downto 0);
        variable opcode_v : std_logic_vector(5 downto 0);
        variable timestamp_v : std_logic_vector(5 downto 0);
        variable temp_data_v : std_logic_vector(15 downto 0);
        variable light_data_v : std_logic_vector(15 downto 0);
        variable moist_data_v : std_logic_vector(15 downto 0);
    begin
        source_v := active_report(63 downto 62);
        status_v := active_report(61 downto 60);
        opcode_v := active_report(59 downto 54);
        timestamp_v := active_report(53 downto 48);
        temp_data_v := active_report(47 downto 32);
        light_data_v := active_report(31 downto 16);
        moist_data_v := active_report(15 downto 0);
        
        write(csv_line, integer'image(to_integer(unsigned(source_v))) & "," &
                        integer'image(to_integer(unsigned(status_v))) & "," &
                        integer'image(to_integer(unsigned(opcode_v))) & "," &
                        integer'image(to_integer(unsigned(timestamp_v))) & "," &
                        integer'image(to_integer(unsigned(temp_data_v))) & "," &
                        integer'image(to_integer(unsigned(light_data_v))) & "," &
                        integer'image(to_integer(unsigned(moist_data_v))));
        
        writeline(output_file, csv_line);
    end procedure;

begin
    uut: control_center 
    Port map (
        CLK => CLK,
        RESET => RESET,
        instruction => instruction,
        active_report => active_report
    );

    CLK_process :process
    begin
        CLK <= '0';
        wait for CLK_period/2;
        CLK <= '1';
        wait for CLK_period/2;
    end process;

    stim_proc: process
    begin
        write_csv_header(output_file);
        
        RESET <= '1';
        wait for CLK_period;
        RESET <= '0';
        
        instruction <= "01000010";  -- Instruction untuk Station 1
        wait for CLK_period;
        
        -- Simulate a packet for Station 1
        -- packet_in <= 
        --     "01" &       -- Source
        --     "11" &       -- Status
        --     "001010" &   -- Opcode
        --     "010101" &   -- Timestamp
        --     "0000000011110000" &  -- Temp Data
        --     "1111000011110000" &  -- Light Data
        --     "0101010101010101";   -- Moisture Data
        
        wait for CLK_period * 1000;
        
        write_packet_to_csv(output_file, active_report);
        
        --instruction <= "10000010";  -- Instruction untuk Station 2
        --wait for CLK_period;
        
        -- packet_in <= 
        --     "10" &       -- Source
        --     "01" &       -- Status
        --     "010101" &   -- Opcode
        --     "101010" &   -- Timestamp
        --     "1111000000001111" &  -- Temp Data
        --     "0000111111110000" &  -- Light Data
        --     "1010101010101010";   -- Moisture Data
        
        wait for CLK_period * 1000;
        
        write_packet_to_csv(output_file, active_report);
        
        --instruction <= "11000011";  -- Instruction untuk Station 3
        --wait for CLK_period;
        
        -- packet_in <= 
        --     "11" &       -- Source
        --     "00" &       -- Status
        --     "111111" &   -- Opcode
        --     "001100" &   -- Timestamp
        --     "0101010101010101" &  -- Temp Data
        --     "1010101010101010" &  -- Light Data
        --     "0011001100110011";   -- Moisture Data
        
        wait for CLK_period * 1000;
        
        write_packet_to_csv(output_file, active_report);
        
        file_close(output_file);
        
        wait;
    end process;

end Behavioral;