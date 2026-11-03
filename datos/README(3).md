# Datos

Este ejemplo **no necesita archivos de entrada**: `teragen` los genera.
Cada fila mide 100 bytes (10 de clave + 90 de valor), así que:

| Filas | Tamaño |
|---|---|
| 100,000 | ≈ 10 MB |
| 1,000,000 | ≈ 100 MB |

Comando: `hadoop jar $EJEMPLOS teragen 100000 /tmp/equipo6/tera-in`
