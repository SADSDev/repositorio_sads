CREATE   PROCEDURE PWST.CATALOGOS_ObtenerMeses  
AS  
BEGIN  
    SET NOCOUNT ON;  
  
    SELECT *  
    FROM  
    (  
        VALUES  
            (1, 'Enero'),  
            (2, 'Febrero'),  
            (3, 'Marzo'),  
            (4, 'Abril'),  
            (5, 'Mayo'),  
            (6, 'Junio'),  
            (7, 'Julio'),  
            (8, 'Agosto'),  
            (9, 'Septiembre'),  
            (10, 'Octubre'),  
            (11, 'Noviembre'),  
            (12, 'Diciembre')  
    ) AS Meses (MesId, Mes)  
    ORDER BY MesId;  
END;  