CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_ConsultaMetas  
(  
    @mes INT,  
    @anio INT,  
    @agencia INT  
)  
AS  
BEGIN  
  
    SET NOCOUNT ON; 

    -- Obtencion de metas con indicadorId=1
    DECLARE @columnas NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX); 

    SELECT @columnas =
        STRING_AGG(
            'CAST(ROUND(SUM(CASE WHEN M.Indicador = ''' 
            + REPLACE(M.Indicador, '''', '''''') 
            + ''' THEN M.Valor_Meta ELSE 0 END), 0) AS INT) AS ' 
            + QUOTENAME(
                CASE 
                    WHEN M.Indicador = 'VOLUMEN' THEN 'meta_vol'
                    ELSE M.Indicador
                END
            ),
            ', '
        )
    FROM
    (
        SELECT DISTINCT
            M.Indicador
        FROM PWST.SADS_SegOper_Metas AS M  
        INNER JOIN PWST.CATALOGOS_Agencias AS A  
            ON M.NUR LIKE '%' + A.Clave_NUR + '%'  
        WHERE  
            M.Fecha BETWEEN DATEFROMPARTS(@anio, @mes, 1)  
                        AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))  
            AND A.Agencia = @agencia  
            AND M.CategoriaId = 1
    ) M;

    SET @SQL = '
    SELECT
        M.NUR,
        ' + @Columnas + '
    FROM PWST.SADS_SegOper_Metas AS M
    INNER JOIN PWST.CATALOGOS_Agencias AS A
        ON M.NUR LIKE ''%'' + A.Clave_NUR + ''%''
    WHERE
        M.Fecha BETWEEN DATEFROMPARTS(' + CAST(@anio AS VARCHAR(4)) + ',' + CAST(@mes AS VARCHAR(2)) + ',1)
                    AND EOMONTH(DATEFROMPARTS(' + CAST(@anio AS VARCHAR(4)) + ',' + CAST(@mes AS VARCHAR(2)) + ',1))
        AND A.Agencia = ' + CAST(@agencia AS VARCHAR(10)) + '
        AND M.CategoriaId = 1
    GROUP BY
        M.NUR
    ORDER BY
        M.NUR;
    ';

    EXEC sp_executesql @SQL;

END;