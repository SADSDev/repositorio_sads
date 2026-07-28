# Obtención de clientes activos en la cartera de cada ruta

#----------------------------------------------------
# LIBRERIAS
#----------------------------------------------------
import pandas as pd

#----------------------------------------------------
# IMPORTS
#----------------------------------------------------


#----------------------------------------------------
# CLIENTES ACTIVOS POR RUTA
#----------------------------------------------------
def clientes_activos(df_ux: pd.DataFrame)-> pd.DataFrame:
    return (
        df_ux.groupby("NUR")
        .agg(
            activos=("Status", lambda x: (x == "Activo").sum())
        )
        .reset_index()
    )