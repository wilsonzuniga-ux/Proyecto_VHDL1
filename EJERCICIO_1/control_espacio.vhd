library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Control del tiempo de una persona en un espacio
entity control_espacio is
    Port (
        reloj_50mhz      : in  STD_LOGIC;
        reiniciar        : in  STD_LOGIC;
        persona_presente : in  STD_LOGIC;
        alarma_led       : out STD_LOGIC;
        felicitacion_led : out STD_LOGIC;
        display_decenas  : out STD_LOGIC_VECTOR(6 downto 0);
        display_unidades : out STD_LOGIC_VECTOR(6 downto 0)
    );
end control_espacio;

architecture Comportamiento of control_espacio is

    -- Estados que puede tener el sistema
    type estado_tipo is (LIBRE, CONTEO_35S, ALARMA_EXCESO, FELICITACION);
    signal estado_actual, estado_siguiente : estado_tipo;

    -- Contador del reloj y tiempo en segundos
    signal cnt_50mhz : integer range 0 to 49_999_999 := 0;
    signal pulso_1s  : STD_LOGIC := '0';
    signal seg       : integer range 0 to 99 := 0;

    signal dec : integer range 0 to 9 := 0;
    signal uni : integer range 0 to 9 := 0;

    -- Convierte el número para mostrarlo en el display
    function decodificar_7seg(digito : integer) return STD_LOGIC_VECTOR is
    begin
        case digito is
            when 0 => return "1000000";
            when 1 => return "1111001";
            when 2 => return "0100100";
            when 3 => return "0110000";
            when 4 => return "0011001";
            when 5 => return "0010010";
            when 6 => return "0000010";
            when 7 => return "1111100";
            when 8 => return "0000000";
            when 9 => return "0010000";
            when others => return "1111111";
        end case;
    end function;

begin

    -- Se cuentan los ciclos del reloj para obtener 1 segundo
    process(reloj_50mhz, reiniciar)
    begin
        if reiniciar = '1' then
            cnt_50mhz <= 0;
            pulso_1s <= '0';

        elsif rising_edge(reloj_50mhz) then
            if cnt_50mhz = 49_999_999 then
                cnt_50mhz <= 0;
                pulso_1s <= '1';
            else
                cnt_50mhz <= cnt_50mhz + 1;
                pulso_1s <= '0';
            end if;
        end if;
    end process;

    -- Aquí se actualiza el tiempo y el estado
    process(reloj_50mhz, reiniciar)
    begin
        if reiniciar = '1' then
            estado_actual <= LIBRE;
            seg <= 0;

        elsif rising_edge(reloj_50mhz) then
            if pulso_1s = '1' then
                estado_actual <= estado_siguiente;

                if estado_actual = CONTEO_35S or estado_actual = ALARMA_EXCESO then
                    if persona_presente = '1' then
                        seg <= seg + 1;
                    end if;
                else
                    seg <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Lógica para decidir a qué estado pasar
    process(estado_actual, persona_presente, seg)
    begin
        alarma_led <= '0';
        felicitacion_led <= '0';

        case estado_actual is

            when LIBRE =>
                if persona_presente = '1' then
                    estado_siguiente <= CONTEO_35S;
                else
                    estado_siguiente <= LIBRE;
                end if;

            when CONTEO_35S =>
                if persona_presente = '0' then
                    estado_siguiente <= FELICITACION;
                elsif seg >= 35 then
                    estado_siguiente <= ALARMA_EXCESO;
                else
                    estado_siguiente <= CONTEO_35S;
                end if;

            when ALARMA_EXCESO =>
                alarma_led <= '1';

                if persona_presente = '0' then
                    estado_siguiente <= LIBRE;
                else
                    estado_siguiente <= ALARMA_EXCESO;
                end if;

            when FELICITACION =>
                felicitacion_led <= '1';

                if persona_presente = '0' then
                    estado_siguiente <= LIBRE;
                else
                    estado_siguiente <= CONTEO_35S;
                end if;

        end case;
    end process;

    -- Se separan las decenas y las unidades
    dec <= seg / 10;
    uni <= seg rem 10;

    display_decenas  <= decodificar_7seg(dec);
    display_unidades <= decodificar_7seg(uni);

end Comportamiento;