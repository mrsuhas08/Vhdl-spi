library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity spi_topmodule is
        generic(addr_width  :   integer  := 8;
                data_width  :   integer  := 16);
        port(clk    :   in std_logic;
             rst    :   in std_logic;
             start  :   in std_logic;
             r_w    :   in std_logic;
             w_addr :   in std_logic_vector(addr_width-1 downto 0);
             r_addr :   in std_logic_vector(addr_width-1 downto 0);
             data_in:   in std_logic_vector(data_width-1 downto 0);
             
             cs     :   out std_logic;
             sclk   :   out std_logic;
             mosi   :   out std_logic;
             data_out:  out std_logic_vector(data_width-1 downto 0));
end spi_topmodule;

architecture Behavioral of spi_topmodule is
    component spi_master is
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
    end component;
    
    component spi_slave is
        generic(addr_width  :   integer := 8;
                data_width  :   integer := 16);
        port(sclk   :   in std_logic;
             cs     :   in std_logic;
             mosi   :   in std_logic;
             
             miso   :   out std_logic);
    end component;
    
    signal sclk_w   :   std_logic   := '0';
    signal cs_w     :   std_logic   := '0';
    signal mosi_w   :   std_logic   := '0';
    signal miso_w   :   std_logic   := '0';
begin

    cs   <= cs_w;
    sclk <= sclk_w;
    mosi <= mosi_w;
    
    master: spi_master
        generic map(addr_width => addr_width,
                    data_width => data_width)
        port map(clk    =>  clk,
                rst     =>  rst,
                start   =>  start,
                miso    =>  miso_w,
                r_w     =>  r_w,
                w_addr  =>  w_addr,
                r_addr  =>  r_addr,
                data_in =>  data_in,
                cs      =>  cs_w,
                sclk    =>  sclk_w,
                mosi    =>  mosi_w,
                data_out=>  data_out);
    slave: spi_slave
        generic map(addr_width => addr_width,
                    data_width => data_width)
        port map(sclk   =>  sclk_w,
                cs      =>  cs_w,
                mosi    =>  mosi_w,
                miso    =>  miso_w);

end Behavioral;
