----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.12.2025 11:50:52
-- Design Name: 
-- Module Name: spi_master - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_master is
    generic(addr_width  :   integer  := 8;
            data_width  :   integer  := 16);
    port(clk    :   in std_logic;
         rst    :   in std_logic;
         start  :   in std_logic;
         miso_m :   in std_logic;
         r_w    :   in std_logic;
         w_addr :   in std_logic_vector(addr_width-1 downto 0);
         r_addr :   in std_logic_vector(addr_width-1 downto 0);
         data_in:   in std_logic_vector(data_width-1 downto 0);
         
         cs_m   :   out std_logic;
         sclk_m :   out std_logic;
         mosi_m :   out std_logic;
         data_out:  out std_logic_vector(data_width-1 downto 0));
end spi_master;

architecture Behavioral of spi_master is
    signal tcs      :   std_logic   := '0';
    signal div      :   integer     := 0;
    
    signal fedge    :   std_logic   := '0';
    signal dsclk    :   std_logic   := '0';
    signal psclk    :   std_logic   := '0';
    signal redge    :   std_logic   := '0';
   
    signal shift_a  :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal shift_d  :   std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal count    :   integer range 0 to data_width   := 0;
    
    type fsm is(idle,
                rw,
                addr,
                Wdata,
                rdata);
    signal state    :   fsm     := idle;
    
begin
    
    process (clk, rst)
    begin
    
        if rst = '0' then
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
    redge   <=  (psclk and (not dsclk));
    
    sclk_m  <=  psclk;
    cs_m    <=  tcs;
            
    process (clk,rst)is
    begin
        if rst='0' then
            tcs     <=  '1';
--            psclk   <=  '0';
            mosi_m  <=  'Z';
            data_out<=  (others => '0');
            shift_a <=  (others => '0');
            shift_d <=  (others => '0');
            count   <=  0;
            state   <=  idle;
            
        elsif rising_edge (clk) then
        
            case state is
            
                when idle =>
                
                    tcs     <=  '1';
                    mosi_m  <=  '0';
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

                    if redge = '1' then
                        mosi_m <=  r_w;
                        count  <=  addr_width;
                        state  <=  addr;
                        
                    end if;
                    
                when addr =>
                    
                    if redge = '1' then
                        mosi_m  <=  shift_a(addr_width-1);
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
                    
                    if redge = '1' then
                        mosi_m  <=  shift_d(data_width-1);
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
                        shift_d <=  shift_d(data_width-2 downto 0) & miso_m;
                        count   <=  count-1;
                        
                        if count = 0 then
                            data_out    <=  shift_d(data_width-2 downto 0) & miso_m;
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
