CREATE OR ALTER PROCEDURE PWST.SADS_AsigMetas_ConsultaDatos
(
    @mes INT,
    @anio INT,
    @agencia INT
)
AS
BEGIN

    SET NOCOUNT ON;

    WITH metas_existentes AS
    (
        SELECT
            M.NUR,
            CEILING(SUM(M.Valor_Meta)) AS Meta_Volumen
        FROM PWST.SADS_SegOper_Metas AS M
        INNER JOIN PWST.CATALOGOS_Agencias AS A
            ON M.NUR LIKE '%' + A.Clave_NUR + '%'
        WHERE
            M.Fecha BETWEEN DATEFROMPARTS(@anio, @mes, 1)
                        AND EOMONTH(DATEFROMPARTS(@anio, @mes, 1))
            AND A.Agencia = @agencia
        GROUP BY
            M.NUR
    )

    SELECT *
    FROM metas_existentes
    ORDER BY NUR;

END;
GO