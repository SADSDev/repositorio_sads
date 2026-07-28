# obtencion deL Ticket (total de paquetes) esperado en la venta de una ruta

#----------------------------------------------------
# LIBRERIAS
#----------------------------------------------------
import pandas as pd


#----------------------------------------------------
# IMPORTS
#----------------------------------------------------



#-----------------------------------------------------
# OBTENCION DE TICKET ESPERADO
#----------------------------------------------------
def venta_por_cliente(df_venta: pd.DataFrame) -> pd.DataFrame:
    return (
        df_venta
        .groupby(["NUR", "Cliente", "Fecha"])
        .agg(
            paquetes=("Cantidad", "sum")
        )
        .reset_index()
    )


def ticket_esperado(df_venta_por_cliente: pd.DataFrame)-> pd.DataFrame:
    return (
        df_venta_por_cliente
        .groupby("NUR")
        .agg(
            ticket_esperado=("paquetes", "mean")
        )
        .reset_index()
    )

