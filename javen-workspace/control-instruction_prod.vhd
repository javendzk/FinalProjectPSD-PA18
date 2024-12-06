library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Control_Center is
    Port (
        CLK           : in std_logic;
        instruction   : in std_logic_vector(7 downto 0);
        packet_report_1 : in std_logic_vector(63 downto 0);
        packet_report_2 : in std_logic_vector(63 downto 0);
        packet_report_3 : in std_logic_vector(63 downto 0);
        active_report : out std_logic_vector(63 downto 0)
    );
end Control_Center;

architecture Behavioral of Control_Center is
    -- Internal signals for instructions directed to each station
    signal instruct_Station_1 : std_logic_vector(7 downto 0) := (others => '0');
    signal instruct_Station_2 : std_logic_vector(7 downto 0) := (others => '0');
    signal instruct_Station_3 : std_logic_vector(7 downto 0) := (others => '0');

    -- Procedure to decode instruction and forward it
    procedure decode_instruction(signal instr : in std_logic_vector(7 downto 0)) is
    begin
        case instr(7 downto 6) is
            when "01" =>
                instruct_Station_1 <= instr;
                instruct_Station_2 <= (others => '0');
                instruct_Station_3 <= (others => '0');
            when "10" =>
                instruct_Station_1 <= (others => '0');
                instruct_Station_2 <= instr;
                instruct_Station_3 <= (others => '0');
            when "11" =>
                instruct_Station_1 <= (others => '0');
                instruct_Station_2 <= (others => '0');
                instruct_Station_3 <= instr;
            when others =>
                instruct_Station_1 <= (others => '0');
                instruct_Station_2 <= (others => '0');
                instruct_Station_3 <= (others => '0');
        end case;
    end procedure;
    
    -- Signal for selecting the active packet report
    signal active_packet : std_logic_vector(63 downto 0) := (others => '0');

begin
    -- Decode the instruction and forward it to the respective station
    process(CLK)
    begin
        if rising_edge(CLK) then
            decode_instruction(instruction);

            -- Select the active report based on the instruction's MSB
            case instruction(7 downto 6) is
                when "01" =>
                    active_packet <= packet_report_1;
                when "10" =>
                    active_packet <= packet_report_2;
                when "11" =>
                    active_packet <= packet_report_3;
                when others =>
                    active_packet <= (others => '0');
            end case;
        end if;
    end process;

    -- Output the active report
    active_report <= active_packet;

end Behavioral;
