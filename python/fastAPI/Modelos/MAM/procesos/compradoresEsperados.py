# Obtiene los clientes compradores esperados por ruta.

#-----------------------------------
# LIBRERIAS
#-----------------------------------
import pandas as pd


#-----------------------------------
# PROCESO DE COMPRADORES ESPERADOS
#-----------------------------------
def compradores_esperados(
    df_clientes_activos: pd.DataFrame,
    df_eficiencia_ponderada: pd.DataFrame
) -> pd.DataFrame:

    df_compradores_esperados = (
        df_clientes_activos
        .merge(
            df_eficiencia_ponderada,
            on="NUR",
            how="left"
        )
        .assign(
            clientes_esperados=lambda x:
            x["activos"] * x["eficiencia_ponderada"]
        )
        [["NUR", "clientes_esperados"]]
    )

    return df_compradores_esperados