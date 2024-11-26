library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Control_Center is
    Port (
        instruction   : in std_logic_vector(7 downto 0)
    );
end Control_Center;

architecture Behavioral of Control_Center is
    -- contoh misalnya ada 3 internal signal untuk meneruskan instruct station
    -- masing" akan di port map ke IN dari weather station yang kesambung dengannya. 
    signal instruct_Station_1 : std_logic_vector(7 downto 0);
    signal instruct_Station_2 : std_logic_vector(7 downto 0);
    signal instruct_Station_3 : std_logic_vector(7 downto 0);

    -- implementasi procedure buat forward instruction ke weather
    -- station yang mana. dia ngebaca di 2 bit MSB @syahmihamdani
    procedure decode_instruction(signal instr : in std_logic_vector(7 downto 0)) is
    begin
        case instr(7 downto 6) is
            when "01" =>
                instruct_Station_1 <= instr;
            when "10" =>
                instruct_Station_2 <= instr;
            when "11" =>
                instruct_Station_3 <= instr;
            when others =>
                instruct_Station_1 <= (others => '0');
                instruct_Station_2 <= (others => '0');
                instruct_Station_3 <= (others => '0');
        end case;
    end procedure;
begin

    -- ini juga misalnya buat pengandaian aja, ketika weather station di instantiate
    -- kita map port instruction masing" ke signal yang udah dedcated
    weather_station1_inst: entity work.weather_station1
        port map (
            instruction => instruct_Station_1
        );

    weather_station2_inst: entity work.weather_station2
        port map (
            instruction => instruct_Station_2
        );

    weather_station3_inst: entity work.weather_station3
        port map (
            instruction => instruct_Station_3
        );
end Behavioral;


