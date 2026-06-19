CREATE VIEW ANALYTICS.MAM_volumen_esperado_por_ruta
AS
WITH tabla_completa_de_metricas AS(
    SELECT
        A.*,
        B.frecuencia_recompra,
        C.ticket_esperado,
    ROUND((A.clientes_esperados*B.frecuencia_recompra*C.ticket_esperado),0) as volumen_esperado
    FROM ANALYTICS.MAM_Clientes_esperados_por_ruta A
    LEFT JOIN ANALYTICS.MAM_frecuencia_de_recompra_por_ruta B
    ON A.Ruta=B.Ruta
    LEFT JOIN ANALYTICS.MAM_ticket_esperado_por_ruta C
    ON A.Ruta=C.Ruta
)
SELECT
    Ruta,
    volumen_esperado
FROM tabla_completa_de_metricas

GO