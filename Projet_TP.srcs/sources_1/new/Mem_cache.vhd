----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.09.2024 10:32:30
-- Design Name: 
-- Module Name: Mem_cache - Behavioral
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
use IEEE.NUMERIC_STD.ALL; -- pour les opérations arithmétiques

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Mem_cache is
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
end Mem_cache;

architecture Behavioral of Mem_cache is

component FF_jd 
    Port ( D : in STD_LOGIC_VECTOR (7 downto 0);
           Q : out STD_LOGIC_VECTOR (7 downto 0);
           Clk : in STD_LOGIC;
           EN : in STD_LOGIC;
           RESET : in STD_LOGIC);
end component;

component fifo_generator_0
  PORT (
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
END component;

--signaux fifos
--signal wr_en_fifo :std_logic;
--signal rd_en_fifo :std_logic;
signal prog_full_thresh_s : std_logic_vector (9 downto 0);
signal full_s : std_logic;
signal empty_s : std_logic;
signal prog_full_s: std_logic;

signal full_2s : std_logic;
signal empty_2s : std_logic;
signal prog_full_2s: std_logic;
--signal wr_en_fifo2 :std_logic;
--signal rd_en_fifo2 :std_logic;

--signaux bascules
-- 72 bits + 24 de transition après les fifos - 8 bits de la derniere fifo que nous avons retiré
signal transit : std_logic_vector (87 downto 0);

--signaux pour filtrage SOBEL 
signal Gx, Gy : integer range -1024 to 1024;
signal magnitude : integer range 0 to 2048;
--signal P33 : STD_LOGIC_VECTOR (7 downto 0);
--signal P32 : STD_LOGIC_VECTOR (7 downto 0);
--signal P31 : STD_LOGIC_VECTOR (7 downto 0);
--signal P23 : STD_LOGIC_VECTOR (7 downto 0);
--signal P22 : STD_LOGIC_VECTOR (7 downto 0);
--signal P21 : STD_LOGIC_VECTOR (7 downto 0);
--signal P13 : STD_LOGIC_VECTOR (7 downto 0);
--signal P12 : STD_LOGIC_VECTOR (7 downto 0);
--signal P11 : STD_LOGIC_VECTOR (7 downto 0);

--signal temp_magnitude : std_logic_vector(7 downto 0);
signal temp_transit_magnitude : std_logic_vector(7 downto 0);
signal temp_pixels : std_logic_vector(71 downto 0); -- Pour les 9 pixels utilisés
signal enable_temp : std_logic := '0'; -- Signal de contrôle du multiplexeur
signal transit_bascule   : std_logic_vector(87 downto 0); -- Sortie des bascules

begin
-------------------------------------------------------------
-- INSTANCIATION COMPOSANTS --
-------------------------------------------------------------
-- 3 premieres bascules--------------------------------------
    FU1:FF_jd  port map(
        din( 7 downto 0 ),     
        transit(7 downto 0),       
        Clk,
        enable_bascule,
        reset);

FF_REG_1: for I in 1 to 2 generate
    FUX:FF_jd  port map(
        transit_bascule((I*8)-1 downto (I-1)*8),     
        transit_bascule((I*8)+7 downto I*8),       
        Clk,
        enable_bascule,
        reset
        );    
end generate;
-----------------------------------------------------------
-- 2 e vague de bascule (n° 4, 5, 6 )
FF_REG_2: for I in 4 to 6 generate
    FUX2:FF_jd  port map(
        transit_bascule((I*8)-1 downto (I-1)*8),     
        transit_bascule((I*8)+7 downto I*8),       
        Clk,
        enable_bascule,
        reset
        );    
end generate;

-- 3e vague de bascule (n° 7, 8, 9)
FF_REG_3: for I in 8 to 10 generate
    FUX3:FF_jd  port map(
        transit_bascule((I*8)-1 downto (I-1)*8),     
        transit_bascule((I*8)+7 downto I*8),       
        Clk,
        enable_bascule,
        reset
        );    
end generate;

-- Les 3 fifo du systeme (pour la troisième, on considere seulement le bus)
    U0:fifo_generator_0 port map(
        clk,
        reset,
        transit(23 downto 16),
        write_fifo_1,
        prog_full_s , --ligne à retard (rd_en)
        treshold(9 downto 0),
        transit(31 downto 24),
        full_s ,
        empty_s,
        prog_full_s
        );

    U1:fifo_generator_0 port map(
        clk,
        reset,
        transit(55 downto 48),
        write_fifo_2,
        prog_full_2s, --ligne à retard (rd_en)
        treshold(9 downto 0),
        transit(63 downto 56),
        full_2s ,
        empty_2s,
        prog_full_2s
        );
-------------------------------------------------------------
-- FIN INSTANCIATION COMPOSANTS --
-------------------------------------------------------------
    --prog_full_thresh_s <= "0001111101"; -- initialisation du seuil des fifo à 125 ( 3 mots stockés dans les bascules)

    dout <= transit(87 downto 80); -- fin du bus de transit de données

-- Processus pour Sobel et contrôle du multiplexeur
sobel: process(CLK, RESET)
begin
    if RESET = '1' then
        -- Réinitialisation des signaux
        enable_temp <= '0';
        Gx <= 0;
        Gy <= 0;
        temp_pixels <= (others => '0');
        temp_transit_magnitude <= (others => '0');
    elsif rising_edge(CLK) then
        if DATA_VALID = '1' then
            -- Mise à jour des pixels
            temp_pixels(7 downto 0) <= transit(7 downto 0);
            temp_pixels(15 downto 8) <= transit(15 downto 8);
            temp_pixels(23 downto 16) <= transit(23 downto 16);
            temp_pixels(31 downto 24) <= transit(31 downto 24);
            temp_pixels(39 downto 32) <= transit(39 downto 32);
            temp_pixels(47 downto 40) <= transit(47 downto 40);
            temp_pixels(55 downto 48) <= transit(55 downto 48);
            temp_pixels(63 downto 56) <= transit(63 downto 56);
            temp_pixels(71 downto 64) <= transit(71 downto 64);

            -- Calcul des gradients
            Gx <= (-1 * to_integer(unsigned(temp_pixels(71 downto 64)))) + 
                  ( 1 * to_integer(unsigned(temp_pixels(55 downto 48)))) + 
                  (-2 * to_integer(unsigned(temp_pixels(47 downto 40)))) + 
                  ( 2 * to_integer(unsigned(temp_pixels(31 downto 24)))) + 
                  (-1 * to_integer(unsigned(temp_pixels(23 downto 16)))) + 
                  ( 1 * to_integer(unsigned(temp_pixels(7 downto 0))));

            Gy <= ( 1 * to_integer(unsigned(temp_pixels(71 downto 64)))) + 
                  ( 2 * to_integer(unsigned(temp_pixels(63 downto 56)))) + 
                  ( 1 * to_integer(unsigned(temp_pixels(55 downto 48)))) + 
                  (-1 * to_integer(unsigned(temp_pixels(23 downto 16)))) + 
                  (-2 * to_integer(unsigned(temp_pixels(15 downto 8)))) + 
                  (-1 * to_integer(unsigned(temp_pixels(7 downto 0))));

            -- Calcul de la magnitude
            temp_transit_magnitude <= std_logic_vector(to_unsigned(abs(Gx) + abs(Gy), 8));

            -- Activation du multiplexeur
            enable_temp <= '1';
        else
            -- Désactiver le multiplexeur si pas de données valides
            enable_temp <= '0';
        end if;
    end if;
end process;

-- Multiplexage pour résoudre le conflit sur transit(39 downto 32)
transit(39 downto 32) <= temp_transit_magnitude when enable_temp = '1' else
                         transit_bascule(39 downto 32);
    
end Behavioral;
