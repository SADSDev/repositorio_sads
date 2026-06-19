CREATE VIEW ANALYTICS.MAM_Clientes_esperados_por_ruta
AS
WITH
clientes_activos_por_ruta AS (

    SELECT
        Ruta,
        COUNT(DISTINCT Codigo_GLN) AS clientes_activos

    FROM PowerStreet.UX

    WHERE Estatus = 'Activo'

    GROUP BY Ruta
),

clientes_unicos_por_mes_por_ruta AS (

    SELECT
        Ruta,
        YEAR(Fecha) AS anio,
        MONTH(Fecha) AS mes,
        COUNT(DISTINCT Cliente) AS clientes_compradores_unicos

    FROM ANALYTICS.MAM_venta_diaria_de_clientes_por_ruta

    GROUP BY
        Ruta,
        YEAR(Fecha),
        MONTH(Fecha)
),

efectividad_compra AS (

    SELECT
        A.Ruta,
        A.anio,
        A.mes,
        A.clientes_compradores_unicos,
        B.clientes_activos,

        CAST(A.clientes_compradores_unicos AS FLOAT)
        / NULLIF(B.clientes_activos,0) AS pct_compra

    FROM clientes_unicos_por_mes_por_ruta A

    LEFT JOIN clientes_activos_por_ruta B
        ON A.Ruta = B.Ruta
),

efectividad_pond_por_mes AS (

    SELECT
        A.Ruta,

        SUM(
            A.pct_compra * B.peso
        ) / SUM(B.peso) AS efectividad_ponderada

    FROM (

        SELECT
            Ruta,
            anio,
            mes,
            pct_compra,

            ROW_NUMBER() OVER(
                PARTITION BY Ruta
                ORDER BY anio DESC, mes DESC
            ) AS mes_relativo

        FROM efectividad_compra

    ) A
    
    LEFT JOIN ANALYTICS.MAM_Ponderaciones B
        ON A.mes_relativo = B.mes

    GROUP BY A.Ruta
),

clientes_esperados_por_ruta AS (

    SELECT
        A.Ruta,
        A.efectividad_ponderada,
        B.clientes_activos,

        ROUND(
            B.clientes_activos * A.efectividad_ponderada,
            0
        ) AS clientes_esperados

    FROM efectividad_pond_por_mes A

    LEFT JOIN clientes_activos_por_ruta B
        ON A.Ruta = B.Ruta
)

SELECT
    Ruta,
    clientes_esperados
FROM clientes_esperados_por_ruta;
GO
