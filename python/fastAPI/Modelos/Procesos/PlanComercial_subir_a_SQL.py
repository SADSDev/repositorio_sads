# subir respuestas a API a SQL

# -----------------------------------
# LIBRERÍAS
# -----------------------------------
import pandas as pd
from sqlalchemy import text
from datetime import date
# -----------------------------------
# IMPORTS
# -----------------------------------
from Config.conexion_SQL import (
    manejar_error_conexion_sql,
    obtener_motor
)

# -----------------------------------
# PROCESO DE SUBIDA DE DATOS A SQL
# -----------------------------------
@manejar_error_conexion_sql
def subir_datos_sql_plancomercial(
    df_mam: pd.DataFrame,
    df_mart: pd.DataFrame,
    indicadores_agencia: dict[str, float],
    marcas_estrategicas: list,
    anio: int,
    mes: int,
    agencia:int,
    schema: str,
    tabla_metas_diarias_sql: str,
    tabla_metas_agencia_sql:str
) -> pd.DataFrame:

    #DF DE INDICADORES DE AGENCIA
    df_indicadores_agencia = pd.DataFrame({
        "Mes": date(anio, mes, 1),
        "Agencia": agencia,
        "CategoriaId": 1,
        "Indicador": list(indicadores_agencia.keys()),
        "Valor_Meta": list(indicadores_agencia.values())
    })

    # METAS DIARIAS DE VOLUMEN
    df_metas_volumen = (
        df_mart
        .merge(
            df_mam[["NUR", "meta_vol"]],
            on="NUR",
            how="left"
        )
        .assign(
            Valor_Meta=lambda x:
                x["Peso_Esperado"] * x["meta_vol"],
            CategoriaId=1,
            Indicador="VOLUMEN"
        )
        [["Fecha", "NUR", "CategoriaId", "Indicador", "Valor_Meta"]]
    )

    
    # METAS DIARIAS MARCAS ESTRATÉGICAS
    df_metas_me = (
        df_mart
        .merge(
            df_mam[["NUR"] + marcas_estrategicas],
            on="NUR",
            how="left"
        )
        .melt(
            id_vars=["Fecha", "NUR", "Peso_Esperado"],
            value_vars=marcas_estrategicas,
            var_name="Indicador",
            value_name="Meta_Mensual"
        )
        .assign(
            CategoriaId=1,
            Valor_Meta=lambda x:
                x["Peso_Esperado"] * x["Meta_Mensual"]
        )
        [["Fecha", "NUR", "CategoriaId", "Indicador", "Valor_Meta"]]
    )

    # UNIFICAR METAS
    df_metas_diarias = pd.concat(
        [
            df_metas_volumen,
            df_metas_me
        ],
        ignore_index=True
    )

    # SUBIR A SQL
    motor = obtener_motor()
    with motor.begin() as conn:
        # Eliminar metas existentes del mes de metas diarias
        sql_query_1 = text(f"""
            DELETE M
            FROM {schema}.{tabla_metas_diarias_sql} AS M
            INNER JOIN [PWST].[CATALOGOS_Agencias] AS A
                ON M.NUR LIKE '%' + A.Clave_NUR + '%'
            WHERE MONTH(M.Fecha) = :mes
            AND YEAR(M.Fecha) = :anio
            AND A.Agencia = :agencia
            AND M.CategoriaId = 1
        """)

        conn.execute(
            sql_query_1,
            {
                "mes": mes,
                "anio": anio,
                "agencia":agencia
            }
        )

        # Eliminar metas existentes del mes de metas mensuales
        sql_query_2 = text(f"""
            DELETE M
            FROM {schema}.{tabla_metas_agencia_sql} AS M
            WHERE MONTH(M.Mes) = :mes
            AND YEAR(M.Mes) = :anio
            AND M.Agencia = :agencia
            AND M.CategoriaId = 1
        """)

        conn.execute(
            sql_query_2,
            {
                "mes": mes,
                "anio": anio,
                "agencia":agencia
            }
        )

        # Insertar nuevas metas
        df_metas_diarias.to_sql(
            con=conn,
            schema=schema,
            name=tabla_metas_diarias_sql,
            if_exists="append",
            index=False
        )

        df_indicadores_agencia.to_sql(
            con=conn,
            schema=schema,
            name=tabla_metas_agencia_sql,
            if_exists="append",
            index=False
        )
        

    return df_metas_diarias