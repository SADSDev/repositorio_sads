# obtencion de la eficiencia de la cartera de cada ruta por mes y su promedio ponderado

#----------------------------------------------------
# LIBRERIAS
#----------------------------------------------------
import pandas as pd
from datetime import date, timedelta

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------



#-----------------------------------------------------
# OBTENCION DE EFICIENCIA POR MES Y PONDERADO
#----------------------------------------------------
def clientes_unicos_por_mes(df_venta:pd.DataFrame)-> pd.DataFrame:
    return (
        df_venta
        .assign(
            Mes=df_venta["Fecha"].dt.to_period("M").dt.to_timestamp()
        )
        .groupby(["NUR", "Mes"])
        .agg(
            clientes_unicos=("Cliente", "nunique")
        )
        .reset_index()
    )


def eficiencia_por_mes(
        df_clientes_unicos_por_mes: pd.DataFrame,
        df_clientes_activos: pd.DataFrame, 
        df_ponderaciones: pd.DataFrame)-> pd.DataFrame:
    return (
        df_clientes_unicos_por_mes
        .merge(
            df_clientes_activos,
            on="NUR",
            how="left"
        )
        .assign(
            eficiencia=lambda x: x["clientes_unicos"] / x["activos"]
        )
        .sort_values(
            ["NUR", "Mes"],
            ascending=[True, False]
        )
        .assign(
            Mes=lambda x: x.groupby("NUR").cumcount() + 1
        )
        .merge(
            df_ponderaciones,
            on="Mes",
            how="left"
        )
    )


def eficiencia_ponderada(df_eficiencia_mes: pd.DataFrame)-> pd.DataFrame:
    return (
        df_eficiencia_mes
        .assign(
            valor=lambda x: x["eficiencia"] * x["Peso"]
        )
        .groupby("NUR")
        .agg(
            eficiencia_ponderada=("valor", "sum")
        )
        .reset_index()
    )