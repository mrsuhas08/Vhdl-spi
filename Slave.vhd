library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity spi_slave is
    generic(addr_width  :   integer := 8;
            data_width  :   integer := 16);
    port(clk    :   in std_logic;
         rst    :   in std_logic;
         sclk   :   in std_logic;
         cs     :   in std_logic;
         mosi   :   in std_logic;
         
         miso   :   out std_logic);
end spi_slave;

architecture Behavioral of spi_slave is
    constant depth  :   integer:=2**addr_width;
    signal reg_addr :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    
    signal fedge    :   std_logic   := '0';
    signal dsclk    :   std_logic   := '0';
    signal redge    :   std_logic   := '0';
    
    signal shift_rw :   std_logic   := '0';
    signal shift_a  :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal shift_d  :   std_logic_vector(data_width-1 downto 0) := (others => '0');
    
    signal count    :   integer range 0 to data_width   := 0;
    
    type store is array(depth-1 downto 0) of std_logic_vector(data_width-1 downto 0);
    signal mem      :   store   := (others => (others => '0'));
    
    type fsm is(idle,
                rw,
                addr,
                wdata,
                rdata);
    signal state    :   fsm     :=idle;
begin

    process (clk)is
    begin
    
        if rising_edge (clk)then
            dsclk   <=  sclk;
        end if;
        
    end process;
    
    fedge   <=  (dsclk and (not sclk));
    redge   <=  (sclk and (not dsclk));
    
    process(clk,rst)is
    begin
    
        if cs = '1' then
            miso    <=  'Z';
            reg_addr<=  (others => '0');
            shift_a <=  (others => '0');
            shift_d <=  (others => '0');
            shift_rw<=  '0';
            count   <=  0;
            state   <=  idle;
            
        elsif rising_edge(clk)then
        
            case state is
            
                when idle =>
                
                    count   <=  0;
                    state   <=  rw;
                    
                when rw =>
                
                    if fedge = '1' then
                        shift_rw<=  mosi;
                        count   <=  0;
                        state   <=  addr;
                    end if;
                    
                when addr =>
                
                    if fedge = '1' then
                    
                        if count < addr_width then
                            shift_a <=  shift_a(addr_width-2 downto 0) & mosi;
                            count   <=  count+1;
                            
                            if count = addr_width-1 then
                                reg_addr<=  shift_a(addr_width-2 downto 0) & mosi;
                                count   <=  0;
                                
                                if shift_rw = '1' then    --read
                                    shift_d <=  mem(TO_INTEGER(unsigned(shift_a(addr_width-2 downto 0) & mosi)));
                                    count   <=  0;
                                    state   <=  rdata;
                                end if;
                                
                                if shift_rw = '0' then    --write
                                    shift_d <=  (others => '0');
                                    count   <=  0;
                                    state   <=  wdata;
                                end if;
                                
                            end if;
                            
                        end if;
                        
                    end if;
                    
                when wdata =>
                
                    if fedge = '1' then
                    
                        if count >= 0 and count < data_width then
                            shift_d <=  shift_d(data_width-2 downto 0) & mosi;
                            count   <=  count+1;
                            
                            if count = data_width-1 then
                                mem(TO_INTEGER(unsigned(reg_addr))) <=  shift_d(data_width-2 downto 0) & mosi;
                            end if;
                            
                            if count = data_width then
                                count   <=  0;
                                state   <=  idle;
                            end if;
                            
                        end if;
                    
                    end if;
                
                when rdata =>
                
                    if fedge = '1' then
                    
                        if count >= 0 and count <data_width then
                            miso    <=  shift_d(data_width-1);
                            shift_d <=  shift_d(data_width-2 downto 0) & '0';
                            count   <=  count+1;
                            
                            if count = data_width then
                                count   <=  0;
                                state   <=  idle;
                            end if;
                            
                        end if;
                    
                    end if;
                
                when others =>
                
                    state   <=  idle;
                    
            end case;
            
        end if;
        
    end process;
    
end Behavioral;
