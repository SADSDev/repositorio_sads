-- Este SP actualiza la meta mensual de la cantidad de visitas efectivas que
-- cada ruta debe hacer mensualmente, en base a la meta fija mensual de clientes
--y a los días operativos del mes de la meta
--Esta programado en un job para correr cada día ultimo del mes en curso

CREATE OR ALTER PROCEDURE SADS.ActualizarMetas
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Mes_Meta DATE;
    DECLARE @Dias_Operativos INT;

    -- Primer día del siguiente mes
    SET @Mes_Meta = DATEFROMPARTS
    (
        YEAR(DATEADD(MONTH,1,GETDATE())),
        MONTH(DATEADD(MONTH,1,GETDATE())),
        1
    );

    -- Días hábiles
    SELECT
        @Dias_Operativos = COUNT(*)
    FROM CATALOGOS.Calendario
    WHERE Anio = YEAR(@Mes_Meta)
      AND Mes = MONTH(@Mes_Meta)
      AND Es_Habil = 1;

    -----------------------------------------------------
    -- Limpiar metas existentes
    -----------------------------------------------------

    DELETE
    FROM SADS.SegOper_Metas_Mensuales
    WHERE Mes = @Mes_Meta;

    DELETE M
    FROM SADS.SegOper_Metas M
    WHERE YEAR(M.Fecha)=YEAR(@Mes_Meta)
      AND MONTH(M.Fecha)=MONTH(@Mes_Meta);

    -----------------------------------------------------
    -- Metas mensuales
    -----------------------------------------------------

    INSERT INTO SADS.SegOper_Metas_Mensuales
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
    FROM CATALOGOS.Objetivos_Fijos_Rutas;

    -----------------------------------------------------
    -- Metas diarias
    -----------------------------------------------------

    INSERT INTO SADS.SegOper_Metas
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
            WHEN O.Indicador='VISITAS EFECTIVAS'
                THEN ROUND(O.Valor_Objetivo/@Dias_Operativos,3)

            ELSE
                O.Valor_Objetivo
        END

    FROM CATALOGOS.Objetivos_Fijos_Rutas O

    CROSS JOIN CATALOGOS.Calendario C

    WHERE C.Anio = YEAR(@Mes_Meta)
      AND C.Mes = MONTH(@Mes_Meta)
      AND C.Es_Habil = 1;

END;
GO