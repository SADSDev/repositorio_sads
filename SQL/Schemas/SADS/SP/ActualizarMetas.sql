-- Este SP actualiza la meta mensual de la cantidad de visitas efectivas que
-- cada ruta debe hacer mensualmente, en base a la meta fija mensual de clientes
--y a los días operativos del mes de la meta
--Esta programado en un job para correr cada día ultimo del mes en curso
CREATE OR ALTER PROCEDURE PWST.SADS_ActualizarMetasVisitas
(
    @Mes_a_actualizar DATE
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mes_Meta DATE;
    DECLARE @Dias_Operativos INT;

    SET @Mes_Meta = DATEFROMPARTS(
                        YEAR(@Mes_a_actualizar),
                        MONTH(@Mes_a_actualizar),
                        1
                    );

    SELECT
        @Dias_Operativos = COUNT(*)
    FROM PWST.CATALOGOS_Calendario
    WHERE
        Anio = YEAR(@Mes_Meta)
        AND Mes = MONTH(@Mes_Meta)
        AND Es_Habil = 1;

    -----------------------------------------------------
    -- Limpiar metas existentes
    -----------------------------------------------------

    DELETE M
    FROM PWST.SADS_SegOper_Metas M
    WHERE
        YEAR(M.Fecha) = YEAR(@Mes_Meta)
        AND MONTH(M.Fecha) = MONTH(@Mes_Meta)
        AND M.Indicador = 'VISITAS EFECTIVAS';

    -----------------------------------------------------
    -- Metas diarias
    -----------------------------------------------------

    INSERT INTO PWST.SADS_SegOper_Metas
    (
        Fecha,
        NUR,
        CategoriaId,
        Indicador,
        Valor_Meta
    )
    SELECT
        C.Fecha,
        O.NUR,
        O.CategoriaId,
        O.Indicador,
        ROUND(O.Valor_Meta / @Dias_Operativos, 3)
    FROM PWST.SADS_SegOper_Metas_Mensuales O
    
    WHERE
        C.Anio = YEAR(@Mes_Meta)
        AND C.Mes = MONTH(@Mes_Meta)
        AND C.Es_Habil = 1
        AND O.Mes = @Mes_Meta
        AND O.Indicador = 'VISITAS EFECTIVAS';


END;
GO