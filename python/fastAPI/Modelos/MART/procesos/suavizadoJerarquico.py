#proceso encargado de generar un promedio mediante suavizado jerarquico


#----------------------------------------------------------------
# LIBRERIAS 
# ---------------------------------------------------------------
import pandas as pd

#----------------------------------------------------------------
# IMPORTS 
#----------------------------------------------------------------


#----------------------------------------------------------------
# PROCESO de Suavizacion jerarquica
#----------------------------------------------------------------
def suavizado_jerarquico(df_prom_pond_diames_diasem: pd.DataFrame,
    df_prom_pond_diames: pd.DataFrame,
    df_prom_pond_diasem: pd.DataFrame,
    df_n: pd.DataFrame,
    parametro_c:int,
    bet:float)-> pd.DataFrame:
    df_suavizdo_jerarquico = (
        df_n
        .merge(
            df_prom_pond_diames_diasem,
            on=["NUR", "Dia_Mes", "Dia_Semana"],
            how="left"
        )
        .merge(
            df_prom_pond_diames,
            on=["NUR", "Dia_Mes"],
            how="left"
        )
        .merge(
            df_prom_pond_diasem,
            on=["NUR", "Dia_Semana"],
            how="left"
        )
        .assign(
            Prom_Pond_Diames_Diasem=lambda x: x["Prom_Pond_Diames_Diasem"].fillna(0),
            Prom_Pond_Diames=lambda x: x["Prom_Pond_Diames"].fillna(0),
            Prom_Pond_Diasemana=lambda x: x["Prom_Pond_Diasemana"].fillna(0),

            Alpha=lambda x:
                x["n"] / (x["n"] + parametro_c),

            Beta=lambda x:
                bet * (1 - x["Alpha"]),

            Upsilon=lambda x:
                (1 - bet) * (1 - x["Alpha"]),

            Prom_Suavizado=lambda x:
                (
                    x["Alpha"] * x["Prom_Pond_Diames_Diasem"]
                    + x["Beta"] * x["Prom_Pond_Diames"]
                    + x["Upsilon"] * x["Prom_Pond_Diasemana"]
                )
        )
    )

    return df_suavizdo_jerarquico