library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity station_controller_2 is
    port (
        CLK             : in std_logic;  
        instruction     : in std_logic_vector(7 downto 0);
        packet_report   : out std_logic_vector(63 downto 0)
    );
end station_controller_2;

architecture Behavioral of station_controller_2 is
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
    signal delay_counter : integer range 0 to 3 := 0;
    signal data_ready : std_logic := '0';
    signal previous_packet_report : std_logic_vector(63 downto 0) := (others => '0');
    signal unchanged_cycles : integer range 0 to 3 := 0;

    -- function untuk mengecek validitas opcode, dimamana harus berada diantara
    -- operating opcode 000010 sampai dengan opcode 001000. Jika iya TRUE, jika tidak FALSE
    function is_valid_opcode(opcode : std_logic_vector(5 downto 0)) return boolean is
    begin
        return (opcode >= "000010") and (opcode <= "001000");
    end function;

    -- function untuk hitung kelembapan dengan rumus = (massa * 100)/ volume. Disini,
    -- akan me return integer signed yang dimasukkan ke data stream moist
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
        file input_file: text open read_mode is "sensor_2.csv";
        variable row: line;
        variable suhu: integer;
        variable daylight: integer;
        variable mass: integer;
        variable volume: integer;
        variable kelembapan: integer;
        variable semicolon: character;
        variable line_count: integer := 0;
        variable data_processed : boolean := false;
        variable opcode : std_logic_vector(5 downto 0);
    begin
        if rising_edge(CLK) then
            opcode := instruction(5 downto 0);

            if is_valid_opcode(opcode) then
                if not endfile(input_file) then
                    -- logika membaca file CSV atau semicolon seperated value. di line pertama
                    -- ada kolom header untuk di-skip. Jika tidak, maka membaca per baris 
                    -- dan mengoutput/proses data sesuai jenis
                    if line_count = 0 then
                        readline(input_file, row);  
                        line_count := line_count + 1;
                        data_processed := false;
                        delay_counter <= 0;
                        data_ready <= '1';
                    elsif data_processed = false then
                        readline(input_file, row);
                        read(row, suhu);
                        read(row, semicolon);
                        read(row, daylight);
                        read(row, semicolon);
                        read(row, mass);
                        read(row, semicolon);
                        read(row, volume);

                        kelembapan := calculate_kelembaban(mass, volume);

                        data_temp <= "0101" & std_logic_vector(to_signed(suhu, 12));
                        data_light <= "1001" & std_logic_vector(to_signed(daylight, 12));
                        data_moist <= "1101" & std_logic_vector(to_signed(kelembapan, 12));

                        line_count := line_count + 1;
                        data_processed := true;
                        delay_counter <= 0;
                        unchanged_cycles <= 0;
                        previous_packet_report <= ws_packet_report;
                    elsif ws_packet_report = previous_packet_report then
                        -- logika untuk reset counter kalau packet report baru agenya 3 CC
                        -- jadinya, antara controller dan station selalu sinkron. Dan juga
                        -- pembacaan dari CSV di adjust ke speed si station.
                        if unchanged_cycles < 3 then
                            unchanged_cycles <= unchanged_cycles + 1;
                        else
                            data_processed := false;
                            delay_counter <= 0;
                            data_ready <= '1';
                            unchanged_cycles <= 0;
                            previous_packet_report <= ws_packet_report;
                        end if;
                    else
                        line_count := 0;
                        data_processed := false;
                        delay_counter <= 0;
                        data_ready <= '1';
                        unchanged_cycles <= 0;
                        previous_packet_report <= ws_packet_report;
                    end if;
                end if;
            else
                data_ready <= '0'; 
            end if;
        end if;
    end process;
end Behavioral;