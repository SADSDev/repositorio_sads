# Obtiene el volumen esperado de marcas estratégicas por ruta.

#-----------------------------------
# LIBRERIAS
#-----------------------------------
import pandas as pd


#-----------------------------------
# PROCESO DE VOLUMEN ME ESPERADO
#-----------------------------------
def volumen_me_esperado(
    df_penetracion_ponderada: pd.DataFrame,
    df_ventaprom_ponderada: pd.DataFrame,
    df_clientes_activos: pd.DataFrame
) -> pd.DataFrame:

    df_volumen_me_esperado = (
        df_penetracion_ponderada
        .merge(
            df_ventaprom_ponderada,
            on="NUR",
            how="left"
        )
        .merge(
            df_clientes_activos,
            on="NUR",
            how="left"
        )
        .assign(
            vol_me_esperado=lambda x:
            x["activos"] * x["pen_ponderada"] * x["mu_ponderada"]
        )
        [["NUR", "vol_me_esperado"]]
    )

    return df_volumen_me_esperado