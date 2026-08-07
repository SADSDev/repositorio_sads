#se obtienen 3 tipos de promedio ponderado, 
# prom pond por dia de mes + dia de semana
# prom pond por dia de mes
# prom pond por dia de la semana

#----------------------------------------------------------------
# LIBRERIAS 
# ---------------------------------------------------------------
import pandas as pd

#----------------------------------------------------------------
# IMPORTS 
#----------------------------------------------------------------


#----------------------------------------------------------------
# PROCESOS DE OBTENCION DE PROMEDIOS PONDERADOS
#----------------------------------------------------------------
def promedio_pond_diames_diasem(
        df_esfuerzo_historico: pd.DataFrame,
        df_ponderaciones: pd.DataFrame) -> pd.DataFrame:

    df_prom_pond_diames_diasem = (
        df_esfuerzo_historico
        .loc[
            lambda x: x["Fecha"].dt.dayofweek != 6
        ]  # Quita domingos
        .sort_values(
            ["NUR", "Mes"],
            ascending=[True, False]
        )
        .assign(
            Mes_Pond=lambda x:
                x.groupby("NUR")["Mes"]
                .rank(method="dense", ascending=False)
                .astype(int)
        )
        .merge(
            df_ponderaciones,
            left_on="Mes_Pond",
            right_on="Mes",
            how="left"
        )
        .assign(
            Dia_Mes=lambda x:
                x["Fecha"].dt.day,

            Dia_Semana=lambda x:
                x["Fecha"].dt.dayofweek + 1,

            Esfuerzo_Pond=lambda x:
                x["Esfuerzo"] * x["Peso"]
        )
        .groupby(
            [
                "NUR",
                "Dia_Mes",
                "Dia_Semana"
            ],
            as_index=False
        )
        .agg(
            Suma_Esfuerzo_Pond=(
                "Esfuerzo_Pond",
                "sum"
            ),
            Suma_Ponderacion=(
                "Peso",
                "sum"
            )
        )
        .assign(
            Prom_Pond_Diames_Diasem=lambda x:
                x["Suma_Esfuerzo_Pond"] /
                x["Suma_Ponderacion"]
        )
        .drop(
            columns=[
                "Suma_Esfuerzo_Pond",
                "Suma_Ponderacion"
            ]
        )
    )

    return df_prom_pond_diames_diasem

def promedio_pond_diames(
        df_esfuerzo_historico: pd.DataFrame,
        df_ponderaciones: pd.DataFrame) -> pd.DataFrame:

    df_prom_pond_diames=(
        df_esfuerzo_historico
        .loc[
            lambda x: x["Fecha"].dt.dayofweek != 6
        ]  # Quita domingos
        .sort_values(
            ["NUR", "Mes"],
            ascending=[True, False]
        )
        .assign(
            Mes_Pond=lambda x:
                x.groupby("NUR")["Mes"]
                .rank(method="dense", ascending=False)
                .astype(int)
        )
        .merge(
            df_ponderaciones,
            left_on="Mes_Pond",
            right_on="Mes",
            how="left"
        )
        .assign(
            Dia_Mes=lambda x:
                x["Fecha"].dt.day,

            Esfuerzo_Pond=lambda x:
                x["Esfuerzo"] * x["Peso"]
        )
        .groupby(
            [
                "NUR",
                "Dia_Mes"
            ],
            as_index=False
        )
        .agg(
            Suma_Esfuerzo_Pond=(
                "Esfuerzo_Pond",
                "sum"
            ),
            Suma_Ponderacion=(
                "Peso",
                "sum"
            )
        )
        .assign(
            Prom_Pond_Diames=lambda x:
                x["Suma_Esfuerzo_Pond"] /
                x["Suma_Ponderacion"]
        )
        .drop(
            columns=[
                "Suma_Esfuerzo_Pond",
                "Suma_Ponderacion"
            ]
        )
    )

    return df_prom_pond_diames


def promedio_pond_diasem(
        df_esfuerzo_historico: pd.DataFrame,
        df_ponderaciones: pd.DataFrame) -> pd.DataFrame:

    df_prom_pond_diasem = (
        df_esfuerzo_historico
        .loc[
            lambda x: x["Fecha"].dt.dayofweek != 6
        ]  # Quita domingos
        .sort_values(
            ["NUR", "Mes"],
            ascending=[True, False]
        )
        .assign(
            Mes_Pond=lambda x:
                x.groupby("NUR")["Mes"]
                .rank(method="dense", ascending=False)
                .astype(int)
        )
        .merge(
            df_ponderaciones,
            left_on="Mes_Pond",
            right_on="Mes",
            how="left"
        )
        .assign(
            Dia_Semana=lambda x:
                x["Fecha"].dt.dayofweek + 1,

            Esfuerzo_Pond=lambda x:
                x["Esfuerzo"] * x["Peso"]
        )
        .groupby(
            [
                "NUR",
                "Dia_Semana"
            ],
            as_index=False
        )
        .agg(
            Suma_Esfuerzo_Pond=(
                "Esfuerzo_Pond",
                "sum"
            ),
            Suma_Ponderacion=(
                "Peso",
                "sum"
            )
        )
        .assign(
            Prom_Pond_Diasemana=lambda x:
                x["Suma_Esfuerzo_Pond"] /
                x["Suma_Ponderacion"]
        )
        .drop(
            columns=[
                "Suma_Esfuerzo_Pond",
                "Suma_Ponderacion"
            ]
        )
    )

    return df_prom_pond_diasem