# subir respuestas a API a SQL

# -----------------------------------
# LIBRERÍAS
# -----------------------------------
import pandas as pd
from sqlalchemy import text

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
def subir_datos_sql(
    df_mam: pd.DataFrame,
    df_mart: pd.DataFrame,
    marcas_estrategicas: list,
    anio: int,
    mes: int,
    schema: str,
    tabla_sql: str
) -> pd.DataFrame:

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
        # Eliminar metas existentes del mes
        sql_query = text(f"""
            DELETE FROM {schema}.{tabla_sql}
            WHERE MONTH(Fecha) = :mes
              AND YEAR(Fecha) = :anio
        """)

        conn.execute(
            sql_query,
            {
                "mes": mes,
                "anio": anio
            }
        )

        # Insertar nuevas metas
        df_metas_diarias.to_sql(
            con=conn,
            schema=schema,
            name=tabla_sql,
            if_exists="append",
            index=False
        )

    return df_metas_diarias