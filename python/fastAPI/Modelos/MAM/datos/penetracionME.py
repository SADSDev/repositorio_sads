# obtención de la penetración de las marcas estrategicas vigentes en los ultimos
#4 meses de cada ruta

#----------------------------------------------------
# LIBRERIAS
#----------------------------------------------------
import pandas as pd


#----------------------------------------------------
# IMPORTS
#----------------------------------------------------
from fastAPI.Modelos.MAM.datos.clientesActivos import clientes_activos
from fastAPI.Modelos.MAM.datos.SQL import obtener_vigencias_me
from fastAPI.Modelos.MAM.Config.parametros import obtener_ponderaciones

#-----------------------------------------------------
# OBTENCION DE PENETRACIONES DE VENTA DE ME
#----------------------------------------------------

# total de paquetes vendidos por cada marca y mes
def venta_marca_mes_cliente(
    df_venta: pd.DataFrame,
    df_vigencias_me: pd.DataFrame
)-> pd.DataFrame:

    return(
        df_venta
        .groupby(["NUR", "Cliente", "Familia", "Mes"])
        .agg(
            venta_cliente=("Cantidad", "sum")
        )
        .reset_index()
        .merge(
            df_vigencias_me,
            on=["Familia", "Mes"],
            how="inner"
        )
    ) 


#adopcion por marca, mes y ruta
def adopcion_marca_mes_cliente(
    df_venta_marca_mes_cliente: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_venta_marca_mes_cliente
        .assign(
            adopcion=lambda x: (x["venta_cliente"] >= 0.2).astype(int)
        )
        .groupby(["NUR", "Familia", "Mes"])
        .agg(
            clientes_que_adoptaron=("adopcion", "sum")
        )
        .reset_index()
    )


#penetracion por mes, marca y ruta
def penetracion_marca_mes_cliente(
    df_adopcion_marca_mes_cliente: pd.DataFrame,
    df_clientes_activos: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_adopcion_marca_mes_cliente
        .merge(
            df_clientes_activos,
            on="NUR",
            how="left"
        )
        .assign(
            pen_mensual=lambda x: x["clientes_que_adoptaron"] / x["activos"]
        )
        [[
            "NUR",
            "Familia",
            "Mes",
            "clientes_que_adoptaron",
            "pen_mensual"
        ]]
    )

#penetracion promedio por mes y ruta
def penetracionprom_mes(
    df_penetracion_marca_mes: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_penetracion_marca_mes
        .assign(
            valor=lambda x: x["pen_mensual"] * x["clientes_que_adoptaron"]
        )
        .groupby(["NUR", "Mes"])
        .agg(
            total_clientes=("clientes_que_adoptaron", "sum"),
            numerador=("valor", "sum")
        )
        .assign(
            pen_prom=lambda x: x["numerador"] / x["total_clientes"]
        )
        .reset_index()[["NUR", "Mes", "total_clientes", "pen_prom"]]
    )

#penetracion ponderada de las me
def penetracion_ponderada(
    df_penetracionprom_mes: pd.DataFrame,
    df_ponderaciones: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_penetracionprom_mes
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
        .assign(
            valor=lambda x: x["pen_prom"] * x["Peso"]
        )
        .groupby("NUR")
        .agg(
            pen_ponderada=("valor", "sum")
        )
        .reset_index()
    )

#venta promedio por mes, marca y ruta
def ventaprom_marca_mes(
    df_venta_marca_mes_cliente: pd.DataFrame,
    df_adopcion_marca_mes_cliente: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_venta_marca_mes_cliente
        .groupby(["NUR", "Familia", "Mes"])
        .agg(
            venta_total=("venta_cliente", "sum")
        )
        .reset_index()
        .merge(
            df_adopcion_marca_mes_cliente,
            on=["NUR", "Familia", "Mes"],
            how="left"
        )
        .assign(
            venta_promedio=lambda x: x["venta_total"] / x["clientes_que_adoptaron"]
        )
        [[
            "NUR",
            "Familia",
            "Mes",
            "clientes_que_adoptaron",
            "venta_promedio"
        ]]
    )

#venta promedio por mes
def ventaprom_prom_mes(
    df_ventaprom_marca_mes: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_ventaprom_marca_mes
        .assign(
            valor=lambda x: x["venta_promedio"] * x["clientes_que_adoptaron"]
        )
        .groupby(["NUR", "Mes"])
        .agg(
            total_clientes=("clientes_que_adoptaron", "sum"),
            numerador=("valor", "sum")
        )
        .assign(
            mu_E=lambda x: x["numerador"] / x["total_clientes"]
        )
        .reset_index()
        [["NUR", "Mes", "total_clientes", "mu_E"]]
    )

#venta ponderada
def ventaprom_ponderada(
    df_ventaprom_prom_mes: pd.DataFrame,
    df_ponderaciones: pd.DataFrame
) -> pd.DataFrame:

    return (
        df_ventaprom_prom_mes
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
        .assign(
            valor=lambda x: x["mu_E"] * x["Peso"]
        )
        .groupby("NUR")
        .agg(
            mu_ponderada=("valor", "sum")
        )
        .reset_index()
    )