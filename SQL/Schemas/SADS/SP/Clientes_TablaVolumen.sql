  
CREATE OR ALTER PROCEDURE [PWST].[Clientes_TablaVolumen]  
    @Cliente VARCHAR(300),  
    @Inicio INT,  
    @Fin INT,  
    @Ainicio INT,  
    @Afin INT,  
    @FamiliasSeleccionadas VARCHAR(MAX) = NULL  
AS  
BEGIN  
  
    SET NOCOUNT ON;  
  
    --Tabla de familias  
    DECLARE @Familias TABLE ( Familia VARCHAR(100), Orden INT)  
  
    --Si no se seleccionaron las familias, mostrara el listado por default  
    IF NULLIF(LTRIM(RTRIM(@FamiliasSeleccionadas)), '') IS NULL  
    BEGIN  
        INSERT INTO @Familias ( Familia, Orden ) VALUES   
        ('MARLBORO RED', 1), ('ICE MIX', 2), ('BLOSSOM MIX', 3), ('SUMMER MIX', 4), ('RUBY MIX', 5), ('CRAFTED RED', 6), ('BARONET', 7)  
  
    END  
    ELSE  
    BEGIN  
  
        --Obtencion del listado de familias desde el front  
        DECLARE @FrontFamilias VARCHAR(MAX)  
        DECLARE @FamiliaActual VARCHAR(100)  
        DECLARE @Posicion INT  
        DECLARE @Orden INT  
  
  
        SET @FrontFamilias = LTRIM(RTRIM(@FamiliasSeleccionadas))  
        SET @FrontFamilias = @FrontFamilias + ','  
        SET @Orden = 1  
  
        WHILE LEN(@FrontFamilias) > 0  
        BEGIN  
  
            SET @Posicion = CHARINDEX(',', @FrontFamilias)  
  
            IF @Posicion = 0 BREAK  
  
            SET @FamiliaActual = LTRIM(RTRIM(LEFT(@FrontFamilias, @Posicion - 1)))  
  
            IF LEN(@FamiliaActual) > 0  
            BEGIN  
                INSERT INTO @Familias(Familia, Orden) VALUES (@FamiliaActual, @Orden)  
                SET @Orden = @Orden + 1  
            END  
            SET @FrontFamilias = SUBSTRING(@FrontFamilias, @Posicion + 1, LEN(@FrontFamilias))  
        END  
    END  
  
    --Si no se encuentra datos para las familias desde el front, guardar las default  
    IF NOT EXISTS (SELECT 1 FROM @Familias)  
    BEGIN  
        INSERT INTO @Familias (Familia, Orden)  
        VALUES ('MARLBORO RED', 1), ('ICE MIX', 2), ('BLOSSOM MIX', 3), ('SUMMER MIX', 4), ('RUBY MIX', 5), ('CRAFTED RED', 6), ('BARONET', 7)  
    END  
  
    --Declareacion de las semanas  
    CREATE TABLE #Semanas (Semana INT)  
  
    DECLARE @Semana INT = @Inicio  
  
    WHILE @Semana <= @Fin  
    BEGIN  
        INSERT INTO #Semanas (Semana) VALUES (@Semana)  
        SET @Semana = @Semana + 1  
    END  
  
    --Consulta SQL dinamica en base a las familias  
    DECLARE @Columnas NVARCHAR(MAX)  
    DECLARE @ColumnasSelect NVARCHAR(MAX)  
    DECLARE @ColumnasBase NVARCHAR(MAX)  
    DECLARE @ColumnasTotal NVARCHAR(MAX)  
    DECLARE @ListaFamilias NVARCHAR(MAX)  
  
    SET @Columnas = ''  
    SET @ColumnasSelect = ''  
    SET @ColumnasBase = ''  
    SET @ColumnasTotal = ''  
    SET @ListaFamilias = ''  
  
    DECLARE @Familia VARCHAR(100);  
  
    --Cursor familas y datos de variables  
    DECLARE CursorFamilias CURSOR LOCAL FAST_FORWARD  
    FOR  
        SELECT Familia FROM @Familias ORDER BY Orden  
  
    OPEN CursorFamilias  
  
    FETCH NEXT FROM CursorFamilias  
    INTO @Familia  
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
  
        SET @Columnas = @Columnas + CASE WHEN @Columnas = '' THEN '' ELSE ',' END + QUOTENAME(@Familia)  
        SET @ColumnasSelect = @ColumnasSelect + CASE WHEN @ColumnasSelect = '' THEN '' ELSE ',' END + QUOTENAME(@Familia) + ' AS ' + QUOTENAME(@Familia)  
        SET @ColumnasBase = @ColumnasBase + CASE WHEN @ColumnasBase = '' THEN '' ELSE ',' END + 'P.' + QUOTENAME(@Familia) + ' AS ' + QUOTENAME(@Familia)  
        SET @ColumnasTotal = @ColumnasTotal + CASE WHEN @ColumnasTotal = '' THEN '' ELSE ',' END +  'ROUND(SUM(' + QUOTENAME(@Familia) + '), 1) AS ' + QUOTENAME(@Familia)  
        SET @ListaFamilias = @ListaFamilias + CASE WHEN @ListaFamilias = '' THEN '' ELSE ',' END + '''' + REPLACE(@Familia, '''', '''''') + ''''  
  
        FETCH NEXT FROM CursorFamilias  
        INTO @Familia  
    END  
  
    CLOSE CursorFamilias  
    DEALLOCATE CursorFamilias  
  
    DECLARE @SQL NVARCHAR(MAX)  
  
    SET @SQL = N'  
  
    SELECT
        DATEPART(ISO_WEEK, VD.Fecha) AS SemanaISO,
        A.Familia,
        CAST(ROUND(SUM(VD.Cantidad), 1) AS DECIMAL(18,1)) AS Cantidad
    INTO #Datos
    FROM PWST.POWERSTREET_Venta_Diaria VD
    INNER JOIN PWST.CATALOGOS_Articulos A
        ON VD.Codigo_Articulo = A.Codigo
    WHERE VD.Cliente = @Cliente
    AND DATEPART(ISO_WEEK, VD.Fecha) BETWEEN @Inicio AND @Fin
    AND A.Familia IN (' + @ListaFamilias + ')
    AND YEAR(VD.Fecha) BETWEEN @AInicio AND @AFin
    GROUP BY
        DATEPART(ISO_WEEK, VD.Fecha),
        A.Familia
  
    /* =========================  
       PIVOT  
    ========================= */  
    SELECT SemanaISO, ' + @ColumnasSelect + ' INTO #Pivot  
    FROM (SELECT SemanaISO, Familia, Cantidad FROM #Datos) D  
    PIVOT ( SUM(Cantidad) FOR Familia IN (' + @Columnas + ') ) P  
  
    /* =========================  
       Unión con todas las semanas  
    ========================= */  
    SELECT S.Semana, ' + @ColumnasBase + ' INTO #Resultado  
    FROM #Semanas S   
    LEFT JOIN #Pivot P ON S.Semana = P.SemanaISO  
  
    /* =========================  
       Resultado final + TOTAL  
    ========================= */  
    SELECT CASE WHEN GROUPING(Semana) = 1 THEN ''TOTAL'' ELSE CAST(Semana AS VARCHAR(20)) END AS Sem, ' + @ColumnasTotal + '  
    FROM #Resultado  
    GROUP BY ROLLUP(Semana)  
    ORDER BY GROUPING(Semana), Semana  
  
  
    --Borrado de tablas temporales  
    DROP TABLE #Datos  
    DROP TABLE #Pivot  
    DROP TABLE #Resultado  
      
    '  
  
    EXEC sp_executesql  
        @SQL,  
        N'@Cliente VARCHAR(300),  
          @Inicio INT,  
          @Fin INT,  
          @AInicio INT,  
          @AFin INT',  
  
        @Cliente = @Cliente,  
        @Inicio = @Inicio,  
        @Fin = @Fin,  
        @AInicio = @Ainicio,  
        @AFin = @Afin  
  
    DROP TABLE #Semanas  
  
END  