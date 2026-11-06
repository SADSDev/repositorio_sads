CREATE  OR ALTER PROCEDURE [PWST].[SADS_Clientes_TablaVisita]  
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
    [PWST].[DiaSemana](V.Fecha) as Dia,   
    FORMAT(V.Fecha, 'dd-MM-yyyy') as Fecha,   
    FORMAT(V.HoraInicio, 'hh\:mm') AS Hora,  
    DATEDIFF(MINUTE,V.HoraInicio,V.HoraFinal ) AS Tiempo,   
    V.TipoInicio AS Apertura,
    V.PaquetesVendidos AS [Paquetes vendidos]  
  FROM PWST.POWERSTREET_PDV_PorAgencia V 
  WHERE Cliente = @Cliente  
  AND Fecha BETWEEN @FechaInicio AND @FechaFin    
  ORDER BY
      CONVERT(DATETIME, V.Fecha) ASC,
      HoraInicio ASC;

END
