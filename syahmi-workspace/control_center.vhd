library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity Weather_Control_Center is
    Port (
        CLK          : in std_logic;        
        RESET        : in std_logic;        
        packet_in    : in std_logic_vector(63 downto 0); 
        data_ready   : in std_logic 
    );
end Weather_Control_Center;

architecture Behavioral of Weather_Control_Center is

    signal opcode    : std_logic_vector(5 downto 0);
    signal status    : std_logic_vector(1 downto 0);
    signal source    : std_logic_vector(1 downto 0);
    signal timestamp : std_logic_vector(5 downto 0);
    signal temp_data, light_data, moist_data : std_logic_vector(15 downto 0);

    type state_type is (Idle, Decode, Format, Writing);
    signal current_state, next_state : state_type;

    file data_file : text open write_mode is "weather_data.csv";
    variable line_buffer : line;

    signal formatted_data : std_logic_vector(127 downto 0);

    component Packet_Decoder is
        Port (
            packet_in    : in std_logic_vector(63 downto 0);
            opcode       : out std_logic_vector(5 downto 0);
            status       : out std_logic_vector(1 downto 0);
            source       : out std_logic_vector(1 downto 0);
            timestamp    : out std_logic_vector(5 downto 0);
            temp_data    : out std_logic_vector(15 downto 0);
            light_data   : out std_logic_vector(15 downto 0);
            moist_data   : out std_logic_vector(15 downto 0)
        );
    end component;

    procedure decode_packet(
        packet_in    : in std_logic_vector(63 downto 0);
        opcode       : out std_logic_vector(5 downto 0);
        status       : out std_logic_vector(1 downto 0);
        source       : out std_logic_vector(1 downto 0);
        timestamp    : out std_logic_vector(5 downto 0);
        temp_data    : out std_logic_vector(15 downto 0);
        light_data   : out std_logic_vector(15 downto 0);
        moist_data   : out std_logic_vector(15 downto 0)
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
    decoder_inst : Packet_Decoder
        Port map (
            packet_in    => packet_in,
            opcode       => opcode,
            status       => status,
            source       => source,
            timestamp    => timestamp,
            temp_data    => temp_data,
            light_data   => light_data,
            moist_data   => moist_data
        );

    process(CLK, RESET)
    begin
        if RESET = '1' then
            current_state <= Idle;
        elsif rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, data_ready, opcode, status, source, timestamp, temp_data, light_data, moist_data)
    begin
        next_state <= current_state;

        case current_state is
            when Idle =>
                if data_ready = '1' then
                    next_state <= Decode;
                end if;

            when Decode =>
                decode_packet(packet_in, opcode, status, source, timestamp, temp_data, light_data, moist_data);
                next_state <= Format;

            when Format =>
                formatted_data <= source & status & opcode & timestamp & 
                                  temp_data & light_data & moist_data;
                next_state <= writing;

            when writing =>
                write(line_buffer, source & ",");
                write(line_buffer, status & ",");
                write(line_buffer, opcode & ",");
                write(line_buffer, timestamp & ",");
                write(line_buffer, integer'image(to_integer(unsigned(temp_data))) & ",");
                write(line_buffer, integer'image(to_integer(unsigned(light_data))) & ",");
                write(line_buffer, integer'image(to_integer(unsigned(moist_data))));
                writeline(data_file, line_buffer);
                next_state <= Idle;
        end case;
    end process;

end Behavioral;
