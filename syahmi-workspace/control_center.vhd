library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity control_center is
    Port (
        CLK              : in std_logic;
        RESET            : in std_logic;
        instruction      : in std_logic_vector(7 downto 0);
        active_report    : out std_logic_vector(63 downto 0)
    );
end control_center;

architecture Behavioral of control_center is
    signal source    : std_logic_vector(1 downto 0);
    signal status    : std_logic_vector(1 downto 0);
    signal opcode    : std_logic_vector(5 downto 0);
    signal timestamp : std_logic_vector(5 downto 0);
    signal temp_data, light_data, moist_data : std_logic_vector(15 downto 0);
    signal active_packet : std_logic_vector(63 downto 0);  -- Use this internal signal for packet assignment
    signal packet_report_1, packet_report_2, packet_report_3 : std_logic_vector(63 downto 0); -- Internal signals for packets

    type state_type is (Idle, Send_Inst, Read_Pack, Decode, Report_Pack);
    signal current_state, next_state : state_type;

    procedure decode_instruction(signal instr : in std_logic_vector(7 downto 0);
                                 signal instruct_1, instruct_2, instruct_3 : out std_logic_vector(7 downto 0)) is
        variable temp_instr : std_logic_vector(7 downto 0);
    begin
        temp_instr := instr; 
        
        case temp_instr(7 downto 6) is
            when "01" =>  
                instruct_1 <= temp_instr;
                instruct_2 <= (others => '0');
                instruct_3 <= (others => '0');
            when "10" => 
                instruct_1 <= (others => '0');
                instruct_2 <= temp_instr;
                instruct_3 <= (others => '0');
            when "11" =>  
                instruct_1 <= (others => '0');
                instruct_2 <= (others => '0');
                instruct_3 <= temp_instr;
            when others => 
                instruct_1 <= (others => '0');
                instruct_2 <= (others => '0');
                instruct_3 <= (others => '0');
        end case;
    end procedure;

    procedure decode_packet(
        signal packet_in   : in std_logic_vector(63 downto 0);
        signal opcode    : out std_logic_vector(5 downto 0);
        signal status    : out std_logic_vector(1 downto 0);
        signal source    : out std_logic_vector(1 downto 0);
        signal timestamp : out std_logic_vector(5 downto 0);
        signal temp_data    : out std_logic_vector(15 downto 0);
        signal light_data   : out std_logic_vector(15 downto 0);
        signal moist_data   : out std_logic_vector(15 downto 0)
    ) is
    begin
        source    <= packet_in(63 downto 62);
        status    <= packet_in(61 downto 60); 
        opcode    <= packet_in(59 downto 54); 
        timestamp <= packet_in(53 downto 48);
        temp_data <= packet_in(47 downto 32); 
        light_data<= packet_in(31 downto 16); 
        moist_data<= packet_in(15 downto 0); 
    end procedure;

    component station_controller_1 is
        port (
            CLK             : in std_logic;  
            instruction     : in std_logic_vector(7 downto 0);
            packet_report   : out std_logic_vector(63 downto 0)
        );
    end component;

    component station_controller_2 is
        port (
            CLK             : in std_logic;  
            instruction     : in std_logic_vector(7 downto 0);
            packet_report   : out std_logic_vector(63 downto 0)
        );
    end component;

    component station_controller_3 is
        port (
            CLK             : in std_logic;  
            instruction     : in std_logic_vector(7 downto 0);
            packet_report   : out std_logic_vector(63 downto 0)
        );
    end component;

    signal instruct_station_1 : std_logic_vector(7 downto 0);
    signal instruct_station_2 : std_logic_vector(7 downto 0);
    signal instruct_station_3 : std_logic_vector(7 downto 0);

begin

    controller1_inst: station_controller_1 
        Port map(
            CLK => CLK,
            instruction => instruct_station_1,
            packet_report => packet_report_1
        );

    controller2_inst: station_controller_2
        Port map(
            CLK => CLK,
            instruction => instruct_station_2,
            packet_report => packet_report_2
        );

    controller3_inst: station_controller_3
        Port map(
            CLK => CLK,
            instruction => instruct_station_3,
            packet_report => packet_report_3
        );

    state_machine: process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= Idle;
            opcode <= (others => '0');
            status <= (others => '0');
            source <= (others => '0');
            timestamp <= (others => '0');
            temp_data <= (others => '0');
            light_data <= (others => '0');
            moist_data <= (others => '0');
            instruct_station_1 <= (others => '0');
            instruct_station_2 <= (others => '0');
            instruct_station_3 <= (others => '0');
        elsif rising_edge(CLK) then
            current_state <= next_state;
            case current_state is
                when Idle =>
                    if instruction /= "00000000" then  
                        next_state <= Send_Inst;
                    else
                        current_state <= Idle;
                    end if;
                
                when Send_Inst =>
                    decode_instruction(instruction, instruct_station_1, instruct_station_2, instruct_station_3);
                    next_state <= Read_Pack;
                
                when Read_Pack =>
                    case instruction(7 downto 6) is
                        when "01" =>
                            active_packet <= packet_report_1;
                        when "10" =>
                            active_packet <= packet_report_2;
                        when "11" =>
                            active_packet <= packet_report_3;
                        when others =>
                            active_packet <= (others => '0');
                    end case;   
                    next_state <= Decode;
                
                when Decode =>
                    decode_packet(
                        active_packet, 
                        opcode, 
                        status, 
                        source, 
                        timestamp, 
                        temp_data, 
                        light_data, 
                        moist_data
                    );
                    next_state <= Report_Pack;

                when Report_Pack =>
                    active_report <= active_packet;
                    next_state <= Idle;
                
                when others =>
                    next_state <= Idle;
            end case;
        end if;
    end process;
end Behavioral;
