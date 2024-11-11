----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.09.2024 14:38:47
-- Design Name: 
-- Module Name: Mem_Cache_tb - Behavioral
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
use std.textio.all;
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mem_Cache_tb is
--  Port ( );
end Mem_Cache_tb;

architecture Behavioral of Mem_Cache_tb is

    component Mem_cache
      Port (DATA_VALID: in STD_LOGIC;
            Din : in STD_LOGIC_VECTOR (7 downto 0);
            CLK : in std_logic;
            RESET : in std_logic;
            Dout: out STD_LOGIC_VECTOR (7 downto 0);
            NB_AVAILABLE : in STD_LOGIC;
            write_fifo_1 : in std_logic;
            write_fifo_2 : in std_logic;
            enable_bascule : in std_logic;
            treshold: in std_logic_vector (9 downto 0));
    end component;

        signal DATA_VALID_s:  STD_LOGIC;
        signal Din_s : STD_LOGIC_VECTOR (7 downto 0);
        signal CLK_s : std_logic;
        signal RESET_s : std_logic;
        signal Dout_s : STD_LOGIC_VECTOR (7 downto 0);
        signal NB_AVAILABLE_s : STD_LOGIC;
        signal FLAG_synchro : STD_LOGIC;
        signal counter : STD_LOGIC_VECTOR (14 downto 0);
        signal write_fifo_1_s :std_logic;
        signal write_fifo_2_s :std_logic;
        signal treshold_s : std_logic_vector (9 downto 0);
        signal enable_bascule_s : std_logic;
        signal I1 : std_logic_vector (7 downto 0);
        signal O1 : std_logic_vector (7 downto 0); 
        
        constant clock_period: time := 10 ns;
        signal clock_init: STD_LOGIC;

    
    begin

        uut: Mem_cache port map (  
            DATA_VALID => DATA_VALID_s,
            clk =>clk_s,
            RESET =>RESET_s,
            Din =>Din_s,
            Dout =>Dout_s,
            NB_AVAILABLE => NB_AVAILABLE_s,
            write_fifo_1 =>write_fifo_1_s,
            write_fifo_2 =>write_fifo_2_s,
            enable_bascule => DATA_VALID_s,
            treshold => treshold_s );
            
    stimuli: process
        begin

            clock_init <= '0';
            FLAG_synchro <= '0';
            write_fifo_2_s <= '0';
            write_fifo_1_s <= '0';
            NB_AVAILABLE_s <= '0';
            RESET_s <= '1';
            -- Put initialisation code here
            wait for 100 ns;
            clock_init <= '1';
            wait for 10*clock_period;
            RESET_s <= '0';
            wait for 1*clock_period;
            treshold_s <= "0001111011"; --treshold à 123 -> 125 (7D) octets de stockage
            wait for 10*clock_period;
            wait until (clk_s'event and clk_s ='1');
            FLAG_synchro <= '1';
            wait for 1*clock_period;       
            -- Put test bench stimulus code here  
--            if (counter ="0000001111")then --counter = 16
--                FLAG_synchro <='0';
--            end if;
            wait until (DATA_VALID_s ='1');
                wait for 2*clock_period; -- 3 octets après que data_valid soit passé à 1
                write_fifo_1_s <= '1';          
                wait for 12*clock_period;-- 16 octets après que data_valid soit passé à 1
                write_fifo_2_s <= '1';
            wait until (counter = "000000100000011"); --259 cycles
                NB_AVAILABLE_s <= '1'; --signal de control pour savoir quand une donnée rentre dans dout_s
            wait until(counter = "100000000000000"); --16384 cycles + 259
                wait for 259*clock_period;
                NB_AVAILABLE_s <= '0';
            wait;
        end process;
        
--    compteur: process
--         begin
--         counter <= (others => '0');
--         wait until (DATA_VALID_s ='1'); 
--                if(CLK_s'event and clk_s='1') then
--                counter <= counter + 1; 
--        end if;
--        wait;
--    end process;
    
    picture_read: process
        FILE vectors : text;
        variable Iline : line;
        variable I1_var :std_logic_vector (7 downto 0);
        
        begin
        counter <= (others => '0');
        din_s <= x"00";
        DATA_VALID_s <= '0';
        -- penser à changer le path quand on change d'appareil
        file_open (vectors,"C:\Users\evanm\Documents\ESIREM\4a\S7\FPGA\Projet_TP\Lena128x128g_8bits.dat", read_mode);
        wait until (FLAG_synchro'event and  FLAG_synchro='1' );
        wait for 4*clock_period;
        DATA_VALID_s <= '1';       
        --wait for 1*clock_period;
        while not endfile(vectors) loop
        readline (vectors,Iline);
        read (Iline,I1_var);
 
        din_s <= I1_var;
        counter <= counter + 1;
        
        wait for 1*clock_period;
          --wait for 10 ns;
        end loop;
        --DATA_VALID_s <= '0';
        wait for 1*clock_period;
        file_close (vectors);
        wait;
    end process;
    
    pricture_writing : process
        file results : text;
        variable OLine : line;
        variable O1_var :std_logic_vector (7 downto 0);
    
        begin
        -- penser à changer le path quand on change d'appareil
        file_open (results,"C:\Users\evanm\Documents\ESIREM\4a\S7\FPGA\Projet_TP\Lena128x128g_8bits_reconstituee.dat", write_mode);
        --ligne ajoutée
        wait for 1*clock_period;
        wait until NB_AVAILABLE_s = '1';
        wait for 1*clock_period;
        -- changer la valeur '1' en '0' pour écrire quand nous sommes à data_available à 1
        while not NB_AVAILABLE_s ='0' loop
        write (Oline, Dout_s, right, 2);
        writeline (results, Oline);
        wait for 1*clock_period;  
        end loop;
        file_close (results);
        wait;
        
    end process;
--O1 <= I1;
--    rampe:process
--        begin
--            din_s <= x"00";
--            DATA_VALID_s <='0';
--            wait for 10 ns;
--            wait until (FLAG_synchro'event and  FLAG_synchro='1' );
--            wait for 4*clock_period;
--            DATA_VALID_s <='1'; -- début de l'ecriture
            
--            while(FLAG_synchro = '1') loop
--                din_s <= din_s +1;      
--                wait for 1*clock_period;
--            end loop;
              
--            --wait for 1*clock_period;
--            wait;
--        end process;
        
    clocking: process
        begin
            clk_s <= '0'; 
            wait for clock_period/2;
            clk_s <= clock_init;
            wait for clock_period/2;
        end process;
      
end Behavioral;
