CREATE VIEW ANALYTICS.MAM_capacidad_base_por_ruta
AS 
WITH clientes_activos_por_ruta AS (

    SELECT
        Ruta,
        COUNT(DISTINCT Codigo_GLN) AS clientes_activos

    FROM PowerStreet.UX

    WHERE Estatus = 'Activo'

    GROUP BY Ruta
),

capacidad_base_por_ruta AS (
    SELECT
        A.*,
        B.clientes_esperados,
        C.volumen_esperado,
        ROUND((POWER(
            NULLIF(A.clientes_activos,0),
            P.valor
        )
        *
        POWER(
            NULLIF(B.clientes_esperados,0),
            1 - P.valor
        )
        *
        C.volumen_esperado),0) AS capacidad_base
    FROM clientes_activos_por_ruta A 
    LEFT JOIN ANALYTICS.MAM_clientes_esperados_por_ruta B
    ON A.Ruta=B.Ruta
    LEFT JOIN ANALYTICS.MAM_volumen_esperado_por_ruta C
    ON A.Ruta=C.Ruta
    
    CROSS JOIN (
    SELECT valor
    FROM ANALYTICS.MAM_Parametros_Ajustables
    WHERE parametro='alpha'
    ) P
        
)
SELECT
    Ruta,
    capacidad_base
FROM capacidad_base_por_ruta
GO
