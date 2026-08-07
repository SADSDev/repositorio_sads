#Este script se encarga de generar un calendario con el esfuerzo historico
#de cada dia del historico de los utltimos max(ponderaciones[mes]) meses

#------------------------------------------------------------
# LIBRERIAS
#-----------------------------------------------------------
import pandas as pd



#-------------------------------------------------------------
# IMPORTS
#-------------------------------------------------------------


#------------------------------------------------------------
# OBTENCION DE ESFUERZO HISTORICO
#-------------------------------------------------------------
def esfuerzo_historico(df_venta: pd.DataFrame)-> pd.DataFrame:
    df_venta["Fecha"] = pd.to_datetime(df_venta["Fecha"])

    df_esfuerzo_historico = (
        df_venta
        .groupby(["NUR", "Fecha"], as_index=False)
        .agg(
            Cantidad=("Cantidad", "sum")
        )
        .assign(
            Mes= lambda x: x["Fecha"].dt.to_period("M").dt.to_timestamp(),
            Cantidad_Mensual=lambda x: x.groupby(["NUR", "Mes"])["Cantidad"].transform("sum"),
            Esfuerzo=lambda x: x["Cantidad"] / x["Cantidad_Mensual"]
        )
        [["NUR","Fecha", "Mes", "Esfuerzo"]]
    )

    return df_esfuerzo_historico