  
CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaDistribucion]  
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
    DECLARE @Familias TABLE (Familia VARCHAR(100), Orden INT)  
  
    --Si no se seleccionaron las familias, mostrara el listado por default  
    IF NULLIF(LTRIM(RTRIM(@FamiliasSeleccionadas)), '') IS NULL  
    BEGIN  
        INSERT INTO @Familias (Familia, Orden) VALUES  
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
                INSERT INTO @Familias (Familia, Orden) VALUES (@FamiliaActual, @Orden)  
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
  
    --Consulta SQL dinamica en base a las familias  
    DECLARE @Columnas NVARCHAR(MAX)  
    DECLARE @ColumnasCreate NVARCHAR(MAX)  
    DECLARE @ColumnasFlag NVARCHAR(MAX)  
    DECLARE @ColumnasFinal NVARCHAR(MAX)  
    DECLARE @ListaFamilias NVARCHAR(MAX)  
  
    SET @Columnas = ''  
    SET @ColumnasCreate = ''  
    SET @ColumnasFlag = ''  
    SET @ColumnasFinal = ''  
    SET @ListaFamilias = ''  
  
    DECLARE @Familia VARCHAR(100);  
  
    --Cursor familias y datos de variables  
    DECLARE CursorFamilias CURSOR LOCAL FAST_FORWARD  
    FOR  
        SELECT Familia FROM @Familias ORDER BY Orden  
  
    OPEN CursorFamilias  
  
    FETCH NEXT FROM CursorFamilias  
    INTO @Familia  
  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
  
        SET @Columnas = @Columnas + CASE WHEN @Columnas = '' THEN '' ELSE ',' END + QUOTENAME(@Familia)  
        SET @ColumnasCreate = @ColumnasCreate + CASE WHEN @ColumnasCreate = '' THEN '' ELSE ',' END + QUOTENAME(@Familia) + ' INT'  
        SET @ColumnasFlag = @ColumnasFlag + CASE WHEN @ColumnasFlag = '' THEN '' ELSE ',' END + 'IIF(' + QUOTENAME(@Familia) + ' > 0, 1, 0) AS ' + QUOTENAME(@Familia)  
        SET @ColumnasFinal = @ColumnasFinal + CASE WHEN @ColumnasFinal = '' THEN '' ELSE ',' END + 'ISNULL(P.' + QUOTENAME(@Familia) + ', 0) AS ' + QUOTENAME(@Familia)  
        SET @ListaFamilias = @ListaFamilias + CASE WHEN @ListaFamilias = '' THEN '' ELSE ',' END + '''' + REPLACE(@Familia, '''', '''''') + ''''  
  
        FETCH NEXT FROM CursorFamilias  
        INTO @Familia  
    END  
  
    CLOSE CursorFamilias  
    DEALLOCATE CursorFamilias  
  
    DECLARE @SQL NVARCHAR(MAX)  
  
    SET @SQL = N'  
  
    CREATE TABLE #Datos (' + @ColumnasCreate + ')  
  
    INSERT INTO #Datos  
    SELECT ' + @ColumnasFlag + '  
    FROM  
    (  
        SELECT  
            A.Familia, 
            SUM(V.Cantidad) AS Cantidad  
        FROM    [PWST].[POWERSTREET_Venta_Diaria] V
        LEFT JOIN [PWST].[CATALOGOS_Articulos] A
            ON V.Codigo_Articulo=A.Codigo  
        WHERE   1 = 1  
        AND     Cliente = @Cliente  
        AND     Familia IN (' + @ListaFamilias + ')  
        AND Fecha >= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
        AND Fecha <= EOMONTH(GETDATE()) 
        GROUP BY Familia  
    ) AS Datos  
    PIVOT  
    (  
        SUM(Cantidad)  
        FOR Familia IN (' + @Columnas + ')  
    ) AS pvt;  
  
    SELECT ' + REPLACE(@ColumnasFinal, 'P.', 'P.') + '
    FROM (SELECT 1 AS Dummy) D
    LEFT JOIN #Datos P
        ON 1 = 1; 
  
    DROP TABLE #Datos;  
  
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
  
END