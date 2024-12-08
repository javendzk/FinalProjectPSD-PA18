library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity weather_station_tb2 is
end weather_station_tb2;

architecture Behavioral of weather_station_tb2 is
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

    signal CLK : std_logic;
    signal data_light : std_logic_vector(15 downto 0);
    signal data_moist : std_logic_vector(15 downto 0);
    signal data_temp : std_logic_vector(15 downto 0);
    signal instruction : std_logic_vector(7 downto 0);
    signal packet_report : std_logic_vector(63 downto 0);

    function calculate_kelembaban(mass: integer; volume: integer) return integer is
        variable kelembapan: integer;
    begin
        kelembapan := mass / volume;
        return kelembapan;
    end function;

begin
    DUT: Weather_Station port map (
        CLK => CLK,
        data_temp => data_temp,
        data_light => data_light,
        data_moist => data_moist,
        instruction => instruction,
        packet_report => packet_report
    );
    
    tb: process
        file input_file: text open read_mode is "sensor2.csv";
        variable row: line;
        variable suhu: integer;
        variable daylight: std_logic;
        variable mass: integer;
        variable volume: integer;
        variable kelembapan: integer;
        variable comma: character;
        variable isFirstLine: boolean := true;
    begin
        while not endfile(input_file) loop
            readline(input_file, row);

            if isFirstLine then
                isFirstLine := false;
                next;
            else
                read(row, suhu);
                read(row, comma);

                read(row, daylight);
                read(row, comma);

                read(row, mass);
                read(row, comma);

                read(row, volume);

                kelembapan := calculate_kelembaban(mass, volume);

                data_light <= std_logic_vector(to_unsigned(suhu, 16));
                data_moist <= std_logic_vector(to_unsigned(kelembapan, 16));
                data_temp <= std_logic_vector(to_unsigned(daylight, 16));

                wait for 10 ns;
            end if;
        end loop;
        
        wait;
    end process;
end Behavioral;