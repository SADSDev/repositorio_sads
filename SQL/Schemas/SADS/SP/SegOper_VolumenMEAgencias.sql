CREATE OR ALTER PROCEDURE PWST.SADS_SegOper_VolumenMEAgencias
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

    SET @zona = NULLIF(LTRIM(RTRIM(@zona)), '');

    SET @ruta = NULLIF(LTRIM(RTRIM(@ruta)), '');

    DECLARE @AgruparPorGrupo BIT =
        CASE
            WHEN @agencia IS NOT NULL
                 AND CHARINDEX(',', @agencia) = 0
            THEN 1
            ELSE 0
        END;

    IF @frecuencia NOT IN (1, 2, 3)
    BEGIN
        THROW 50001, 'La frecuencia debe ser 1, 2 o 3.', 1;
    END;

    DECLARE @fecha_inicio DATE;
    DECLARE @fecha_fin DATE;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @columnas_meta NVARCHAR(MAX);
    DECLARE @columnas_avance NVARCHAR(MAX);
    DECLARE @columnas_objetivo NVARCHAR(MAX);
    DECLARE @columnas_alcance NVARCHAR(MAX);
    DECLARE @columnas NVARCHAR(MAX);

    SET @fecha_inicio =
        CASE @frecuencia
            WHEN 1 THEN @fecha

            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                            DAY,
                            -(DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        ) < DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
                    THEN DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)

                    ELSE DATEADD(
                            DAY,
                            -(DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        )
                END

            WHEN 3 THEN
                DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
        END;

    SET @fecha_fin =
        CASE @frecuencia
            WHEN 1 THEN @fecha

            WHEN 2 THEN
                CASE
                    WHEN DATEADD(
                            DAY,
                            6 - (DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        ) > EOMONTH(@fecha)
                    THEN EOMONTH(@fecha)

                    ELSE DATEADD(
                            DAY,
                            6 - (DATEDIFF(DAY, CONVERT(DATE, '19000101'), @fecha) % 7),
                            @fecha
                        )
                END

            WHEN 3 THEN
                EOMONTH(@fecha)
        END;

    /*
      Indicadores estratégicos disponibles en el mes consultado.
      Se excluye el indicador VOLUMEN.
    */
    SELECT DISTINCT
        LTRIM(RTRIM(M.Indicador)) AS Indicador
    INTO #Indicadores
    FROM PWST.SADS_SegOper_Metas M
    WHERE
        M.CategoriaId = 1
        AND UPPER(LTRIM(RTRIM(M.Indicador))) <> 'VOLUMEN'
        AND M.Fecha BETWEEN
            DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
            AND EOMONTH(@fecha);

    IF NOT EXISTS (SELECT 1 FROM #Indicadores)
    BEGIN
        SELECT
            CAST(NULL AS VARCHAR(20)) AS NUR,
            CAST(NULL AS VARCHAR(100)) AS CLO
        WHERE 1 = 0;

        RETURN;
    END;

    /*
      Construcción dinámica de las columnas.

      Se usa QUOTENAME para que indicadores como:
      ICE MIX
      BARONET
      MARCA A + MARCA B 
      sean nombres válidos de columnas.
    */
    SELECT
        @columnas_meta =
            STRING_AGG(
                CONVERT(
                    NVARCHAR(MAX),
                    'CAST(CEILING(SUM(CASE
                        WHEN D.Indicador = N''' +
                    REPLACE(I.Indicador, '''', '''''') +
                    '''
                        THEN D.MetaPeriodo
                        ELSE 0
                    END)) AS INT) AS ' +
                    QUOTENAME('Meta ' + I.Indicador)
                ),
                ','
            ),

        @columnas_avance =
            STRING_AGG(
                CONVERT(
                    NVARCHAR(MAX),
                    'CAST(SUM(CASE
                        WHEN D.Indicador = N''' +
                    REPLACE(I.Indicador, '''', '''''') +
                    '''
                        THEN D.Avance
                        ELSE 0
                    END) AS DECIMAL(18,3)) AS ' +
                    QUOTENAME('Avance ' + I.Indicador)
                ),
                ','
            ),

        @columnas_objetivo =
            STRING_AGG(
                CONVERT(
                    NVARCHAR(MAX),
                    'CAST(CEILING(SUM(CASE
                        WHEN D.Indicador = N''' +
                    REPLACE(I.Indicador, '''', '''''') +
                    '''
                        THEN D.ObjAlDia
                        ELSE 0
                    END)) AS INT) AS ' +
                    QUOTENAME('ObjAlDia ' + I.Indicador)
                ),
                ','
            ),

        @columnas_alcance =
            STRING_AGG(
                CONVERT(
                    NVARCHAR(MAX),
                    'CAST(
                        ROUND(
                            SUM(CASE
                                WHEN D.Indicador = N''' +
                    REPLACE(I.Indicador, '''', '''''') +
                    '''
                                THEN D.Avance
                                ELSE 0
                            END)
                            /
                            NULLIF(
                                SUM(CASE
                                    WHEN D.Indicador = N''' +
                    REPLACE(I.Indicador, '''', '''''') +
                    '''
                                    THEN D.MetaPeriodo
                                    ELSE 0
                                END),
                                0
                            ),
                            4
                        )
                        AS DECIMAL(10,4)
                    ) AS ' +
                    QUOTENAME('Alcance ' + I.Indicador)
                ),
                ','
            )
    FROM #Indicadores I;

    SET @columnas =
        @columnas_meta + ',' +
        @columnas_avance + ',' +
        @columnas_objetivo + ',' +
        @columnas_alcance;

    SET @sql = N'
    ;WITH Rutas AS
    (
        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona,
            CASE
                WHEN @AgruparPorGrupo = 1 THEN V.Grupo
                ELSE A.CLO
            END AS Agrupador
        FROM PWST.CATALOGOS_Rutas_Evaluables V
        INNER JOIN PWST.CATALOGOS_Agencias A
            ON V.NUR LIKE A.Clave_NUR + ''%''
        WHERE
            V.NUR <> ''1125632M29''
            AND (
                @agencia IS NULL
                OR CHARINDEX(
                    '','' + CONVERT(VARCHAR(10), A.Agencia) + '','',
                    '','' + @agencia + '',''
                ) > 0
            )
            AND (@zona IS NULL OR EXISTS (SELECT 1 FROM STRING_SPLIT(@zona, CHAR(44)) Z WHERE LTRIM(RTRIM(Z.value)) = V.Grupo))
            AND
            (
                @ruta IS NULL
                OR CONCAT(
                    ''R'',
                    SUBSTRING(
                        V.NUR,
                        PATINDEX(''%[A-Z]%'', V.NUR) + 1,
                        LEN(V.NUR)
                    )
                ) IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@ruta, CHAR(44)))
            )
    ),

    Metas AS
    (
        SELECT
            M.NUR,
            LTRIM(RTRIM(M.Indicador)) AS Indicador,

            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @fecha_inicio AND @fecha_fin
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS MetaPeriodo,

            SUM(
                CASE
                    WHEN M.Fecha BETWEEN @fecha_inicio AND @fecha
                    THEN M.Valor_Meta
                    ELSE 0
                END
            ) AS ObjAlDia

        FROM PWST.SADS_SegOper_Metas M
        INNER JOIN Rutas R
            ON R.NUR = M.NUR
        INNER JOIN #Indicadores I
            ON I.Indicador = LTRIM(RTRIM(M.Indicador))
        WHERE
            M.CategoriaId = 1
            AND M.Fecha BETWEEN @fecha_inicio AND @fecha_fin
        GROUP BY
            M.NUR,
            LTRIM(RTRIM(M.Indicador))
    ),

    Ventas AS
    (
        SELECT
            M.NUR,
            LTRIM(RTRIM(M.Indicador)) AS Indicador,
            SUM(VD.Cantidad) AS Avance
        FROM Metas M
        INNER JOIN PWST.POWERSTREET_Venta_Diaria VD
            ON VD.NUR = M.NUR
        INNER JOIN PWST.CATALOGOS_Articulos A
            ON A.Codigo = VD.Codigo_Articulo
        WHERE
            VD.Fecha BETWEEN @fecha_inicio AND @fecha
            AND EXISTS
            (
                SELECT 1
                FROM STRING_SPLIT(M.Indicador, ''+'') S
                WHERE LTRIM(RTRIM(S.value)) = LTRIM(RTRIM(A.Familia))
            )
        GROUP BY
            M.NUR,
            LTRIM(RTRIM(M.Indicador))
    ),

    RutasConMeta AS
    (
        SELECT DISTINCT
            M.NUR,
            R.Agrupador
        FROM Metas M
        INNER JOIN Rutas R
            ON R.NUR = M.NUR
    ),

    Datos AS
    (
        SELECT
            R.NUR,
            R.Agrupador,
            I.Indicador,
            CAST(CEILING(COALESCE(M.MetaPeriodo, 0)) AS INT) AS MetaPeriodo,
            CAST(COALESCE(V.Avance, 0) AS DECIMAL(18,3)) AS Avance,
            CAST(CEILING(COALESCE(M.ObjAlDia, 0)) AS INT) AS ObjAlDia
        FROM RutasConMeta R
        CROSS JOIN #Indicadores I
        LEFT JOIN Metas M
            ON M.NUR = R.NUR
            AND M.Indicador = I.Indicador
        LEFT JOIN Ventas V
            ON V.NUR = R.NUR
            AND V.Indicador = I.Indicador
    )

    SELECT
        Agrupador AS CLO,
        ' + @columnas + N'
    FROM Datos D
    GROUP BY
        Agrupador
    ORDER BY
        Agrupador;
    ';
    EXEC sys.sp_executesql
        @sql,
        N'@fecha DATE,
          @fecha_inicio DATE,
          @fecha_fin DATE,
          @agencia VARCHAR(200),
          @AgruparPorGrupo BIT,
          @zona VARCHAR(200),
          @ruta VARCHAR(200)',
        @fecha = @fecha,
        @fecha_inicio = @fecha_inicio,
        @fecha_fin = @fecha_fin,
        @agencia = @agencia,
        @AgruparPorGrupo = @AgruparPorGrupo,
        @zona = @zona,
        @ruta = @ruta;
END;
GO
