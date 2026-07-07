-- Este SP actualiza la meta mensual de la cantidad de visitas efectivas que
-- cada ruta debe hacer mensualmente, en base a la meta fija mensual de clientes
--y a los días operativos del mes de la meta
--Esta programado en un job para correr cada día ultimo del mes en curso

CREATE PROCEDURE SADS.ActualizarMetas_Visitas  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    DECLARE @Mes_Meta DATE;  
    DECLARE @Dias_Operativos INT;  
  
    -- Primer día del siguiente mes  
    SET @Mes_Meta = DATEFROMPARTS  
    (  
        YEAR(DATEADD(MONTH, 1, GETDATE())),  
        MONTH(DATEADD(MONTH, 1, GETDATE())),  
        1  
    );  
  
    -- Obtener la cantidad de días hábiles del mes  
    SELECT  
        @Dias_Operativos = COUNT(*)  
    FROM CATALOGOS.Calendario  
    WHERE  
        Anio = YEAR(@Mes_Meta)  
        AND Mes = MONTH(@Mes_Meta)  
        AND Es_Habil = 1;  
  
    -- Si ya existen metas para ese mes, reemplazarlas  
    DELETE  
    FROM SADS.OP_Objetivos_Mensuales  
    WHERE Fecha = @Mes_Meta;  
  
    -- Insertar metas diarias por ruta  
    INSERT INTO SADS.OP_Objetivos_Mensuales  
    (  
        Fecha,  
        NUR,  
        Obj_Visitas_Mensual,
        Obj_Visitas_Diario
    )  
    SELECT  
        @Mes_Meta,  
        NUR,
        Objetivo_Mensual_Visitas, 
        ROUND(Objetivo_Mensual_Visitas / @Dias_Operativos, 3)  
    FROM CATALOGOS.Objetivos_Fijos_Rutas;  
  
END;  
