library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity weather_station_controller1 is
    port (
        CLK             : in std_logic;  
        instruction     : in std_logic_vector(7 downto 0);
        packet_report   : out std_logic_vector(63 downto 0)
    );
end weather_station_controller1;

architecture Behavioral of weather_station_controller1 is
    component Weather_Station is
        Port (
            CLK           : in std_logic;
            data_temp     : in std_logic_vector(15 downto 0);
            data_light    : in std_logic_vector(15 downto 0);
            data_moist    : in std_logic_vector(15 downto 0);
            instruction   : in std_logic_vector(7 downto 0);
            packet_report : out std_logic_vector(63 downto 0)
        );
    end component;

    signal data_light  : std_logic_vector(15 downto 0) := (others => '0');
    signal data_moist  : std_logic_vector(15 downto 0) := (others => '0');
    signal data_temp   : std_logic_vector(15 downto 0) := (others => '0');
    signal ws_packet_report : std_logic_vector(63 downto 0);

    function calculate_kelembaban(mass: integer; volume: integer) return integer is
        variable kelembapan: integer;
    begin
        if volume /= 0 then
            kelembapan := (mass * 100) / volume;
            return kelembapan;
        else
            return 0;
        end if;
    end function;

begin
    Weather_Station_Inst: Weather_Station 
    port map (
        CLK => CLK,
        data_temp => data_temp,
        data_light => data_light,
        data_moist => data_moist,
        instruction => instruction,
        packet_report => ws_packet_report
    );

    packet_report <= ws_packet_report;

    file_read_process: process(CLK)
        file input_file: text open read_mode is "sensor1.csv";
        variable row: line;
        variable suhu: integer;
        variable daylight: integer;
        variable mass: integer;
        variable volume: integer;
        variable kelembapan: integer;
        variable comma: character;
        variable isFirstLine: boolean := true;
        variable line_count: integer := 0;
    begin
        if rising_edge(CLK) then
            if not endfile(input_file) then
                if line_count = 0 then
                    readline(input_file, row);  
                    line_count := line_count + 1;
                else
                    readline(input_file, row);
                    
                    read(row, suhu);
                    read(row, comma);
                    read(row, daylight);
                    read(row, comma);
                    read(row, mass);
                    read(row, comma);
                    read(row, volume);

                    kelembapan := calculate_kelembaban(mass, volume);

                    data_temp <= std_logic_vector(to_unsigned(daylight, 16));
                    data_light <= std_logic_vector(to_unsigned(suhu, 16));
                    data_moist <= std_logic_vector(to_unsigned(kelembapan, 16));

                    line_count := line_count + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;