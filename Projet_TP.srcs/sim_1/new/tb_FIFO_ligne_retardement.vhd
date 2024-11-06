----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2024 15:29:16
-- Design Name: 
-- Module Name: tb_FIFO_ligne_retardement - Behavioral
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
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.STD_LOGIC_arith.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_FIFO_ligne_retardement is
--  Port ( );
end tb_FIFO_ligne_retardement;

architecture Behavioral of tb_FIFO_ligne_retardement is

component fifo_generator_0
    Port(  
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    prog_full_thresh : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC
  );
end component;


    signal clk_s :STD_LOGIC;
    signal rst_s :STD_LOGIC;
    signal din_s :STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal wr_en_s :STD_LOGIC;
    signal rd_en_s :STD_LOGIC;
    signal prog_full_thresh_s :STD_LOGIC_VECTOR(9 DOWNTO 0);
    signal dout_s :STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal full_s :STD_LOGIC;
    signal empty_s :STD_LOGIC;
    signal prog_full_s :STD_LOGIC;
    
    constant clock_period: time := 10 ns;
    signal clock_init: STD_LOGIC;
    
begin
uut: fifo_generator_0 port map (  
    clk =>clk_s,
    rst =>rst_s,
    din =>din_s,
    wr_en =>wr_en_s,
    rd_en =>rd_en_s,
    prog_full_thresh =>prog_full_thresh_s,
    dout =>dout_s,
    full =>full_s,
    empty =>empty_s,
    prog_full =>prog_full_s);
    
stimulus: process
begin
    clock_init <= '0';
    --dout_s <= x"00";
    --rd_en_s <= '0';
    wr_en_s <= '0';
    rst_s <= '1';
    -- seuil defini sur 3 octets
    prog_full_thresh_s <= "0000000011";
    --cabler la ligne à retard
    --rd_en_s <= prog_full_s;
    -- autres déclaration : RESET
    -- Put initialisation code here
    wait for 100 ns;
    clock_init <= '1';
    wait for 1*clock_period;
    rst_s <= '0';
    wait for 1*clock_period;
    din_s <= x"00";
    wait for 1*clock_period;
    --dout_s <= x"00";
    wait for 1*clock_period;
    -- Put test bench stimulus code here
    wr_en_s <= '1';
    wait for 1*clock_period;
    din_s <= din_s + "00000001";
    wait for 5*clock_period;
    din_s <= din_s + "00000001";
    wait for 5*clock_period;
    din_s <= din_s + "00000001";
    wait for 5*clock_period;
    din_s <= din_s + "00000001";
    wait for 5*clock_period;
    din_s <= din_s + "00000001";
    wait;
end process;
-- la structure when else ne tien pas dans un process
    --mise en place de la ligne à retard
--    rd_en_s <= '1' when (((prog_full_s ='1') and (empty_s ='0'))) else '0';

ligne_retard: process (prog_full_s, full_s, empty_s)
begin
    if ((full_s = '1' and empty_s = '1')) then 
    rd_en_s <= '0';
        --mise en place de la ligne à retard
    else
       if (prog_full_s = '1') then rd_en_s <= '1';
       else rd_en_s <= '0';
       end if;
    end if;
 end process;

clocking: process
  begin
     clk_s <= '0'; 
     wait for clock_period/2;
     clk_s <= clock_init;
     wait for clock_period/2;
  end process;

end Behavioral;
