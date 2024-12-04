library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity weather_station is
    Port (
        CLK           : in std_logic;
        data_temp     : in std_logic_vector(15 downto 0);
        data_light    : in std_logic_vector(15 downto 0);
        data_moist    : in std_logic_vector(15 downto 0);
        instruction   : in std_logic_vector(7 downto 0);
        packet_report : out std_logic_vector(63 downto 0)
    );
end weather_station;

architecture Behavioral of Weather_Station is
    type state_type is (Idle_State, Read_Inst, Encode, Generate_Report);
    signal current_state, next_state : state_type;
    signal sensor_temp, sensor_light, sensor_moist : std_logic_vector(15 downto 0);
    signal current_instruction, prev_instruction   : std_logic_vector(7 downto 0);
    signal opcode                                  : std_logic_vector(5 downto 0);
    signal timestamp                               : std_logic_vector(5 downto 0);
    signal clock_cycle_counter                     : unsigned(5 downto 0) := (others => '0');
    signal source                                  : std_logic_vector(1 downto 0) := "00"; -- angka source diambil dari instruction
    signal status                                  : std_logic_vector(1 downto 0) := "10"; -- default status 01 (idle)
    signal temp_active, light_active, moist_active : std_logic := '0';

    -- Encoding untuk sensor data, karena perlu dicustom pada packet report
    function encode_sensor_data(
        sensor_type : std_logic_vector(1 downto 0);
        sensor_status : std_logic_vector(1 downto 0);
        data : std_logic_vector(15 downto 0)
    ) return std_logic_vector is
        variable encoded_data : std_logic_vector(15 downto 0);
    begin
        encoded_data(15 downto 14) := sensor_type;
        encoded_data(13 downto 12) := sensor_status;
        if sensor_status = "10" then
            encoded_data(11 downto 0) := (others => '0');
        else
            encoded_data(11 downto 0) := data(11 downto 0);
\        end if;
        return encoded_data;
    end function;

begin
    state_transition: process(CLK)
    begin
        if rising_edge(CLK) then
            current_state <= next_state;
            
            if current_state = Generate_Report then -- Counter sudah berapa kali report
                clock_cycle_counter <= clock_cycle_counter + 1;
            end if;
        end if;
    end process state_transition;

    state_machine: process(CLK)
        variable report_packet : std_logic_vector(63 downto 0);
    begin
        if rising_edge(CLK) then
            next_state <= current_state;
            
            case current_state is
                when Idle_State =>
                    -- State idle awal: status = 10 (idle), opcode 0....01 (idle). di report sama, data sensor = flat 0
                    status <= "10";  
                    opcode <= "000001";  
                    report_packet(63 downto 62) := "01";  
                    report_packet(61 downto 60) := "10";  -
                    report_packet(59 downto 54) := "000001"; 
                    report_packet(53 downto 48) := (others => '0');  
                    report_packet(47 downto 0) := (others => '0');
                    packet_report <= report_packet;

                    if instruction /= "00000000" then
                        prev_instruction <= instruction;
                        next_state <= Read_Inst;
                    end if;

                when Read_Inst =>
                    current_instruction <= instruction;
                    source <= instruction(7 downto 6);  
                    opcode <= instruction(5 downto 0);
                    
                    case instruction(5 downto 0) is
                        when "000001" => -- opcode: idle
                            status <= "10";
                            temp_active <= '0';
                            light_active <= '0';
                            moist_active <= '0';
                            next_state <= Idle_State;
                        
                        when "000010" => 
                            temp_active <= '1'; -- opcode: run (semua sensor)
                            light_active <= '1'; 
                            moist_active <= '1'; 
                            status <= "01";  
                            next_state <= Encode;
                        
                        when "000011" => 
                            temp_active <= '0'; 
                            light_active <= '1'; 
                            moist_active <= '1'; 
                            status <= "01";
                            next_state <= Encode;
                        
                        when "000100" =>
                            temp_active <= '1'; -- opcode: run (semua kecuali light)
                            light_active <= '0';
                            moist_active <= '1';
                            status <= "01";
                            next_state <= Encode;
                        
                        when "000101" =>
                            temp_active <= '1'; -- opcode: run (semua kecuali moist)
                            light_active <= '1';
                            moist_active <= '0';
                            status <= "01";
                            next_state <= Encode;
                        
                        when "000110" =>
                            temp_active <= '1'; -- opcode: run (hanya temp)
                            light_active <= '0';
                            moist_active <= '0';
                            status <= "01";
                            next_state <= Encode;
                        
                        when "000111" =>
                            temp_active <= '0'; -- opcode: run (hanya light)
                            light_active <= '1';
                            moist_active <= '0';
                            status <= "01";
                            next_state <= Encode;
                        
                        when "001000" =>
                            temp_active <= '0'; -- opcode: run (hanya moist)
                            light_active <= '0';
                            moist_active <= '1';
                            status <= "01";
                            next_state <= Encode;
                        
                        when others =>
                            next_state <= Idle_State; -- masuk ke idle kalau opcode unknown
                    end case;

                when Encode =>
                    if temp_active = '1' then
                        sensor_temp <= encode_sensor_data("01", "01", data_temp);
                    else
                        sensor_temp <= encode_sensor_data("01", "10", (others => '0'));
                    end if;

                    if light_active = '1' then
                        sensor_light <= encode_sensor_data("10", "01", data_light);
                    else
                        sensor_light <= encode_sensor_data("10", "10", (others => '0'));
                    end if;

                    if moist_active = '1' then
                        sensor_moist <= encode_sensor_data("11", "01", data_moist);
                    else
                        sensor_moist <= encode_sensor_data("11", "10", (others => '0'));
                    end if;

                    timestamp <= std_logic_vector(clock_cycle_counter);
                    next_state <= Generate_Report;

                when Generate_Report =>
                    -- meracik report packet 64 bit, semua value sudah dirapihkan tinggal dikirim.
                    report_packet(63 downto 62) := source;
                    report_packet(61 downto 60) := status;
                    report_packet(59 downto 54) := opcode;
                    report_packet(53 downto 48) := timestamp;
                    report_packet(47 downto 32) := sensor_temp;
                    report_packet(31 downto 16) := sensor_light;
                    report_packet(15 downto 0) := sensor_moist;
                    
                    packet_report <= report_packet;
                    
                    -- trigger jika instruction baru (berbeda dari previous) buat masuk state read_onst
                    -- di awal yang /= 00000000 dipakai buat ngecek jika full flat, bukan perbandingan inst baru
                    if instruction /= prev_instruction then
                        prev_instruction <= instruction;
                        next_state <= Read_Inst;
                    else
                        next_state <= Encode;
                    end if;
            end case;
        end if;
    end process state_machine;
end Behavioral;