CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_SubirDatos
(   
    @anio INT,
    @mes INT,
    @agencia INT,
    @datos VARCHAR(MAX)
) 
AS      
BEGIN 

    SET NOCOUNT ON;
    
    -- Metas globales
    SELECT
        Agencia,
        DATEFROMPARTS(@anio, @mes, 1) AS Mes,
        1 AS CategoriaId,
        Indicador,
        Valor_Meta
    INTO #MetasAgencia
    FROM OPENJSON(@datos)
    WITH
    (
        Agencia INT '$.Agencia',
        MetaGT  DECIMAL(18,4) '$.MetasAgencia.MetaGT', 
        MetaGTP DECIMAL(18,4) '$.MetasAgencia.MetaGTP',
        MetaMM DECIMAL(18,4) '$.MetasAgencia.MetaMM'
    ) A
    CROSS APPLY
    (
        VALUES
            ('VOLUMEN', A.MetaGT),
            ('VOLUMEN GTP', A.MetaGTP),
            ('VOLUMEN MM', A.MetaMM)
    ) V(Indicador, Valor_Meta);


    -- METAS DIARIAS
    SELECT
        R.NUR,
        M.Fecha,
        1 AS CategoriaId,
        'VOLUMEN' AS Indicador,
        M.Meta AS Valor_Meta
    INTO #MetasDiarias
    FROM OPENJSON(@Datos, '$.Rutas')
    WITH
    (
        NUR VARCHAR(50) '$.NUR',
        MetaVolumen NVARCHAR(MAX) '$.MetaVolumen' AS JSON
    ) R
    CROSS APPLY OPENJSON(R.MetaVolumen)
    WITH
    (
        Fecha DATE '$.Fecha',
        Meta DECIMAL(18,4) '$.Meta'
    ) M

    UNION ALL

    SELECT
        R.NUR,
        M.Fecha,
        1 AS CategoriaId,
        B.Marca AS Indicador,
        M.Meta AS Valor_Meta
    FROM OPENJSON(@Datos, '$.Rutas')
    WITH
    (
        NUR VARCHAR(50) '$.NUR',
        MetasMarca NVARCHAR(MAX) '$.MetasMarca' AS JSON
    ) R

    CROSS APPLY OPENJSON(R.MetasMarca)
    WITH
    (
        Marca VARCHAR(300) '$.Marca',
        MetaDiaria NVARCHAR(MAX) '$.MetaDiaria' AS JSON
    ) B

    CROSS APPLY OPENJSON(B.MetaDiaria)
    WITH
    (
        Fecha DATE '$.Fecha',
        Meta DECIMAL(18,4) '$.Meta'
    ) M;


    -- DELETES PREVIOS
    DELETE FROM PWST.SADS_SegOper_MetasAgencia
    WHERE YEAR(Mes) = @anio
      AND MONTH(Mes) = @mes
      AND Agencia = @agencia
      AND CategoriaId=1;


    DELETE M
    FROM PWST.SADS_SegOper_Metas M
    INNER JOIN PWST.CATALOGOS_Agencias A
        ON M.NUR LIKE A.Clave_NUR + '%'
    WHERE YEAR(M.Fecha) = @anio
      AND MONTH(M.Fecha) = @mes
      AND A.Agencia = @agencia
      AND CategoriaId=1;


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

END;
GO              
