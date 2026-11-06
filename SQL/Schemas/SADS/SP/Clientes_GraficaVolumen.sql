  
CREATE OR ALTER PROCEDURE [PWST].[SADS_Clientes_GraficaVolumen]  
@Cliente VARCHAR(300),  
@Inicio INT,  
@Fin INT,  
@Ainicio INT,  
@Afin INT  
  
AS  
BEGIN
    SET NOCOUNT ON;
  
    DECLARE @CruzaAnio BIT =
        CASE
            WHEN @Inicio < 1
             AND @Ainicio < @Afin
            THEN 1
            ELSE 0
        END;

    DECLARE @SemanasAnioInicio INT =
        DATEPART(
            ISO_WEEK,
            DATEFROMPARTS(@Ainicio, 12, 28)
        );

    DECLARE @InicioAjustado INT =
        CASE
            WHEN @CruzaAnio = 1
            THEN @SemanasAnioInicio + @Inicio
            ELSE @Inicio
        END;

    ;WITH Datos AS
    (
        SELECT
            DATEPART(ISO_WEEK, VD.Fecha) AS SemanaIso,
            YEAR(VD.Fecha) AS Anio,
            ISNULL(SUM(VD.Cantidad), 0) AS Cantidad
        FROM [PWST].[POWERSTREET_Venta_Diaria] VD
        WHERE VD.Cliente = @Cliente
          AND
          (
              -- Consulta normal dentro del mismo año
              (
                  @CruzaAnio = 0
                  AND DATEPART(ISO_WEEK, VD.Fecha)
                      BETWEEN @Inicio AND @Fin
                  AND YEAR(VD.Fecha)
                      BETWEEN @Ainicio AND @Afin
              )

              OR

              -- Semanas restantes del año anterior
              (
                  @CruzaAnio = 1
                  AND YEAR(VD.Fecha) = @Ainicio
                  AND DATEPART(ISO_WEEK, VD.Fecha)
                      BETWEEN @InicioAjustado
                      AND @SemanasAnioInicio
              )

              OR

              -- Semanas iniciales del año actual
              (
                  @CruzaAnio = 1
                  AND YEAR(VD.Fecha) = @Afin
                  AND DATEPART(ISO_WEEK, VD.Fecha)
                      BETWEEN 1 AND @Fin
              )
          )
        GROUP BY
            DATEPART(ISO_WEEK, VD.Fecha),
            YEAR(VD.Fecha)
    )
    SELECT
        SemanaIso,
        Cantidad
    FROM Datos
    ORDER BY
        CASE
            WHEN @CruzaAnio = 1
             AND Anio = @Ainicio
            THEN 0

            WHEN @CruzaAnio = 1
             AND Anio = @Afin
            THEN 1

            ELSE 0
        END,
        SemanaIso;
END;
  
--SELECT DATEPART(ISO_WEEK, A.Fecha) AS Semana,  
--  A.Cantidad  
--FROM ( SELECT    
--   Fecha ,         
--   SUM(Cantidad) AS Cantidad  
--  FROM [PWST].[VentaPorRutaSOD]  
--  WHERE Cliente = @Cliente  
--  AND  Fecha   
--  BETWEEN PWST.ObtenerFechaI(@Inicio)    
--  AND  PWST.ObtenerFechaF(@Fin)   
--  GROUP BY  fecha ) A  
--  Order by Semana  
  
  