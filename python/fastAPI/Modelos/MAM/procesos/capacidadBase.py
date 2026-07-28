# Obtiene la capacidad base operativa por ruta.

#-----------------------------------
# LIBRERIAS
#-----------------------------------
import pandas as pd


#-----------------------------------
# PROCESO DE CAPACIDAD BASE
#-----------------------------------
def capacidad_base(
    df_volumen_esperado: pd.DataFrame,
    df_compradores_esperados: pd.DataFrame,
    df_clientes_activos: pd.DataFrame,
    alpha: float
) -> pd.DataFrame:

    df_capacidad_base = (
        df_volumen_esperado
        .merge(
            df_compradores_esperados,
            on="NUR",
            how="left"
        )
        .merge(
            df_clientes_activos,
            on="NUR",
            how="left"
        )
        .assign(
            capacidad_base=lambda x:
            x["volumen_esperado"]
            * (
                x["clientes_esperados"] ** (1 - alpha)
                * x["activos"] ** alpha
            )
        )
        [["NUR", "capacidad_base"]]
    )

    return df_capacidad_base