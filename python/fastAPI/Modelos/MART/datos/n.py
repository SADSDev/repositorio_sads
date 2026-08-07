#calculo de la n_i,d,k 
#la cantidad de veces observada la combinacion de dia mes+dia semana

#----------------------------------------------------------------
# LIBRERIAS 
# ---------------------------------------------------------------
import pandas as pd

from datetime import datetime
#----------------------------------------------------------------
# IMPORTS 
#----------------------------------------------------------------


#----------------------------------------------------------------
# PROCESO DE OBTENCION DE PARAMETRO n
#----------------------------------------------------------------
def parametro_n(
    df_esfuerzo_historico: pd.DataFrame,
) -> pd.DataFrame:

    # Universo de combinaciones
    df_base = (
        df_esfuerzo_historico[["NUR"]]
        .drop_duplicates()
        .merge(
            pd.DataFrame({
                "Dia_Mes": range(1, 32)
            }),
            how="cross"
        )
        .merge(
            pd.DataFrame({
                "Dia_Semana": range(1, 8)
            }),
            how="cross"
        )
    )

    # Conteo histórico observado
    df_n = (
        df_esfuerzo_historico
        .assign(
            Dia_Mes=lambda x: x["Fecha"].dt.day,
            Dia_Semana=lambda x: x["Fecha"].dt.dayofweek + 1
        )
        .groupby(
            ["NUR", "Dia_Mes", "Dia_Semana"],
            as_index=False
        )
        .size()
        .rename(columns={"size": "n"})
    )

    # Completar combinaciones no observadas
    df_n = (
        df_base
        .merge(
            df_n,
            on=["NUR", "Dia_Mes", "Dia_Semana"],
            how="left"
        )
        .fillna({"n": 0})
    )

    print("el df_n contiene:")
    print(df_n.head(20))

    return df_n