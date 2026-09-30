# Proyecto Capstone · Análisis de ventas de un e-commerce con PostgreSQL

Análisis exploratorio (EDA) de una tienda online de tecnología: limpiar los datos, responder preguntas de negocio con SQL e interpretar qué dicen los números.

## 1. Problema de negocio

Una tienda de electrónica quiere decidir **dónde poner su esfuerzo comercial**. Las preguntas que guían el análisis:

1. ¿Quiénes son los clientes que más gastan? ¿Compran seguido o hacen pocas compras grandes?
2. ¿En qué meses se concentran las ventas?
3. ¿Qué productos casi no se venden y hay que revisar?
4. ¿Qué categorías y qué pedidos pesan más en la facturación?

## 2. Dataset

Dataset propio (generado para este trabajo, no son ventas reales), con 3 tablas:

| Tabla         | Filas | Contenido |
|---            |---    |---        |
| `clientes`    | 16    | nombre, email, ciudad, fecha de registro |
| `productos`   | 12    | nombre, categoría (Computación, Audio, Wearables, Accesorios), precio de lista |
| `pedidos`     | 90    | cliente, producto, fecha, cantidad, precio unitario (jul–dic 2024) |

Se incluyeron **nulos a propósito** en columnas críticas para practicar la limpieza: 8 pedidos sin `precio_unitario` y 4 sin `fecha_pedido`.

## 3. Cómo ejecutar el código

Requisitos: PostgreSQL 14 o superior.

Desde pgAdmin o DBeaver: crear la base `capstone_project`, abrir cada archivo en el editor de consultas y ejecutarlo en ese orden. Ambos scripts se pueden re-ejecutar sin errores.

Archivos del repositorio:

- `estructura.sql`: creación de tablas (con PK, FK, `CHECK`) e inserción de datos.
- `analisis.sql`: limpieza y 4 consultas de análisis comentadas.
- `README.md`: este documento.

## 4. Limpieza de datos

Tenemos 8 pedidos con `precio_unitario` NULL. Lo cambié al precio de lista con `COALESCE(precio_unitario, precio_lista)`, que es la mejor estimación disponible. Si los ignoro, los salteo y las ventas quedan subestimadas.

Tenemos 4 pedidos con `fecha_pedido` NULL. No invento la fecha, sino que la informo como `'Sin fecha'`, porque no tengo el dato para respaldar las fechas faltantes. Las muestro aparte para que se vea su peso sobre el total (1% de las ventas).

Para las columnas Categoría o Ciudad NULL usé `COALESCE(..., 'Sin categoría' / 'Sin ciudad')`, para no perder filas en los agrupamientos.

Además, se verificó que las fechas sean `DATE` y el dinero `NUMERIC`, y que la vista limpia conserve las 90 filas originales.

**Efecto de la imputación:** los 8 precios reemplazados suman USD 1.141 de un total de USD 14.186,81 (8%). Es una diferencia acotada, pero conviene tenerla presente al leer los resultados.

## 5. Hallazgos e interpretación

Ventas totales del período: **USD 14.186,81** en 90 pedidos.

### 5.1 Pocos clientes concentran más de la mitad de la facturación

El top 5 de clientes explica **USD 8.260 (58%)** de las ventas, siendo solo 5 de los 16 clientes.

| # | Cliente           | Pedidos   | Gasto total   |
|---|---                |---        |---            |
| 1 | Tomás Álvarez     | 12        | USD 2.188,54  |
| 2 | Carolina Medina   | 5         | USD 1.811,87  |
| 3 | Camila Torres     | 13        | USD 1.541,31  |
| 4 | Martín Gómez      | 3         | USD 1.464,79  |
| 5 | Agustina Sosa     | 6         | USD 1.253,81  |

Lo interesante es que **no todos gastan de la misma forma**. Camila, junto con Lucía Fernández, es quien más veces compra (13 pedidos cada una), pero con tickets chicos, mientras que Carolina y Martín gastan mucho con pocos pedidos (Martín, USD 1.464 en solo 3), lo que sugiere compras de productos caros. Son perfiles distintos y piden acciones distintas:

- **Tomás y Camila** (compradores frecuentes): programa de fidelización o descuentos por recurrencia.
- **Martín y Carolina** (pocas compras, tickets altos): recordatorios y ofertas de complementos para que vuelvan a comprar.


### 5.2 Noviembre y diciembre concentran casi la mitad de las ventas

Noviembre y diciembre representan el **46% de las ventas con fecha** del semestre. Noviembre creció un **70%** respecto de octubre (de USD 1.871 a USD 3.173) y diciembre lo superó levemente (USD 3.310, +4%). También hay una caída en septiembre (-22%) que vale la pena investigar.

Implicancia: el stock y las campañas deberían prepararse antes de noviembre. Con un solo semestre de datos no se puede afirmar que sea estacionalidad anual; habría que comparar contra otros años para confirmarlo.

### 5.3 Dos productos casi no rotan, pero hay que leer el dato con cuidado

Los 3 menos vendidos por unidades son:

| Producto              | Categoría     | Unidades  |
|---                    |---            |---        |
| Soporte para monitor  | Accesorios    | 0         |
| Pulsera fitness       | Wearables     | 3         |
| Monitor 24"           | Computación   | 5         |

El **Soporte para monitor no vendió ninguna unidad**. Es el candidato más claro a liquidar. La Pulsera fitness es el segundo caso a revisar.

El Monitor 24" empata con el Notebook 15" en 5 unidades (el orden alfabético definió quién entra al top 3). Pero son productos **caros**: vender pocas unidades no significa vender poco dinero, así que no corresponde tratarlos como un problema sin mirar antes su facturación.

### 5.4 Computación es la categoría que sostiene el negocio

| Categoría     | Ventas        | % del total   | Unidades  |
|---            |---            |---            |---        |
| Computación   | USD 7.627,71  | 54%           | 54        |
| Audio         | USD 3.359,03  | 24%           | 68        |
| Wearables     | USD 1.903,80  | 13%           | 18        |
| Accesorios    | USD 1.296,27  | 9%            | 75        |

Accesorios es la categoría con **más unidades vendidas (75) pero solo el 9% de la facturación**, porque son artículos baratos. Computación hace lo contrario. El ranking con `RANK()` lo confirma: los pedidos más grandes de Computación (hasta USD 917) son de un orden de magnitud distinto a los de Accesorios (máximo USD 72).

Una oportunidad concreta es vender accesorios como complemento en el mismo pedido de una compra de Computación (el ticket sube sin buscar clientes nuevos).

## 6. Conclusiones y próximos pasos

1. **Cuidar a los clientes que ya compran**: el 58% de las ventas depende de 5 personas, lo cual es una fortaleza pero también un riesgo.
2. **Preparar la temporada alta**: noviembre y diciembre son casi la mitad de la facturación del período.
3. **Revisar el catálogo**: sacar o relanzar Soporte para monitor y Pulsera fitness.
4. **Impulsar la venta cruzada**: accesorios junto con productos de Computación.

Limitaciones: el dataset es chico y sintético, cubre solo 6 meses, y el 8% del valor de ventas se apoya en precios imputados. Para llevar estas conclusiones a decisiones reales habría que repetir el análisis con datos reales y un período más largo.

## 7. Técnicas de SQL utilizadas

`JOIN` / `LEFT JOIN` · `GROUP BY` + `SUM` / `COUNT` · `COALESCE` / `NULLIF` · funciones de fecha (`DATE_TRUNC`, `TO_CHAR`) · CTEs (`WITH`) · funciones de ventana (`RANK`, `LAG`) · vistas · `information_schema`.

