# Solución

```bash
# 🐳
export EJEMPLOS=/opt/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
export BASE=/tmp/ejercicio
hdfs dfs -mkdir -p $BASE
hadoop jar $EJEMPLOS teragen 20000 $BASE/in
hadoop jar $EJEMPLOS terasort -Dmapreduce.job.reduces=2 $BASE/in $BASE/out
hadoop jar $EJEMPLOS teravalidate $BASE/out $BASE/report
hdfs dfs -cat $BASE/report/part-r-00000
hdfs dfs -ls $BASE/out
od -An -tx1 $BASE/out/_partition.lst
# Para el inciso e):
hadoop jar $EJEMPLOS teravalidate $BASE/in $BASE/report-malo
hdfs dfs -cat $BASE/report-malo/part-r-00000 | head -n 5
```

- **a)** 2,000,000 bytes: 20,000 filas × 100 bytes.
- **b)** 2 archivos (`part-r-00000` y `part-r-00001`), uno por reducer, de tamaño parecido (~1 MB).
- **c)** 11 bytes aprox.: con 2 reducers hace falta **1 punto de corte** (una clave de 10 bytes + un salto de línea). Ese corte es la primera clave de `part-r-00001`. Con 3 reducers fueron 22 bytes (2 cortes).
- **d)** Solo una línea `checksum <número>` y ninguna línea `error`.
- **e)** Aparecen líneas `error misorder ...`, porque las claves de entrada están desordenadas. El `checksum` **no cambia**: prueba que son los mismos registros, no que estén ordenados. El orden lo prueban las líneas `error`.

**Idea clave:** `terasort` muestrea las claves, crea rangos (`_partition.lst`) y el `TotalOrderPartitioner` manda cada rango a un reducer. Como los rangos son contiguos y crecientes, concatenar `part-r-00000`, `part-r-00001`... da un orden **global**.
