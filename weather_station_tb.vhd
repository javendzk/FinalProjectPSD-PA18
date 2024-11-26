library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity weather_station_tb is
end weather_station_tb;

architecture Behavioral of weather_station_tb is
    component weather_station is
        port(
            INPUT_DAYLIGHT : in std_logic;
            INPUT_KELEMBAPAN : in std_logic_vector(31 downto 0);
            INPUT_SUHU : in std_logic_vector(31 downto 0);
            OUTPUT_DAYLIGHT : out std_logic;
            OUTPUT_KELEMBAPAN : out std_logic_vector(31 downto 0);
            OUTPUT_SUHU : out std_logic_vector(31 downto 0)
        );
    end component;

    signal INPUT_DAYLIGHT : std_logic := '0';
    signal INPUT_KELEMBAPAN : std_logic_vector(31 downto 0) := (others => '0');
    signal INPUT_SUHU : std_logic_vector(31 downto 0) := (others => '0');
    signal OUTPUT_DAYLIGHT : std_logic;
    signal OUTPUT_KELEMBAPAN : std_logic_vector(31 downto 0);
    signal OUTPUT_SUHU : std_logic_vector(31 downto 0);

    function calculate_kelembaban(mass: integer; volume: integer) return integer is
        variable kelembapan: integer;
    begin
        kelembapan := mass / volume;
        return kelembapan;
    end function;

begin
    DUT: weather_station
        port map(
            INPUT_DAYLIGHT => INPUT_DAYLIGHT,
            INPUT_KELEMBAPAN => INPUT_KELEMBAPAN,
            INPUT_SUHU => INPUT_SUHU,
            OUTPUT_DAYLIGHT => OUTPUT_DAYLIGHT,
            OUTPUT_KELEMBAPAN => OUTPUT_KELEMBAPAN,
            OUTPUT_SUHU => OUTPUT_SUHU
        );
    
    tb: process
        file input_file: text open read_mode is "sensor.csv";
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

                INPUT_DAYLIGHT <= daylight;
                INPUT_SUHU <= std_logic_vector(to_signed(suhu, 32));
                INPUT_KELEMBAPAN <= std_logic_vector(to_unsigned(kelembapan, 32));

                wait for 10 ns;
            end if;
        end loop;
        
        wait;
    end process;
end Behavioral;