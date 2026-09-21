-- Este SP actualiza la meta mensual de la cantidad de visitas efectivas que
-- cada ruta debe hacer mensualmente, en base a la meta fija mensual de clientes
--y a los días operativos del mes de la meta
--Esta programado en un job para correr cada día ultimo del mes en curso

CREATE OR ALTER PROCEDURE PWST.SADS_ActualizarMetas
(
    @Mes_a_actualizar DATE
)

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mes_Meta DATE;
    DECLARE @Dias_Operativos INT;

    --floor date del mes
    
    SET @Mes_Meta = DATEFROMPARTS(
                        YEAR(@Mes_a_actualizar),
                        MONTH(@Mes_a_actualizar),
                        1
                    )

    -- Días hábiles
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

    DELETE
    FROM PWST.SADS_SegOper_Metas_Mensuales
    WHERE Mes = @Mes_Meta;

    DELETE M
    FROM PWST.SADS_SegOper_Metas M
    WHERE
        YEAR(M.Fecha) = YEAR(@Mes_Meta)
        AND MONTH(M.Fecha) = MONTH(@Mes_Meta)
        AND Indicador = 'VISITAS EFECTIVAS';

    -----------------------------------------------------
    -- Metas e indicadores mensuales
    -----------------------------------------------------

    INSERT INTO PWST.SADS_SegOper_Metas_Mensuales
    (
        Mes,
        NUR,
        CategoriaId,
        Indicador,
        Valor_Meta
    )
    SELECT
        @Mes_Meta,
        NUR,
        CategoriaId,
        Indicador,
        Valor_Objetivo
    FROM PWST.CATALOGOS_Objetivos_Fijos_Rutas;

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

        CASE
            WHEN O.Indicador = 'VISITAS EFECTIVAS'
                THEN ROUND(O.Valor_Objetivo / @Dias_Operativos, 3)
        
            ELSE
                O.Valor_Objetivo
        END

    FROM PWST.CATALOGOS_Objetivos_Fijos_Rutas O

    CROSS JOIN PWST.CATALOGOS_Calendario C

    WHERE
        C.Anio = YEAR(@Mes_Meta)
        AND C.Mes = MONTH(@Mes_Meta)
        AND C.Es_Habil = 1

        -- Categorías 3 y 4 son indicadores,
        -- no metas operativas diarias
        AND O.CategoriaId NOT IN (3,4);

END;
GO