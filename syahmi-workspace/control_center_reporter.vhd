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
    signal instruction : std_logic_vector(7 downto 0) := (others => '0');
    signal active_report : std_logic_vector(63 downto 0);

    constant CLK_period : time := 10 ns;

    file output_file : text open write_mode is "control_center_report.csv"; 

    function status_to_string(status : std_logic_vector(1 downto 0)) return string is
    begin
        case status is
            when "00" => return "No Status";
            when "01" => return "Running";
            when "10" => return "Idle";
            when others => return "Unknown";
        end case;
    end function;

    function sensor_status_to_string(status : std_logic_vector(1 downto 0)) return string is
        begin
            case status is
                when "00" => return "No Status";
                when "01" => return "Enabled";
                when "10" => return "Disabled";
                when others => return "Unknown";
            end case;
        end function;

    function type_to_string(sensor_type : std_logic_vector(1 downto 0)) return string is
    begin
        case sensor_type is
            when "01" => return "Temperature";
            when "10" => return "Light";
            when "11" => return "Moisture";
            when others => return "Unknown";
        end case;
    end function;

    function daylight_to_string(sensor_type : std_logic_vector(10 downto 0)) return string is
        begin
            case sensor_type is
                when "00000000000" => return "Night";
                when "00000000001" => return "Day";
                when others => return "Unknown";
            end case;
        end function;

    procedure write_csv_header(file output_file : text) is
        variable csv_line : line;
    begin
        write(csv_line, string'("Source;Status;Opcode;Timestamp;SensorType1;SensorStatus1;SensorFlag1;Temp Data;SensorType2;SensorStatus2;SensorFlag2;Light Data;SensorType3;SensorStatus3;SensorFlag3;Moisture Data"));
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
        variable sensor_type_1 : std_logic_vector(1 downto 0);
        variable sensor_status_1 : std_logic_vector(1 downto 0);
        variable sensor_flag_1 : std_logic_vector(0 downto 0);
        variable temp_data_v : std_logic_vector(10 downto 0);
        variable sensor_type_2 : std_logic_vector(1 downto 0);
        variable sensor_status_2 : std_logic_vector(1 downto 0);
        variable sensor_flag_2 : std_logic_vector(0 downto 0);
        variable light_data_v : std_logic_vector(10 downto 0);
        variable sensor_type_3 : std_logic_vector(1 downto 0);
        variable sensor_status_3 : std_logic_vector(1 downto 0);
        variable sensor_flag_3 : std_logic_vector(0 downto 0);
        variable moist_data_v : std_logic_vector(10 downto 0);
    begin
        source_v := active_report(63 downto 62);
        status_v := active_report(61 downto 60);
        opcode_v := active_report(59 downto 54);
        timestamp_v := active_report(53 downto 48);
        sensor_type_1 := active_report(47 downto 46);
        sensor_status_1 := active_report(45 downto 44);
        sensor_flag_1 := active_report(43 downto 43);
        temp_data_v := active_report(42 downto 32);
        sensor_type_2 := active_report(31 downto 30);
        sensor_status_2 := active_report(29 downto 28);
        sensor_flag_2 := active_report(27 downto 27);
        light_data_v := active_report(26 downto 16);
        sensor_type_3 := active_report(15 downto 14);
        sensor_status_3 := active_report(13 downto 12);
        sensor_flag_3 := active_report(11 downto 11);   
        moist_data_v := active_report(10 downto 0);

        write(csv_line, integer'image(to_integer(unsigned(source_v))) & ";" &
                        status_to_string(status_v) & ";" &
                        integer'image(to_integer(unsigned(opcode_v))) & ";" &
                        integer'image(to_integer(unsigned(timestamp_v))) & ";" &
                        type_to_string(sensor_type_1) & ";" &
                        sensor_status_to_string(sensor_status_1) & ";" &
                        integer'image(to_integer(unsigned(sensor_flag_1))) & ";" &
                        integer'image(to_integer(unsigned(temp_data_v))) & ";" &
                        type_to_string(sensor_type_2) & ";" &
                        sensor_status_to_string(sensor_status_2) & ";" &
                        integer'image(to_integer(unsigned(sensor_flag_2))) & ";" &
                        daylight_to_string(light_data_v) & ";" &
                        type_to_string(sensor_type_3) & ";" &
                        sensor_status_to_string(sensor_status_3) & ";" &
                        integer'image(to_integer(unsigned(sensor_flag_3))) & ";" &
                        integer'image(to_integer(unsigned(moist_data_v))));
        writeline(output_file, csv_line);
    end procedure;

    signal station1_status : std_logic_vector(1 downto 0);
    signal station1_opcode : std_logic_vector(5 downto 0);
    signal station1_timestamp : std_logic_vector(5 downto 0);
    signal station1_sensortype_1 : std_logic_vector(1 downto 0);
    signal station1_sensorstatus_1 : std_logic_vector(1 downto 0);
    signal station1_sensorflag_1 : std_logic_vector(0 downto 0);
    signal station1_temp_data : std_logic_vector(10 downto 0);
    signal station1_sensortype_2 : std_logic_vector(1 downto 0);
    signal station1_sensorstatus_2: std_logic_vector(1 downto 0);
    signal station1_sensorflag_2 : std_logic_vector(0 downto 0);
    signal station1_light_data : std_logic_vector(10 downto 0);
    signal station1_sensortype_3 : std_logic_vector(1 downto 0);
    signal station1_sensorstatus_3 : std_logic_vector(1 downto 0);
    signal station1_sensorflag_3 : std_logic_vector(0 downto 0);
    signal station1_moist_data : std_logic_vector(10 downto 0);

    signal station2_status : std_logic_vector(1 downto 0);
    signal station2_opcode : std_logic_vector(5 downto 0);
    signal station2_timestamp : std_logic_vector(5 downto 0);
    signal station2_sensortype_1 : std_logic_vector(1 downto 0);
    signal station2_sensorstatus_1 : std_logic_vector(1 downto 0);
    signal station2_sensorflag_1 : std_logic_vector(0 downto 0);
    signal station2_temp_data : std_logic_vector(10 downto 0);
    signal station2_sensortype_2 : std_logic_vector(1 downto 0);
    signal station2_sensorstatus_2: std_logic_vector(1 downto 0);
    signal station2_sensorflag_2 : std_logic_vector(0 downto 0);
    signal station2_light_data : std_logic_vector(10 downto 0);
    signal station2_sensortype_3 : std_logic_vector(1 downto 0);
    signal station2_sensorstatus_3 : std_logic_vector(1 downto 0);
    signal station2_sensorflag_3 : std_logic_vector(0 downto 0);
    signal station2_moist_data : std_logic_vector(10 downto 0);

    signal station3_status : std_logic_vector(1 downto 0);
    signal station3_opcode : std_logic_vector(5 downto 0);
    signal station3_timestamp : std_logic_vector(5 downto 0);
    signal station3_sensortype_1 : std_logic_vector(1 downto 0);
    signal station3_sensorstatus_1 : std_logic_vector(1 downto 0);
    signal station3_sensorflag_1 : std_logic_vector(0 downto 0);
    signal station3_temp_data : std_logic_vector(10 downto 0);
    signal station3_sensortype_2 : std_logic_vector(1 downto 0);
    signal station3_sensorstatus_2: std_logic_vector(1 downto 0);
    signal station3_sensorflag_2 : std_logic_vector(0 downto 0);
    signal station3_light_data : std_logic_vector(10 downto 0);
    signal station3_sensortype_3 : std_logic_vector(1 downto 0);
    signal station3_sensorstatus_3 : std_logic_vector(1 downto 0);
    signal station3_sensorflag_3 : std_logic_vector(0 downto 0);
    signal station3_moist_data : std_logic_vector(10 downto 0);

    signal current_station : integer range 1 to 3 := 1;

begin
    control_center_inst: control_center 
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
        wait for 100 ns;
    end process;

      report_writer: process(CLK, RESET)
        variable last_report : std_logic_vector(63 downto 0) := (others => '0');
    begin
        if RESET = '1' then
            last_report := (others => '0');
            current_station <= 1;
            
            -- Reset all station signals
            station1_status <= (others => '0');
            station1_opcode <= (others => '0');
            station1_timestamp <= (others => '0');
            station1_sensortype_1 <= (others => '0');
            station1_sensorstatus_1 <= (others => '0');
            station1_sensorflag_1 <= (others => '0');
            station1_temp_data <= (others => '0');
            station1_sensortype_2 <= (others => '0');
            station1_sensorstatus_2 <= (others => '0');
            station1_sensorflag_2 <= (others => '0');
            station1_light_data <= (others => '0');
            station1_sensortype_3 <= (others => '0');
            station1_sensorstatus_3 <= (others => '0');
            station1_sensorflag_3 <= (others => '0');
            station1_moist_data <= (others => '0');

            station2_status <= (others => '0');
            station2_opcode <= (others => '0');
            station2_timestamp <= (others => '0');
            station2_sensortype_1 <= (others => '0');
            station2_sensorstatus_1 <= (others => '0');
            station2_sensorflag_1 <= (others => '0');
            station2_temp_data <= (others => '0');
            station2_sensortype_2 <= (others => '0');
            station2_sensorstatus_2 <= (others => '0');
            station2_sensorflag_2 <= (others => '0');
            station2_light_data <= (others => '0');
            station2_sensortype_3 <= (others => '0');
            station2_sensorstatus_3 <= (others => '0');
            station2_sensorflag_3 <= (others => '0');
            station2_moist_data <= (others => '0');

            station3_status <= (others => '0');
            station3_opcode <= (others => '0');
            station3_timestamp <= (others => '0');
            station3_sensortype_1 <= (others => '0');
            station3_sensorstatus_1 <= (others => '0');
            station3_sensorflag_1 <= (others => '0');
            station3_temp_data <= (others => '0');
            station3_sensortype_2 <= (others => '0');
            station3_sensorstatus_2 <= (others => '0');
            station3_sensorflag_2 <= (others => '0');
            station3_light_data <= (others => '0');
            station3_sensortype_3 <= (others => '0');
            station3_sensorstatus_3 <= (others => '0');
            station3_sensorflag_3 <= (others => '0');
            station3_moist_data <= (others => '0');

        elsif rising_edge(CLK) then
            if active_report /= last_report then 
                if active_report(63 downto 62) /= "00" then
                    write_packet_to_csv(output_file, active_report);  
                    last_report := active_report;  

                    case current_station is
                        when 1 =>
                            station1_status <= active_report(61 downto 60);
                            station1_opcode <= active_report(59 downto 54);
                            station1_timestamp <= active_report(53 downto 48);
                            station1_sensortype_1 <= active_report(47 downto 46);
                            station1_sensorstatus_1 <= active_report(45 downto 44);
                            station1_sensorflag_1 <= active_report(43 downto 43);
                            station1_temp_data <= active_report(42 downto 32);
                            station1_sensortype_2 <= active_report(31 downto 30);
                            station1_sensorstatus_2 <= active_report(29 downto 28);
                            station1_sensorflag_2 <= active_report(27 downto 27);
                            station1_light_data <= active_report(26 downto 16);
                            station1_sensortype_3 <= active_report(15 downto 14);
                            station1_sensorstatus_3 <= active_report(13 downto 12);
                            station1_sensorflag_3 <= active_report(11 downto 11);
                            station1_moist_data <= active_report(10 downto 0);
                        
                        when 2 =>
                            station2_status <= active_report(61 downto 60);
                            station2_opcode <= active_report(59 downto 54);
                            station2_timestamp <= active_report(53 downto 48);
                            station2_sensortype_1 <= active_report(47 downto 46);
                            station2_sensorstatus_1 <= active_report(45 downto 44);
                            station2_sensorflag_1 <= active_report(43 downto 43);
                            station2_temp_data <= active_report(42 downto 32);
                            station2_sensortype_2 <= active_report(31 downto 30);
                            station2_sensorstatus_2 <= active_report(29 downto 28);
                            station2_sensorflag_2 <= active_report(27 downto 27);
                            station2_light_data <= active_report(26 downto 16);
                            station2_sensortype_3 <= active_report(15 downto 14);
                            station2_sensorstatus_3 <= active_report(13 downto 12);
                            station2_sensorflag_3 <= active_report(11 downto 11);
                            station2_moist_data <= active_report(10 downto 0);
                        
                        when 3 =>
                            station3_status <= active_report(61 downto 60);
                            station3_opcode <= active_report(59 downto 54);
                            station3_timestamp <= active_report(53 downto 48);
                            station3_sensortype_1 <= active_report(47 downto 46);
                            station3_sensorstatus_1 <= active_report(45 downto 44);
                            station3_sensorflag_1 <= active_report(43 downto 43);
                            station3_temp_data <= active_report(42 downto 32);
                            station3_sensortype_2 <= active_report(31 downto 30);
                            station3_sensorstatus_2 <= active_report(29 downto 28);
                            station3_sensorflag_2 <= active_report(27 downto 27);
                            station3_light_data <= active_report(26 downto 16);
                            station3_sensortype_3 <= active_report(15 downto 14);
                            station3_sensorstatus_3 <= active_report(13 downto 12);
                            station3_sensorflag_3 <= active_report(11 downto 11);
                            station3_moist_data <= active_report(10 downto 0);
                    end case;

                    if current_station < 3 then
                        current_station <= current_station + 1;
                    else
                        current_station <= 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;