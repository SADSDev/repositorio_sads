"""
Este algortimo toma una columna de datos decimales, divide parte entera y parte decimal,
ordena de mayor a menor los enteros y asigna el valor decimal como entero a los primeros lugares
conservando el total de la columna
"""
#----------------------------------------------------------------------------
#LIBRERIAS
#----------------------------------------------------------------------------
import numpy as np
import pandas as pd


#----------------------------------------------------------------------------
# PROCESO
#----------------------------------------------------------------------------
def redondear_conservando_total(
    df: pd.DataFrame,
    columna: str,
    total: int | None = None
) -> pd.Series:
    """
    Redondea una columna de valores decimales a enteros conservando
    exactamente el total.

    Si 'total' es None, se utiliza round(sum(columna)).
    """

    resultado = df[columna].copy()

    enteros = np.floor(resultado).astype(int)
    decimales = resultado - enteros

    if total is None:
        total = int(round(resultado.sum()))

    faltantes = int(total - enteros.sum())

    if faltantes > 0:
        indices = decimales.nlargest(faltantes).index
        enteros.loc[indices] += 1

    elif faltantes < 0:
        indices = decimales.nsmallest(-faltantes).index
        enteros.loc[indices] -= 1

    return enteros