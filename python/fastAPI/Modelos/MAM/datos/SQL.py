# PROCESO DE OBTENCION DE TABLAS SQL


#-----------------------------------
#LIBRERIAS
#-----------------------------------
import pandas as pd
from sqlalchemy import text
from datetime import date

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------
from Config.conexion_SQL import (
    manejar_error_conexion_sql,
    obtener_motor
)


#----------------------------------------------------------
# PROCESO DE OBTENCION DE DF DE VENTAS sin clientes GTP
#--------------------------------------------------------
@manejar_error_conexion_sql
def obtener_tabla_ventas(agencia: int, fecha_inicio: date, fecha_fin: date):
    motor=obtener_motor()
    return pd.read_sql(
        text("""
            WITH rutas AS (
                SELECT
                    NUR
                FROM PWST.CATALOGOS_Vendedores
                WHERE Agencia = :agencia
                AND Evaluable=1
            ),

            articulos AS (
                SELECT
                    Codigo,
                    Familia
                FROM PWST.CATALOGOS_Articulos
            ),

            ventas_sin_gtp AS (
                SELECT
                    A.Fecha,
                    A.NUR,
                    A.Cliente,
                    A.Cantidad,
                    A.Codigo_Articulo,
                    C.Familia,
                    CASE
                        WHEN B.Cliente IS NOT NULL THEN 1
                        ELSE 0
                    END AS existe_en_B
                FROM POWERSTREET_Venta_Diaria A
                LEFT JOIN PWST.CATALOGOS_Clientes_GTP B
                    ON A.Cliente = B.Cliente
                LEFT JOIN articulos C
                    ON A.Codigo_Articulo = C.Codigo
                INNER JOIN rutas R
                    ON A.NUR=R.NUR
                WHERE Fecha BETWEEN :fecha_inicio AND :fecha_fin
                AND A.NUR <> '1125632M29'
            )   
            SELECT
                    Fecha,
                    DATEFROMPARTS(
                        YEAR(Fecha),
                        MONTH(Fecha),
                        1
                    ) AS Mes,
                    NUR,
                    Cliente,
                    Familia,
                    Cantidad
            FROM ventas_sin_gtp
            WHERE existe_en_B=0
            ORDER BY Fecha DESC, NUR ASC
        """),
        motor,
        params={
            "agencia": agencia,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        }
    )

#--------------------------------------------------------
# OBTENCION DE DF DE UNIVERSO DE CLIENTES 
#--------------------------------------------------------
@manejar_error_conexion_sql
def obtener_tabla_ux(agencia:int):
    motor=obtener_motor()
    return pd.read_sql(
        text("""
            WITH rutas AS (
                SELECT
                    NUR
                FROM PWST.CATALOGOS_Vendedores
                WHERE Agencia = :agencia
                AND Evaluable=1
            ),

            ux AS (
                SELECT
                    A.Agencia,
                    A.NUR,
                    A.Codigo_GLN,
                    A.Status
                FROM PWST.POWERSTREET_Universo_Clientes A
                INNER JOIN rutas B
                    ON A.NUR = B.NUR
                WHERE A.NUR <> '1125632M29'
            )
            SELECT*FROM ux;
        """),
        motor,
        params={
            "agencia":agencia
        }
    )

#-------------------------------------------------------------
# OBTENER VIGENCIAS DE ME
#-------------------------------------------------------------
@manejar_error_conexion_sql
def obtener_vigencias_me(
    agencia: int,
    fecha_inicio: date,
    fecha_fin: date
):
    motor=obtener_motor()
    return pd.read_sql(
        text("""
            WITH Vigencias AS
            (
                SELECT
                    Familia,
                    DATEFROMPARTS(
                        YEAR(Inicio_Vigencia),
                        MONTH(Inicio_Vigencia),
                        1
                    ) AS Mes,
                    Fin_Vigencia
                FROM PWST.CATALOGOS_Vigencias_ME
                WHERE Agencia = :agencia

                UNION ALL

                SELECT
                    Familia,
                    DATEADD(MONTH, 1, Mes),
                    Fin_Vigencia
                FROM Vigencias
                WHERE DATEADD(MONTH, 1, Mes)
                    <= DATEFROMPARTS(
                        YEAR(ISNULL(Fin_Vigencia, :fecha_fin)),
                        MONTH(ISNULL(Fin_Vigencia, :fecha_fin)),
                        1
                    )
            )

            SELECT
                Familia,
                Mes
            FROM Vigencias
            WHERE Mes BETWEEN :fecha_inicio AND :fecha_fin
            ORDER BY
                Familia,
                Mes
        """),
        motor,
        params={
            "agencia": agencia,
            "fecha_inicio": fecha_inicio,
            "fecha_fin": fecha_fin
        }
    )   