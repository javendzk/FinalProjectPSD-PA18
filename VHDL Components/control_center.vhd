library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity control_center is
    Port (
        CLK              : in std_logic;
        RESET            : in std_logic;
        instruction      : in std_logic_vector(7 downto 0);
        active_report    : out std_logic_vector(63 downto 0)
    );
end control_center;

architecture Behavioral of control_center is
    constant QUEUE_DEPTH : integer := 12;  
    
    type packet_queue_type is array (0 to QUEUE_DEPTH-1) of std_logic_vector(63 downto 0);
    
    signal packet_queue : packet_queue_type;
    signal queue_head : integer range 0 to QUEUE_DEPTH-1 := 0;
    signal queue_tail : integer range 0 to QUEUE_DEPTH-1 := 0;
    signal queue_count : integer range 0 to QUEUE_DEPTH := 0;
    signal queue_empty : std_logic := '0';
    signal queue_full : std_logic := '0';

    signal source    : std_logic_vector(1 downto 0);
    signal status    : std_logic_vector(1 downto 0);
    signal opcode    : std_logic_vector(5 downto 0);
    signal timestamp : std_logic_vector(5 downto 0);
    signal temp_data, light_data, moist_data : std_logic_vector(15 downto 0);
    signal active_packet : std_logic_vector(63 downto 0);

    signal packet_report_1 : std_logic_vector(63 downto 0);
    signal packet_report_2 : std_logic_vector(63 downto 0);
    signal packet_report_3 : std_logic_vector(63 downto 0);

    signal instruct_station_1 : std_logic_vector(7 downto 0);
    signal instruct_station_2 : std_logic_vector(7 downto 0);
    signal instruct_station_3 : std_logic_vector(7 downto 0);

    type state_type is (Idle, Send_Inst, Read_Pack, Queue_All_Packs, Dequeue_Pack, Decode, Report_Pack);
    signal current_state, next_state : state_type;

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

    procedure decode_instruction(
        signal instr : in std_logic_vector(7 downto 0);
        signal instruct_1, instruct_2, instruct_3 : out std_logic_vector(7 downto 0)
    ) is
        variable temp_instr : std_logic_vector(7 downto 0);
    begin
        temp_instr := instr; 
        
        case temp_instr(7 downto 6) is
            when "01" =>  
                instruct_1 <= temp_instr;
            when "10" => 
                instruct_2 <= temp_instr;
            when "11" =>  
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

    state_register: process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= Idle;
        elsif rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process state_register;

    next_state_logic: process(current_state, instruction, queue_count, 
                               packet_report_1, packet_report_2, packet_report_3)
    begin        
        case current_state is
            when Idle =>
                if instruction /= "00000000" then  
                    next_state <= Send_Inst;
                end if;
            
            when Send_Inst =>
                next_state <= Read_Pack;
            
            when Read_Pack =>
                next_state <= Queue_All_Packs;
            
            when Queue_All_Packs =>
                if queue_count > 0 then
                    next_state <= Dequeue_Pack;
                else
                    next_state <= Idle;
                end if;
            
            when Dequeue_Pack =>
                next_state <= Decode;
            
            when Decode =>
                next_state <= Report_Pack;

            when Report_Pack =>
                if queue_count > 0 then
                    next_state <= Dequeue_Pack;
                else
                    next_state <= Idle;
                end if;
            
            when others =>
                next_state <= Idle;
        end case;
    end process next_state_logic;

    state_actions: process(CLK, RESET)
    begin
        if RESET = '1' then
            queue_head <= 0;
            queue_tail <= 0;
            queue_count <= 0;
            queue_full <= '0';
            queue_empty <= '1';
            
            active_report <= (others => '0');
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
            if queue_count = QUEUE_DEPTH then
                queue_full <= '1';
            else 
                queue_full <= '0';
            end if;

            if queue_count = 0 then
                queue_empty <= '1';
            else 
                queue_empty <= '0';
            end if;
                        
            case current_state is
                when Send_Inst =>
                    decode_instruction(
                        instruction, 
                        instruct_station_1, 
                        instruct_station_2, 
                        instruct_station_3);
                
                when Read_Pack =>
                    if queue_count < QUEUE_DEPTH - 2 then
                        packet_queue(queue_tail) <= packet_report_1;
                        packet_queue(queue_tail + 1) <= packet_report_2;
                        packet_queue(queue_tail + 2) <= packet_report_3;
                        queue_tail <= (queue_tail + 3) mod QUEUE_DEPTH;
                        queue_count <= queue_count + 3;
                    end if;
                
                when Dequeue_Pack =>
                    if queue_count > 0 then
                        active_packet <= packet_queue(queue_head);
                        queue_head <= (queue_head + 1) mod QUEUE_DEPTH;
                        queue_count <= queue_count - 1;
                    end if;
                
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
                
                when Report_Pack =>
                    active_report <= active_packet;
                
                when others =>
                    null;
            end case;
        end if;
    end process state_actions;
end Behavioral;