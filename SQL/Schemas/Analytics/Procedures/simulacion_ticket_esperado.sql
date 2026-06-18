CREATE PROCEDURE ticket_esperado_por_ruta
AS
BEGIN

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

        WHERE Operacion = 'MONTERREY'
    ),

    paquetes_historicos AS (

        SELECT
            Ruta,
            Cliente,
            Fecha,
            SUM(Cantidad) AS total_diario

        FROM tabla_base

        WHERE Fecha BETWEEN
            DATEADD(MONTH, DATEDIFF(MONTH,0,GETDATE())-4,0)
            AND EOMONTH(GETDATE(),-1)

        GROUP BY
            Ruta,
            Cliente,
            Fecha
    )

    SELECT
        Ruta,
        AVG(CAST(total_diario AS FLOAT)) AS E_vol

    FROM paquetes_historicos

    GROUP BY Ruta;

END
GO