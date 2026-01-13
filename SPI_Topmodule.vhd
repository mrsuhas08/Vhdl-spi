----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.12.2025 18:00:53
-- Design Name: 
-- Module Name: spi_topmodule - Behavioral
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

entity spi_topmodule is
        generic(addr_width  :   integer  := 8;
                data_width  :   integer  := 16);
        port(clk        :   in std_logic;
             rst        :   in std_logic;
             --master
             miso_m     :   in std_logic;--36
             cs_m       :   out std_logic;--35
             sclk_m     :   out std_logic;--34
             mosi_m     :   out std_logic;--37
             --slave
             miso_s     :   out std_logic;--31
             cs_s       :   in std_logic;--32
             sclk_s     :   in std_logic;--33
             mosi_s     :   in std_logic);--30
             
end spi_topmodule;

architecture Behavioral of spi_topmodule is
    component spi_master is
        generic(addr_width  :   integer  := 8;
                data_width  :   integer  := 16);
        port(clk            :   in std_logic;
             rst            :   in std_logic;
             start          :   in std_logic;
             r_w            :   in std_logic;
             w_addr         :   in std_logic_vector(addr_width-1 downto 0);
             r_addr         :   in std_logic_vector(addr_width-1 downto 0);
             data_in        :   in std_logic_vector(data_width-1 downto 0);
             
             
             miso_m         :   in std_logic;
             cs_m           :   out std_logic;
             sclk_m         :   out std_logic;
             mosi_m         :   out std_logic;
             
             data_out       :   out std_logic_vector(data_width-1 downto 0));
    end component;
    
    component spi_slave is
        generic(addr_width  :   integer := 8;
                data_width  :   integer := 16);
        port(clk        :   in std_logic;
             rst        :   in std_logic;
             
             sclk_s     :   in std_logic;
             cs_s       :   in std_logic;
             mosi_s     :   in std_logic;
             
             miso_s     :   out std_logic);
    end component;
    
    COMPONENT ila_0
        PORT (clk       : IN STD_LOGIC;
              probe0    :   IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
              probe1    :   IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
              probe2    :   IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
              probe3    :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
              probe4    :   IN STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT  ;
    
    COMPONENT vio_1
        PORT(clk        : IN STD_LOGIC;
             probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
             probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
             probe_out2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
             probe_out3 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
             probe_out4 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
             probe_out5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
    END COMPONENT;
    
    -- inputs
    signal rst_vio  :   std_logic;
    signal start    :   std_logic;
    signal r_w      :   std_logic;
    signal w_addr   :   std_logic_vector(addr_width-1 downto 0);
    signal r_addr   :   std_logic_vector(addr_width-1 downto 0);
    signal data_in  :   std_logic_vector(data_width-1 downto 0);
    -- output
    signal data_out :   std_logic_vector(data_width-1 downto 0) := (others => '0');
    
begin
    
    master: spi_master
        generic map(addr_width => addr_width,
                    data_width => data_width)
        port map(clk        =>  clk,
                rst         =>  rst_vio,
                start       =>  start,
                r_w         =>  r_w,
                w_addr      =>  w_addr,
                r_addr      =>  r_addr,
                data_in     =>  data_in,
                
                miso_m      =>  miso_m,
                cs_m        =>  cs_m,
                sclk_m      =>  sclk_m,
                mosi_m      =>  mosi_m,
                
                data_out    =>  data_out);
                
    slave: spi_slave
        generic map(addr_width => addr_width,
                    data_width => data_width)
        port map(clk        =>  clk,
                rst         =>  rst_vio,
                
                sclk_s      =>  sclk_s,
                cs_s        =>  cs_s,
                mosi_s      =>  mosi_s,
                miso_s      =>  miso_s);
                
    signals : ila_0
        PORT MAP (clk       =>  clk,
                  probe0(0) =>  sclk_s, 
                  probe1(0) =>  cs_s, 
                  probe2(0) =>  mosi_s, 
                  probe3(0) =>  miso_m,
                  probe4    =>  data_out);
    
    inputs : vio_1
        PORT MAP (clk           =>  clk,
                  probe_out0(0) =>  start,
                  probe_out1(0) =>  r_w,
                  probe_out2    =>  w_addr,
                  probe_out3    =>  r_addr,
                  probe_out4    =>  data_in,
                  probe_out5(0) =>  rst_vio);
   
end Behavioral;
