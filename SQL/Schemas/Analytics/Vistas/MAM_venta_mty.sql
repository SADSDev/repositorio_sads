CREATE VIEW ANALYTICS.MAM_venta_mty
AS
WITH tabla_base AS (

    SELECT
        A.*,
        CASE
            WHEN B.Cliente IS NOT NULL THEN 1
            ELSE 0
        END AS existe_en_B

    FROM PowerStreet.DB_Cliente A

    LEFT JOIN CATALOGOS.Clientes_GTP B
        ON A.Cliente = B.Cliente
    
    WHERE Operacion='MONTERREY'--filtro de rutas de MTY
),

venta AS (

    SELECT
        Ruta,
        Cliente,
        Fecha,
        Familia,
        Cantidad

    FROM tabla_base

    WHERE Fecha BETWEEN
        DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE())-4,0)--historico de 4 meses
            AND EOMONTH(GETDATE(),-1)
        AND existe_en_B=0 --eliminar clientes de cartera GTP
)
SELECT*FROM venta;

GO