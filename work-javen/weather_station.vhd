library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of Weather_Station is
    -- FSM States
    type state_type is (Idle, Read_Inst, Encode, Report);
    signal current_state, next_state : state_type;

    -- Internal signals
    signal sensor_temp, sensor_light, sensor_moist : std_logic_vector(15 downto 0);
    signal current_instruction, prev_instruction   : std_logic_vector(7 downto 0);
    signal opcode, timestamp                       : std_logic_vector(5 downto 0);
    signal report_packet                           : std_logic_vector(63 downto 0);
    signal source                                  : std_logic_vector(1 downto 0) := "01"; -- Station 1
    signal status                                  : std_logic_vector(1 downto 0);
    signal temp_active, light_active, moist_active : std_logic := '1';

    -- Functions and Procedures
    function encode_sensor_data(sensor_type : std_logic_vector(1 downto 0);
                                sensor_status : std_logic_vector(1 downto 0);
                                data : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable encoded_data : std_logic_vector(15 downto 0);
    begin
        encoded_data(15 downto 14) := sensor_type;      -- Sensor type
        encoded_data(13 downto 12) := sensor_status;    -- Status
        if sensor_status = "10" then -- Jika stopped, isi C D dengan 0
            encoded_data(11 downto 0) := (others => '0');
        else
            encoded_data(11) := data(15);              -- Sign bit
            encoded_data(10 downto 0) := data(10 downto 0); -- Data
        end if;
        return encoded_data;
    end function;

    procedure create_report(opcode_in : std_logic_vector(5 downto 0);
                            cycle : std_logic_vector(5 downto 0);
                            temp : std_logic_vector(15 downto 0);
                            light : std_logic_vector(15 downto 0);
                            moist : std_logic_vector(15 downto 0);
                            report : out std_logic_vector(63 downto 0)) is
    begin
        report(63 downto 62) := source;
        report(61 downto 60) := status;
        report(59 downto 54) := opcode_in;
        report(53 downto 48) := cycle;
        report(47 downto 32) := temp;
        report(31 downto 16) := light;
        report(15 downto 0) := moist;
    end procedure;

begin
    -- FSM Sequential Process
    process(CLK)
    begin
        if rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    -- FSM Combinational Logic
    process(current_state, instruction, data_temp, data_light, data_moist)
    begin
        -- Default behavior
        next_state <= current_state;

        case current_state is
            when Idle =>
                status <= "10"; -- Idle
                opcode <= "000001"; -- Go idle opcode
                if instruction /= "00000000" then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                end if;

            when Read_Inst =>
                current_instruction <= instruction;
                opcode <= instruction(5 downto 0); -- Assign opcode
                -- Update sensor activity based on opcode
                case instruction(5 downto 0) is
                    when "000010" => temp_active <= '1'; light_active <= '1'; moist_active <= '1'; next_state <= Encode; -- Run all sensors
                    when "000011" => temp_active <= '0'; light_active <= '1'; moist_active <= '1'; next_state <= Encode; -- Stop temp
                    when "000100" => temp_active <= '1'; light_active <= '0'; moist_active <= '1'; next_state <= Encode; -- Stop daylight
                    when "000101" => temp_active <= '1'; light_active <= '1'; moist_active <= '0'; next_state <= Encode; -- Stop moist
                    when "000110" => temp_active <= '1'; light_active <= '0'; moist_active <= '0'; next_state <= Encode; -- Run temp only
                    when "000111" => temp_active <= '0'; light_active <= '1'; moist_active <= '0'; next_state <= Encode; -- Run daylight only
                    when "001000" => temp_active <= '0'; light_active <= '0'; moist_active <= '1'; next_state <= Encode; -- Run moist only
                    when others =>
                        next_state <= Idle;
                end case;

            when Encode =>
                -- Abort and read new instruction if instruction changes
                if instruction /= prev_instruction then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                else
                    -- Encode data based on active sensors
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

                    next_state <= Report;
                end if;

            when Report =>
                -- Abort and read new instruction if instruction changes
                if instruction /= prev_instruction then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                else
                    create_report(opcode, timestamp, sensor_temp, sensor_light, sensor_moist, report_packet);
                    packet_report <= report_packet;
                    next_state <= Encode; -- Loop back to Encode
                end if;

        end case;
    end process;

end Behavioral;
