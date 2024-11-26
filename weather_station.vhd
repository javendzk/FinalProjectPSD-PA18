library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity weather_station is
    port(
        INPUT_DAYLIGHT : in std_logic;
        INPUT_KELEMBAPAN : in std_logic_vector(31 downto 0);
        INPUT_SUHU : in std_logic_vector(31 downto 0);
        OUTPUT_DAYLIGHT : out std_logic;
        OUTPUT_KELEMBAPAN : out std_logic_vector(31 downto 0);
        OUTPUT_SUHU : out std_logic_vector(31 downto 0)
    );
end weather_station;

architecture Behavioral of weather_station is
    signal daylight : std_logic;
    signal kelembapan : std_logic_vector(31 downto 0);
    signal suhu : std_logic_vector(31 downto 0);
begin
    daylight <= INPUT_DAYLIGHT;
    kelembapan <= INPUT_KELEMBAPAN;
    suhu <= INPUT_SUHU;

    OUTPUT_DAYLIGHT <= daylight;
    OUTPUT_KELEMBAPAN <= kelembapan;
    OUTPUT_SUHU <= suhu;
end Behavioral;