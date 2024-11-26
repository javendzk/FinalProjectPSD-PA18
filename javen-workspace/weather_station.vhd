-- ver 26/11/24 
-- belum bener" banget, untested, uncompiled.

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
    type state_type is (Idle, Read_Inst, Encode, Generate_Report);
    signal current_state, next_state : state_type;

    signal sensor_temp, sensor_light, sensor_moist : std_logic_vector(15 downto 0);
    signal current_instruction, prev_instruction   : std_logic_vector(7 downto 0);
    signal opcode, timestamp                       : std_logic_vector(5 downto 0);
    signal source                                  : std_logic_vector(1 downto 0) := "01";
    signal status                                  : std_logic_vector(1 downto 0);
    signal temp_active, light_active, moist_active : std_logic := '1';

    function encode_sensor_data(sensor_type : std_logic_vector(1 downto 0);
                                sensor_status : std_logic_vector(1 downto 0);
                                data : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable encoded_data : std_logic_vector(15 downto 0);
    begin
        encoded_data(15 downto 14) := sensor_type;
        encoded_data(13 downto 12) := sensor_status;
        if sensor_status = "10" then
            encoded_data(11 downto 0) := (others => '0');
        else
            encoded_data(11) := data(15);
            encoded_data(10 downto 0) := data(10 downto 0);
        end if;
        return encoded_data;
    end function;

    procedure create_report(opcode_in : std_logic_vector(5 downto 0);
                            cycle : std_logic_vector(5 downto 0);
                            temp : std_logic_vector(15 downto 0);
                            light : std_logic_vector(15 downto 0);
                            moist : std_logic_vector(15 downto 0);
                            report_out : out std_logic_vector(63 downto 0)) is
    begin
        report_out(63 downto 62) := source;
        report_out(61 downto 60) := status;
        report_out(59 downto 54) := opcode_in;
        report_out(53 downto 48) := cycle;
        report_out(47 downto 32) := temp;
        report_out(31 downto 16) := light;
        report_out(15 downto 0) := moist;
    end procedure;

begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, instruction, data_temp, data_light, data_moist)
        variable report_var : std_logic_vector(63 downto 0);
    begin
        next_state <= current_state;

        case current_state is
            when Idle =>
                status <= "10";
                opcode <= "000001";
                if instruction /= "00000000" then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                end if;

            when Read_Inst =>
                current_instruction <= instruction;
                opcode <= instruction(5 downto 0);
                case instruction(5 downto 0) is
                    when "000010" => temp_active <= '1'; light_active <= '1'; moist_active <= '1'; next_state <= Encode;
                    when "000011" => temp_active <= '0'; light_active <= '1'; moist_active <= '1'; next_state <= Encode;
                    when "000100" => temp_active <= '1'; light_active <= '0'; moist_active <= '1'; next_state <= Encode;
                    when "000101" => temp_active <= '1'; light_active <= '1'; moist_active <= '0'; next_state <= Encode;
                    when "000110" => temp_active <= '1'; light_active <= '0'; moist_active <= '0'; next_state <= Encode;
                    when "000111" => temp_active <= '0'; light_active <= '1'; moist_active <= '0'; next_state <= Encode;
                    when "001000" => temp_active <= '0'; light_active <= '0'; moist_active <= '1'; next_state <= Encode;
                    when others =>
                        next_state <= Idle;
                end case;

            when Encode =>
                if instruction /= prev_instruction then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                else
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

                    next_state <= Generate_Report;
                end if;

            when Generate_Report =>
                if instruction /= prev_instruction then
                    prev_instruction <= instruction;
                    next_state <= Read_Inst;
                else
                    create_report(opcode, timestamp, sensor_temp, sensor_light, sensor_moist, report_var);
                    packet_report <= report_var;
                    next_state <= Encode;
                end if;

        end case;
    end process;

end Behavioral;

