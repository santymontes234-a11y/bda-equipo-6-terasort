# bda-equipo-6-terasort: la suite TeraSort en Hadoop 3.3.6



Convención: 💻 = se escribe en la terminal de **tu computadora**. 🐳 = se escribe **dentro del contenedor**.

## 1. Descripción y caso de uso

La suite TeraSort son tres programas de los ejemplos de Hadoop que se usan juntos:

| Paso | Qué hace |
|---|---|
| `teragen` | Genera filas aleatorias de 100 bytes (10 de clave + 90 de valor). Solo tiene fase Map. |
| `terasort` | Ordena todas las filas por clave. |
| `teravalidate` | Comprueba que la salida esté ordenada globalmente. |

**Caso real:** es el benchmark clásico (Sort Benchmark) para medir qué tan rápido un clúster Hadoop mueve y ordena datos; sirve para probar discos, red y configuración. Curiosidad: la primera clave generada, `4a 69 6d 47 72 61 79 52 49 50`, dice en ASCII `JimGrayRIP`.

## 2. Requisitos

- Contenedor `hadoop` de la práctica con Hadoop 3.3.6 funcionando (modo local, `fs.defaultFS = file:///`).
- ~1 GB libres en el disco del contenedor para el experimento más grande.

## 3. Paso a paso

### 3.1 Entrar al contenedor

```bash
# 💻 Ver que existe y su estado
docker ps -a
```

```bash
# 💻 Entrar (entras como root)
docker start -ai hadoop
```

```bash
# 🐳 Cambiar al usuario de Hadoop
su - hadoop
```

### 3.2 Preparar variables y carpeta

```bash
# 🐳 Comprobar versión (debe decir 3.3.6)
hadoop version
```

```bash
# 🐳 Variables y carpeta de trabajo
export EJEMPLOS=/opt/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
export BASE=/tmp/equipo6
ls $EJEMPLOS
hdfs dfs -mkdir -p $BASE
hdfs dfs -rm -r -f $BASE/tera-in $BASE/tera-out $BASE/tera-report
```

### 3.3 teragen

```bash
# 🐳 Generar 100,000 filas (≈ 10 MB)
hadoop jar $EJEMPLOS teragen 100000 $BASE/tera-in
hdfs dfs -ls $BASE/tera-in
```

### 3.4 terasort

```bash
# 🐳 Ordenar con 1 reducer
hadoop jar $EJEMPLOS terasort -Dmapreduce.job.reduces=1 $BASE/tera-in $BASE/tera-out
hdfs dfs -ls $BASE/tera-out
```

```bash
# 🐳 Comparar claves antes y después (primeros 10 bytes de 5 registros)
head -c 500 $BASE/tera-in/part-m-00000 | od -An -tx1 -w100 | cut -c1-30
head -c 500 $BASE/tera-out/part-r-00000 | od -An -tx1 -w100 | cut -c1-30
```

### 3.5 teravalidate

```bash
# 🐳
hadoop jar $EJEMPLOS teravalidate $BASE/tera-out $BASE/tera-report
hdfs dfs -cat $BASE/tera-report/part-r-00000
```

### 3.6 Experimento A: 3 reducers

```bash
# 🐳
hdfs dfs -rm -r -f $BASE/tera-out3 $BASE/tera-report3
hadoop jar $EJEMPLOS terasort -Dmapreduce.job.reduces=3 $BASE/tera-in $BASE/tera-out3
hdfs dfs -ls $BASE/tera-out3
hadoop jar $EJEMPLOS teravalidate $BASE/tera-out3 $BASE/tera-report3
hdfs dfs -cat $BASE/tera-report3/part-r-00000
```

```bash
# 🐳 Primera clave de cada archivo de salida (deben ser crecientes)
for f in $BASE/tera-out3/part-r-0000*; do echo "$f"; head -c 10 $f | od -An -tx1; done
od -An -tx1 $BASE/tera-out3/_partition.lst
```

### 3.7 Experimento B: hacer fallar la validación

```bash
# 🐳 Validar los datos SIN ordenar
hdfs dfs -rm -r -f $BASE/tera-report-malo
hadoop jar $EJEMPLOS teravalidate $BASE/tera-in $BASE/tera-report-malo 2>&1 | tail -n 5
hdfs dfs -cat $BASE/tera-report-malo/part-r-00000 | head -n 5
```

### 3.8 Todo de una vez

