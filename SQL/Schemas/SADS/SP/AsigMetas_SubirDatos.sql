CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_SubirDatos
(   
    @anio INT,
    @mes INT,
    @agencia INT,
    @MetasAgencia [PWST].[AsigMetasAgenciaInstancia] READONLY,
    @MetasRuta [PWST].[AsigMetasRutaInstancia] READONLY
) 
AS      
BEGIN 

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MesFecha DATE;

    SET @MesFecha = DATEADD(
        MONTH,
        @mes - 1,
        DATEADD(YEAR, @anio - 1900, 0)
    );

    -- Metas globales recibidas en el TVP.
    SELECT
        Agencia,
        @MesFecha AS Mes,
        1 AS CategoriaId,
        Indicador,
        Valor_Meta
    INTO #MetasAgencia
    FROM @MetasAgencia
    WHERE Agencia = @agencia;


    -- Metas diarias por NUR y marca, recibidas en el TVP.
    SELECT
        NUR,
        Fecha,
        1 AS CategoriaId,
        Indicador,
        Valor_Meta
    INTO #MetasDiarias
    FROM @MetasRuta;


    BEGIN TRY
        BEGIN TRANSACTION;

        -- DELETES PREVIOS
        DELETE FROM PWST.SADS_SegOper_MetasAgencia
        WHERE YEAR(Mes) = @anio
          AND MONTH(Mes) = @mes
          AND Agencia = @agencia
          AND CategoriaId = 1;

        DELETE M
        FROM PWST.SADS_SegOper_Metas M
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON M.NUR LIKE A.Clave_NUR + '%'
        WHERE YEAR(M.Fecha) = @anio
          AND MONTH(M.Fecha) = @mes
          AND A.Agencia = @agencia
          AND CategoriaId = 1;

        -- INSERCIONES DE DATOS
        INSERT INTO PWST.SADS_SegOper_Metas
        (
            Fecha,
            NUR,
            CategoriaId,
            Indicador,
            Valor_Meta
        )
        SELECT
            Fecha,
            NUR,
            CategoriaId,
            Indicador,
            Valor_Meta
        FROM #MetasDiarias;

        INSERT INTO PWST.SADS_SegOper_MetasAgencia
        (
            Mes,
            Agencia,
            CategoriaId,
            Indicador,
            Valor_Meta
        )
        SELECT
            Mes,
            Agencia,
            CategoriaId,
            Indicador,
            Valor_Meta
        FROM #MetasAgencia;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMensaje NVARCHAR(4000);
        DECLARE @ErrorSeveridad INT;
        DECLARE @ErrorEstado INT;

        SELECT
            @ErrorMensaje = ERROR_MESSAGE(),
            @ErrorSeveridad = ERROR_SEVERITY(),
            @ErrorEstado = ERROR_STATE();

        RAISERROR(@ErrorMensaje, @ErrorSeveridad, @ErrorEstado);
    END CATCH;

END;
GO              
