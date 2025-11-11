LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE LPM.LPM_COMPONENTS.ALL;

-- 

ENTITY GCD_LCM IS
	PORT ( 
		CLOCK,
		RESETN	: IN STD_LOGIC;
	
		IO_ADDR	: IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		IO_DATA	: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		IO_WRITE	: IN STD_LOGIC;
		IO_READ	: IN STD_LOGIC
		);
END GCD_LCM;

ARCHITECTURE arch of GCD_LCM IS

	-- internal signals for holding register values
	SIGNAL MODE			: STD_LOGIC := '0';
	SIGNAL INPUT_1		: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL INPUT_2		: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL OUTPUT		: STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

	SIGNAL READ_DATA	: STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0'); -- intermediate signal to hold data during read operation
	
	-- signal for tri-state buffer
	sIGNAL IO_EN		: STD_LOGIC;

	BEGIN

	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => READ_DATA,
		enabledt => IO_EN,
		tridata  => IO_DATA
	);
	
	
	-- WRITE LOGIC
	PROCESS (CLOCK, RESETN)
	BEGIN 
		IF (RESETN = '0') THEN
			MODE <= '0';
			INPUT_1 <= (OTHERS => '0');
			INPUT_2 <= (OTHERS => '0');
		ELSIF (RISING_EDGE(CLOCK)) THEN
			IF (IO_WRITE = '1') THEN
				CASE IO_ADDR IS
					WHEN "00000000000" =>
						MODE <= IO_DATA(0); 
					WHEN "00000000001" =>
						INPUT_1 <= IO_DATA(7 DOWNTO 0);
						INPUT_2 <= IO_DATA(15 DOWNTO 8); 
					WHEN OTHERS => NULL;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	
	-- READ LOGIC
	WITH IO_ADDR SELECT
		READ_DATA	<=	(15 DOWNTO 1 => '0') & MODE	WHEN "00000000000",
							INPUT_2 & INPUT_1				WHEN "00000000001",
							OUTPUT							WHEN "00000000010",
							(OTHERS => 'X')				WHEN OTHERS;
	
	-- tri-state buffer
	IO_EN <=
		'1'	WHEN	(IO_READ = '1') AND
						(IO_ADDR = "00000000000" OR
						IO_ADDR = "00000000001" OR
						IO_ADDR = "00000000010")
				ELSE '0';
	
	
	
	-- GCD/LCM logic
    PROCESS(CLOCK, RESETN)
	 
	 VARIABLE a 		: unsigned(7 DOWNTO 0);
	 VARIABLE b 		: unsigned(7 DOWNTO 0);
	 VARIABLE gcd		: unsigned(7 DOWNTO 0);
	 VARIABLE lcm		: unsigned(15 DOWNTO 0);
	 
    BEGIN
        IF RESETN = '0' THEN
            OUTPUT <= (OTHERS => '0');
        ELSIF RISING_EDGE(CLOCK) THEN
				a := unsigned(INPUT_1);
				b := unsigned(INPUT_2);
				
				-- GCD algorithm --
				IF 	(a = 0) THEN gcd := b; -- edge cases
				ELSIF (b = 0) THEN gcd := a;
				
				ELSE
					WHILE (a /= b) LOOP
						IF (a > b) THEN
							a := a - b;
						ELSE 
							b := b - a;
						END IF;
					END LOOP;
					gcd:= a; -- a == b
				END IF;
				
				-- Select GCD/LCM --
				IF (MODE = '0') THEN -- GCD
					OUTPUT <= std_logic_vector(resize(gcd,16));
				ELSE -- LCM
					IF (gcd = 0) THEN lcm := (OTHERS => '0');
					ELSE lcm := (unsigned(INPUT_1) / gcd) * unsigned(INPUT_2);
					OUTPUT <= std_logic_vector(resize(lcm,16));
					END IF;
				END IF;
				
				
        END IF;
    END PROCESS;
END arch;

		