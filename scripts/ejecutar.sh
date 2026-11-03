#!/bin/bash
# 🐳 Ejecutar DENTRO del contenedor como usuario hadoop
# Uso: ./ejecutar.sh [FILAS] [REDUCERS]     (por defecto: 100000 filas, 3 reducers)
set -e
EJEMPLOS=${HADOOP_HOME:-/opt/hadoop-3.3.6}/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
BASE=/tmp/equipo6
SALIDA=/tmp/salida-equipo6
FILAS=${1:-100000}
REDUCERS=${2:-3}

mkdir -p "$SALIDA"
hdfs dfs -mkdir -p $BASE
hdfs dfs -rm -r -f $BASE/tera-in $BASE/tera-out $BASE/tera-report

echo "== 1/3 teragen ($FILAS filas) =="
hadoop jar $EJEMPLOS teragen $FILAS $BASE/tera-in

echo "== 2/3 terasort ($REDUCERS reducers) =="
hadoop jar $EJEMPLOS terasort -Dmapreduce.job.reduces=$REDUCERS $BASE/tera-in $BASE/tera-out

echo "== 3/3 teravalidate =="
hadoop jar $EJEMPLOS teravalidate $BASE/tera-out $BASE/tera-report

echo "== Reporte (solo debe haber una línea 'checksum') =="
hdfs dfs -cat $BASE/tera-report/part-r-00000 | tee "$SALIDA/reporte-teravalidate.txt"

echo "== Primeras claves SIN ordenar (tera-in) =="
head -c 500 $BASE/tera-in/part-m-00000 | od -An -tx1 -w100 | cut -c1-30 | tee "$SALIDA/primeras-claves-desordenadas.txt"

echo "== Primeras claves ordenadas (tera-out) =="
head -c 500 $BASE/tera-out/part-r-00000 | od -An -tx1 -w100 | cut -c1-30 | tee "$SALIDA/primeras-claves-ordenadas.txt"

echo "== Primera clave de cada archivo de salida =="
for f in $BASE/tera-out/part-r-*; do
  echo "$f"; head -c 10 "$f" | od -An -tx1
done | tee "$SALIDA/rangos.txt"

echo "Listo. Resultados guardados en $SALIDA"
