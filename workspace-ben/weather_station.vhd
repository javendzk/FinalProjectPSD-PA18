library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Weather_Station is
    Port (
        CLK           : in std_logic;
        data_temp     : in std_logic_vector(15 downto 0);
        data_light    : in std_logic_vector(15 downto 0);
        data_moist    : in std_logic_vector(15 downto 0);
        instruction   : in std_logic_vector(7 downto 0);
        packet_report : out std_logic_vector(63 downto 0)
    );
end Weather_Station;

architecture Behavioral of weather_station is
    signal daylight : std_logic;
    signal kelembapan : std_logic_vector(31 downto 0);
    signal suhu : std_logic_vector(31 downto 0);
begin
    daylight <= data_light(15);
    kelembapan <= data_moist;
    suhu <= data_temp;
end Behavioral;