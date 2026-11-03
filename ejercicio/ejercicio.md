# Mini ejercicio: ordena y valida

Con el contenedor de la práctica y el usuario `hadoop`:

1. Define las variables:
   ```bash
   export EJEMPLOS=/opt/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
   export BASE=/tmp/ejercicio
   ```
2. Genera **20,000 filas** con `teragen` en `$BASE/in`.
3. Ordénalas con `terasort` usando **2 reducers**, salida en `$BASE/out`.
4. Valida la salida con `teravalidate`.

Responde:

- a) ¿Cuántos bytes pesa `$BASE/in/part-m-00000`? ¿Por qué?
- b) ¿Cuántos archivos `part-r-` obtienes?
- c) ¿Cuánto pesa `_partition.lst` y qué contiene?
- d) ¿Qué dice el reporte de `teravalidate`?
- e) ¿Qué pasa si validas `$BASE/in` en lugar de `$BASE/out`? ¿Cambia el `checksum`?
