CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_TablaVolumenResumen
(
    @fecha DATE,
    @agencia VARCHAR(200) = NULL,
    @zona VARCHAR(200) = NULL,
    @ruta VARCHAR(200) = NULL,
    @frecuencia INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @agencia = NULLIF(
        REPLACE(LTRIM(RTRIM(@agencia)), ' ', ''),
        ''
    );

    SET @zona = NULLIF(
        LTRIM(RTRIM(@zona)),
        ''
    );

    SET @ruta = NULLIF(
        LTRIM(RTRIM(@ruta)),
        ''
    );

    IF @frecuencia NOT IN (1, 2, 3)
    BEGIN
        THROW 50001,
            'La frecuencia debe ser 1, 2 o 3.',
            1;
    END;

    /*
        Esta tabla recibe exactamente el resultado de
        SegOper_VolumenAgencias.
    */
    CREATE TABLE #DetalleVolumen
    (
        CLO VARCHAR(100) NULL,
        MetaVolumen DECIMAL(18,3) NULL,
        ObjAlDia DECIMAL(18,3) NULL,
        AvanceCLO DECIMAL(18,3) NULL,
        InyeccionGTP DECIMAL(18,3) NULL,
        InyeccionMM DECIMAL(18,3) NULL
    );

    --Se ejecuta la lógica oficial de volumen por agencia/sector/CLO.
    INSERT INTO #DetalleVolumen
    (
        CLO,
        MetaVolumen,
        ObjAlDia,
        AvanceCLO,
        InyeccionGTP,
        InyeccionMM
    )
    EXEC PWST.SADS_SegOper_VolumenAgencias
        @fecha = @fecha,
        @agencia = @agencia,
        @zona = @zona,
        @ruta = @ruta,
        @frecuencia = @frecuencia;

    SELECT
        CAST(
            COALESCE(SUM(CASE
                WHEN CLO <> 'MAYOREO' THEN MetaVolumen
                ELSE 0
            END), 0)
            AS INT
        ) AS MetaVolumen,

        CAST(
            COALESCE(SUM(CASE
                WHEN CLO <> 'MAYOREO' THEN AvanceCLO
                ELSE 0
            END), 0)
            AS DECIMAL(18,3)
        ) AS AvanceRuta,

        CAST(
            COALESCE(SUM(ObjAlDia), 0)
            AS INT
        ) AS ObjAlDia,

        CAST(
            COALESCE(SUM(InyeccionGTP), 0)
            AS DECIMAL(18,3)
        ) AS ExcedenteGTP,

        CAST(
            COALESCE(SUM(InyeccionMM), 0)
            AS DECIMAL(18,3)
        ) AS ExcedenteMM
    FROM #DetalleVolumen;

    DROP TABLE #DetalleVolumen;

END;
GO