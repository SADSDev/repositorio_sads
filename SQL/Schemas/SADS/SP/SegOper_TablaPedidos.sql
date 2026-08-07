CREATE OR ALTER PROCEDURE SADS.SegOper_TablaPedidos
(
    @fecha DATE,
    @agencia INT=NULL,
    @zona VARCHAR(20)=NULL,
    @ruta VARCHAR(10)=NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    
    -------------------------------------------------------
    -- Proceso
    -------------------------------------------------------
    ;WITH Rutas AS
    (
        SELECT DISTINCT
            V.NUR,
            A.Agencia,
            A.CLO,
            V.Grupo AS Zona
        FROM CATALOGOS.Rutas_Evaluables V

        INNER JOIN CATALOGOS.Agencias A
            ON V.NUR LIKE A.Clave_NUR + '%'

        WHERE
            V.NUR <> '1125632M29'
            AND (@agencia IS NULL OR A.Agencia = @agencia)
            AND (@zona IS NULL OR V.Grupo = @zona)
            AND
            (
                @ruta IS NULL
                OR CONCAT(
                        'R',
                        SUBSTRING(
                            V.NUR,
                            PATINDEX('%[A-Z]%', V.NUR) + 1,
                            LEN(V.NUR)
                        )
                    ) = @ruta
            )
    ),
    
    pedidos_filtrado AS
    (
        SELECT *
        FROM
        (
            SELECT
                A.*,
                R.Agencia,
                ROW_NUMBER() OVER
                (
                    PARTITION BY A.Orden
                    ORDER BY A.Fecha DESC
                ) AS rn
            FROM PowerStreet.Fullfillment_Pedidos_PMM A
            INNER JOIN Rutas R
                ON A.NUR = R.NUR
            WHERE A.Fecha >= DATEFROMPARTS(YEAR(@fecha), MONTH(@fecha), 1)
              AND A.Fecha <= @fecha
        ) X
        WHERE rn = 1
    ),  
    
    tabla_pedidos AS
    (
        SELECT
            NUR,
            Agencia,
            COUNT(Orden) AS Asignados,
            SUM(CASE WHEN Cantidad_Orden >= Cantidad_Entrega THEN 1 ELSE 0 END) AS Entregados,
            SUM(CASE WHEN Cantidad_Entrega < Cantidad_Orden THEN 1 ELSE 0 END) AS Incompletos,
            SUM(CASE WHEN Status_Entrega = 'PENDIENTE' THEN 1 ELSE 0 END) AS Pendientes,
            SUM(CASE WHEN Status_Entrega = 'RECHAZADO' THEN 1 ELSE 0 END) AS Rechazados,
            CAST(AVG(Fillrate) / 100.0 AS DECIMAL(10,4)) AS Fillrate,
            CAST(AVG(Fullfillment) / 100.0 AS DECIMAL(10,4)) AS Fullfillment
        FROM pedidos_filtrado
        GROUP BY NUR, Agencia
    )
    SELECT*FROM tabla_pedidos
    ORDER BY NUR ASC

END;
GO