```bash
# 💻 Copiar el script al contenedor y darle permisos
docker cp scripts/ejecutar.sh hadoop:/tmp/ejecutar.sh
docker exec -u root hadoop chown hadoop:hadoop /tmp/ejecutar.sh
docker exec -u root hadoop chmod +x /tmp/ejecutar.sh
```

```bash
# 🐳 Argumentos opcionales: filas y reducers
/tmp/ejecutar.sh 100000 3
```

### 3.9 Sacar resultados a tu computadora

```bash
# 💻
docker cp hadoop:/tmp/salida-equipo6/. resultados/
```

## 4. Resultado esperado

- `teragen`: un archivo `part-m-00000` de **10,000,000 bytes**.
- `terasort` (1 reducer): un `part-r-00000` de 10,000,000 bytes y `_partition.lst` de **0 bytes**. Claves de entrada sin orden (`4a`, `95`, `45`...) y de salida ascendentes (`00 00`, `00 01`, `00 04`...).
- `teravalidate`: una sola línea `checksum c327a1c42c28` y **ninguna** línea `error` (el checksum depende de los datos generados; teragen es aleatorio, pero con la misma semilla de la corrida original coincide entre 1 y 3 reducers).
- 3 reducers: tres archivos de ≈ 3.33 MB, `_partition.lst` de **22 bytes** (2 claves de corte de 10 bytes + 2 saltos de línea) y primeras claves `00 00...`, `55 0e...`, `aa 23...`.
- Validar la entrada: líneas `error misorder in part-m-00000 between ...`.

Tiempos medidos (modo local, 3 reducers):

| Filas | Tamaño | teragen | terasort | teravalidate |
|---|---|---|---|---|
| 100,000 | ≈ 10 MB | 1.9 s | 2.3 s | 1.9 s |
| 500,000 | ≈ 50 MB | 1.9 s | 4.3 s | 1.9 s |
| 1,000,000 | ≈ 100 MB | 1.9 s | 5.2 s | 2.0 s |
| 3,000,000 | ≈ 300 MB | 2.9 s | 9.3 s | 3.0 s |

`teragen` y `teravalidate` casi no cambian (domina el arranque del job); `terasort` sí crece porque hace muestreo, shuffle y ordenamiento. Al ser modo local, **no** mide escalabilidad de un clúster real.

## 5. Cómo funcionan Map y Reduce

**teragen (solo Map):** cada mapper genera su bloque de filas aleatorias y las escribe directo. No hay Reduce.

**terasort:**
1. *Muestreo:* se leen claves de la entrada y se calculan N-1 puntos de corte para N reducers (se guardan en `_partition.lst`).
2. *Map:* lee cada fila y emite `(clave, valor)` sin transformarla.
3. *Partición:* el `TotalOrderPartitioner` manda cada clave al reducer de su rango (reducer 0: claves menores que el corte 1, etc.).
4. *Shuffle/sort:* Hadoop ordena las claves de cada reducer.
5. *Reduce:* escribe las filas ya ordenadas. Como los rangos son contiguos y crecientes, `part-r-00000`, `00001`... forman un orden **global**.

```
Entrada ──► Map ──► Partitioner (rangos) ──► Reducer 0 [00..55) ──► part-r-00000
(sin orden)         usa _partition.lst  ──► Reducer 1 [55..aa) ──► part-r-00001
                                        ──► Reducer 2 [aa..ff] ──► part-r-00002
```

**teravalidate:** el Map revisa que las claves dentro de cada archivo estén en orden y emite la primera y última de cada archivo; el Reduce comprueba que no se traslapen entre archivos consecutivos. Emite `error` si algo falla y siempre un `checksum` de los registros (el checksum prueba que son los mismos registros, no que estén ordenados).

## 6. Errores comunes

| Error | Causa | Solución |
|---|---|---|
| `FileAlreadyExistsException: Output directory ... already exists` | Hadoop no sobrescribe carpetas de salida | `hdfs dfs -rm -r -f <carpeta>` antes de repetir |
| `No such file or directory` al guardar en `/tmp/salida-equipo6` | La carpeta no existía | `mkdir -p /tmp/salida-equipo6` |
| `docker: command not found` | Se pegó un comando 💻 dentro del contenedor | Abrir una terminal nueva en tu computadora |
| `Unable to write to output stream` con `head` | `head` cierra el pipe antes de que `cat` termine | Es normal, se puede ignorar |
| Texto revuelto en archivos de salida | Se pegaron comandos mientras corría un job | Esperar a que termine el job antes de pegar |

## 7. Estructura

```
README.md · datos/ · scripts/ejecutar.sh · resultados/ · ejercicio/ · presentacion.pdf
```
