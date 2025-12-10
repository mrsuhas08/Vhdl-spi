library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use std.env.ALL;

entity spi_testbench is
--  Port ( );
end spi_testbench;

architecture Behavioral of spi_testbench is
    constant addr_width :   integer := 8;
    constant data_width :   integer := 16;
    
    signal clk      :   std_logic   := '0';
    signal rst      :   std_logic   := '0';
    signal start    :   std_logic   := '0';
    signal miso     :   std_logic   := '0';
    signal r_w      :   std_logic   := '0';
    signal w_addr   :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal r_addr   :   std_logic_vector(addr_width-1 downto 0) := (others => '0');
    signal data_in  :   std_logic_vector(data_width-1 downto 0) := (others => '0');
    
    signal cs       :   std_logic;
    signal sclk     :   std_logic;
    signal mosi     :   std_logic; 
    signal data_out :   std_logic_vector(data_width-1 downto 0);
begin
    dut: entity work.spi_topmodule
        generic map(addr_width  =>  addr_width,
                    data_width  =>  data_width)
        port map(clk    =>  clk,
                rst     =>  rst,
                start   =>  start,
                r_w     =>  r_w,
                w_addr  =>  w_addr,
                r_addr  =>  r_addr,
                data_in =>  data_in,
                cs      =>  cs,
                sclk    =>  sclk,
                mosi    =>  mosi,
                data_out=>  data_out);
    process
    begin
        wait for 5 ns;
            clk <=  not clk;
    end process;
    
    process
    begin
        rst <=  '1';
        
        wait for 10 ns;
        rst <=  '0';
        start   <=  '1';
            r_w <=  '0';
            w_addr  <=  x"fe";
            data_in <=  x"fefe";
            
        wait for 2570 ns;
            r_w <=  '1';
            r_addr  <=  x"fe";
            
        wait for 2640 ns;
            r_w <=  '0';
            w_addr  <=  x"fd";
            data_in <=  x"fdfd";
            
        wait for 2580 ns;
            w_addr  <=  x"fc";
            data_in <=  x"fcfc";
            
        wait for 2580 ns;
            w_addr  <=  x"fb";
            data_in <=  x"fbfb";
            
        wait for 2580 ns;
            r_w <=  '1';
            r_addr  <=  x"fd";
            
        wait for 2630 ns;
            r_addr  <=  x"fc";
            
        wait for 2630 ns;
            r_addr  <=  x"fb";
            
        wait for 2630 ns;
            r_addr  <=  x"fd";
        
        wait for 2630 ns;
            r_w <=  '0';
            w_addr  <=  x"fa";
            data_in <=  x"fafa";
            
        wait for 2580 ns;
            r_w <=  '1';
            r_addr  <=  x"fa";
            
        wait for 2630 ns;
            start   <=  '0';
            
        wait for 2000 ns;
        finish;
    end process;
end Behavioral;
