----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.12.2025 16:55:45
-- Design Name: 
-- Module Name: spi_slave - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave is
    generic(addr_width  :   integer := 8;
            data_width  :   integer := 16);
    port(clk    :   in std_logic;
         rst    :   in std_logic;
         sclk_s :   in std_logic;
         cs_s   :   in std_logic;
         mosi_s :   in std_logic;
         
         miso_s :   out std_logic);
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
            dsclk   <=  sclk_s;
        end if;
        
    end process;
    
    fedge   <=  (dsclk  and (not sclk_s));
    redge   <=  (sclk_s and (not dsclk));
    
    process(clk,rst)is
    begin
    
        if cs_s = '1' then
            miso_s  <=  'Z';
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
                        shift_rw<=  mosi_s;
                        count   <=  0;
                        state   <=  addr;
                    end if;
                    
                when addr =>
                
                    if fedge = '1' then
                    
                        if count < addr_width then
                            shift_a <=  shift_a(addr_width-2 downto 0) & mosi_s;
                            count   <=  count+1;
                            
                            if count = addr_width-1 then
                                reg_addr<=  shift_a(addr_width-2 downto 0) & mosi_s;
                                count   <=  0;
                                
                                if shift_rw = '1' then    --read
                                    shift_d <=  mem(TO_INTEGER(unsigned(shift_a(addr_width-2 downto 0) & mosi_s)));
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
                            shift_d <=  shift_d(data_width-2 downto 0) & mosi_s;
                            count   <=  count+1;
                            
                            if count = data_width-1 then
                                mem(TO_INTEGER(unsigned(reg_addr))) <=  shift_d(data_width-2 downto 0) & mosi_s;
                                
                            end if;
                            
                            if count = data_width then
                                count   <=  0;
                                state   <=  idle;
                                
                            end if;
                            
                        end if;
                    
                    end if;
                
                when rdata =>
                
                    if fedge = '1' then
                    
                        if count >= 0 and count < data_width then
                            miso_s  <=  shift_d(data_width-1);
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
