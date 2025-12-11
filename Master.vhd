library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity spi_master is
    generic(addr_width  :   integer  := 8;
            data_width  :   integer  := 16);
    port(clk    :   in std_logic;
         rst    :   in std_logic;
         start  :   in std_logic;
         miso   :   in std_logic;
         r_w    :   in std_logic;
         w_addr :   in std_logic_vector(addr_width-1 downto 0);
         r_addr :   in std_logic_vector(addr_width-1 downto 0);
         data_in:   in std_logic_vector(data_width-1 downto 0);
         
         cs     :   out std_logic;
         sclk   :   out std_logic;
         mosi   :   out std_logic;
         data_out:  out std_logic_vector(data_width-1 downto 0));
end spi_master;

architecture Behavioral of spi_master is
    signal tcs      :   std_logic   := '0';
    signal div      :   integer     := 0;
    
    signal fedge    :   std_logic   := '0';
    signal dsclk    :   std_logic   := '0';
    signal psclk    :   std_logic   := '0';
    signal pedge    :   std_logic   := '0';
   
    signal shift_a  :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal shift_d  :   std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal count    :   integer range 0 to data_width   := 0;
    
    type fsm is(idle,rw,addr,Wdata,rdata);
    signal state    :   fsm     := idle;
begin
    
    process (clk, rst)
    begin
        if rst = '1' then
            div <= 0;
        elsif rising_edge(clk) then
            if tcs = '1' then
                div <= 0;
            else
                if div < 9 then
                    div <= div + 1;
                else
                    div <= 0;
                end if;
            end if;
        end if;
    end process;

    
    process (clk)is
    begin
        
        if tcs = '1' then
            psclk   <=  '0';
            
        elsif rising_edge (clk)  then
                    
            if div < 5 then
                psclk   <=  '0';
            else
                psclk   <=  '1';
            end if;
            
        end if;
        
    end process;
    
    process (clk)is
    begin
        if rising_edge (clk) then
            dsclk<=psclk;
        end if;
    end process;        
    
    fedge   <=  (dsclk and (not psclk));
    pedge   <=  (psclk and (not dsclk));
    
    sclk    <=  psclk;
    cs      <=  tcs;
            
    process (clk,rst)is
    begin
        if rst='1' then
            tcs     <=  '1';
--            psclk   <=  '0';
            mosi    <=  'Z';
            data_out<=  (others => '0');
            shift_a <=  (others => '0');
            shift_d <=  (others => '0');
            count   <=  0;
            state   <=  idle;
            
        elsif rising_edge (clk) then
            case state is
            
                when idle =>
                    tcs     <=  '1';
                    mosi    <=  '0';
                    count   <=  0;
                    shift_d <=  (others => '0');
                    
                    if start = '1' then
                        tcs <=  '0';
                        
                        if r_w = '0' then     --write
                            shift_a <=  w_addr;
                        end if;
                        
                        if r_w = '1' then     --read
                            shift_a <=  r_addr;
                        end if;
                        
                        state   <=  rw;
                        
                    end if;
                    
                when rw =>

                    if pedge = '1' then
                        mosi   <=  r_w;
                        count  <=  addr_width;
                        state  <=  addr;
                    end if;
                    
                when addr =>
                    
                    if pedge = '1' then
                        mosi    <=  shift_a(addr_width-1);
                        shift_a <=  shift_a(addr_width-2 downto 0) & '0';
                        count   <=  count-1;
                        
                        if count = 1 and r_w = '0' then    --write
                            shift_d <=  data_in;
                            count   <=  data_width;
                            state   <=  wdata;
                        end if;
                        
                        if count = 0 and r_w = '1' then    --read
                            shift_d <=  (others=>'0');
                            count   <=  data_width;
                            state   <=  rdata;
                        end if;
                        
                    end if;
                           
                when wdata =>
                    
                    if pedge = '1' then
                        mosi    <=  shift_d(data_width-1);
                        shift_d <=  shift_d(data_width-2 downto 0) & '0';
                        count   <=  count-1;
                        
                        if count = 0 then
                            tcs    <=  '1';
                            count  <=  0;
                            state  <=  idle;
                        end if;
                        
                    end if;
                    
                when rdata =>
                    
                    if fedge = '1' then
                        shift_d <=  shift_d(data_width-2 downto 0) & miso;
                        count   <=  count-1;
                        
                        if count = 1 then
                            data_out    <=  shift_d(data_width-2 downto 0) & miso;
                            tcs         <=  '1';
                            count       <=  0;
                            state       <=  idle;
                        end if;
                        
                    end if;

                when others =>
                    state   <=  idle;
                    
            end case;
            
        end if;
        
    end process;
        
end Behavioral;
