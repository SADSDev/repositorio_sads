CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaCombos]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  
  
AS  
BEGIN 
SET NOCOUNT ON;  
    
    DECLARE @FechaInicio DATE
    DECLARE @FechaFin DATE
    DECLARE @DiferenciaSemanas INT

    SET @FechaFin = DATEADD(
        DAY,
        (@Fin - 1) * 7 + 6,
        DATEADD(
            DAY,
            -(DATEDIFF(DAY, '19000101', DATEFROMPARTS(@Afin, 1, 4)) % 7)-1,
            DATEFROMPARTS(@Afin, 1, 4)
        )
    );
    
    IF @Ainicio < @Afin AND @Inicio < 0 AND @Fin > 0
    BEGIN
       SET @FechaInicio = DATEADD(
            WEEK,
            @Inicio,
            DATEADD(
                DAY,
                -(DATEDIFF(
                    DAY,
                    '19000101',
                    DATEFROMPARTS(@Ainicio, 12, 28)
                ) % 7),
                DATEFROMPARTS(@Ainicio, 12, 28)
            )
        );
    END
    ELSE
    BEGIN 
        SET @DiferenciaSemanas= @Fin-@Inicio
        SET @FechaInicio =DATEADD(DAY, -5,DATEADD(
                WEEK, -@DiferenciaSemanas, @FechaFin
            )
        )
    END

    SELECT
        FORMAT(C.Fecha, 'dd-MM-yyyy') AS Fecha, 
        C.Codigo_Combo as FAP, 
        C.Descripcion_Combo as Descripcion, 
        C.Cantidad_Combos as Cantidad
    FROM PWST.POWERSTREET_Combos_Por_Cliente C  
    WHERE C.Codigo_Cliente = @Cliente    
    AND C.Fecha BETWEEN @FechaInicio AND @FechaFin    
    ORDER BY C.Fecha ASC;
END  
