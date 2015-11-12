library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity adder is
    generic ( operand_width_g : integer );

    port
    (
        clk : in std_logic; 
        rst_n : in std_logic; 
        a_in : in std_logic_vector(operand_width_g - 1 DOWNTO 0);
        b_in : in std_logic_vector(operand_width_g - 1 DOWNTO 0);
        sum_out : out std_logic_vector(operand_width_g DOWNTO 0)
    );
end adder;

architecture rtl of adder is
    signal result : signed(operand_width_g DOWNTO 0);
begin
    sum_out <= std_logic_vector(result);

    calculate : process(clk, rst_n, a_in, b_in)
    begin
        if (rst_n = '1') then
            if (clk'EVENT AND clk='1') then
                result <= resize(signed(a_in), operand_width_g + 1) +
                          resize(signed(b_in), operand_width_g + 1);
            else
                result <= result;
            end if;
        else
            result <= (others => '0');
        end if;
    end process calculate;

end rtl;
