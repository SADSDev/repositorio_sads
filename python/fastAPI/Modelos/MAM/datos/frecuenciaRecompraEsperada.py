# obtención de la frecuencia de recompra de un cliente cualquiera en la cartera de una ruta

#----------------------------------------------------
# LIBRERIAS
#----------------------------------------------------
import pandas as pd


#----------------------------------------------------
# IMPORTS
#----------------------------------------------------
from fastAPI.Modelos.MAM.datos.eficienciaVentaMes import clientes_unicos_por_mes
from fastAPI.Modelos.MAM.datos.ticketEsperado import venta_por_cliente



#-----------------------------------------------------
# OBTENCION DE FRECUENCIA DE COMPRA POR CLIENTE POR MES Y PONDERADO
#----------------------------------------------------
def tickets_por_ruta_mes(df_venta_por_cliente: pd.DataFrame) -> pd.DataFrame:
    return (
        df_venta_por_cliente
        .assign(
            Mes=lambda x: x["Fecha"].dt.to_period("M").dt.to_timestamp()
        )
        .groupby(["NUR", "Mes"])
        .agg(
            ticket=("Cliente", "count")
        )
        .reset_index()
    )

def frecuencia_por_mes(
    df_tickets_por_ruta_mes: pd.DataFrame,
    df_clientes_unicos_por_mes: pd.DataFrame,
    df_ponderaciones: pd.DataFrame) -> pd.DataFrame:
    return (
        df_tickets_por_ruta_mes
        .merge(
            df_clientes_unicos_por_mes,
            on=["NUR", "Mes"],
            how="left"
        )
        .assign(
            frecuencia_mensual=lambda x: x["ticket"] / x["clientes_unicos"]
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

def frecuencia_ponderada(df_frecuencia_por_mes: pd.DataFrame) -> pd.DataFrame:
    return (
        df_frecuencia_por_mes
        .assign(
            valor=lambda x: x["frecuencia_mensual"] * x["Peso"]
        )
        .groupby("NUR")
        .agg(
            frecuencia_ponderada=("valor", "sum")
        )
        .reset_index()
    )