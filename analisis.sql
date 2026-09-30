
-- Proyecto Capstone: Análisis de datos de e-commerce con PostgreSQL
-- Archivo 2/2: analisis.sql  (limpieza + consultas de análisis)
-- Requisito: se debe ejecutar primero el archivo estructura.sql en capstone_project.

-- Pregunta de negocio general: ¿quiénes son nuestros mejores clientes,
-- cuándo vendemos más y qué productos conviene impulsar o revisar?


-- ETAPA 1: LIMPIEZA DE DATOS
-- Se hace ANTES de analizar: si entra basura, sale basura.

-- Verifico que los tipos de datos de las columnas críticas sean
-- los correctos (fechas como DATE, dinero como NUMERIC). Si una fecha
-- estuviera como texto no podríamos agrupar por mes ni restar fechas.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name IN ('fecha_pedido', 'fecha_registro', 'precio_unitario', 'precio_lista')
ORDER BY table_name, column_name;	

-- Mido cuántos nulos hay en las columnas críticas antes de decidir
-- qué hacer con ellos (no se limpia a ciegas).
SELECT
    COUNT(*)                                            AS total_pedidos,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL)     AS pedidos_sin_precio,
    COUNT(*) FILTER (WHERE fecha_pedido    IS NULL)     AS pedidos_sin_fecha
FROM pedidos;

--	Vista con los datos ya limpios. Decisiones tomadas:
--   * precio_unitario NULL -> se reemplaza por el precio de lista del
--     producto. Es la mejor estimación disponible: ignorar esas filas
--     subestimaría las ventas y los NULL en SUM() se saltearían sin aviso.
--   * fecha_pedido NULL -> NO se inventa una fecha (no hay dato que la
--     respalde). Se conserva el NULL y en el análisis mensual se
--     informa aparte como 'Sin fecha', para que se vea su peso real.
--   * categoria NULL -> se etiqueta 'Sin categoría' para no perder filas
--     en los agrupamientos.
CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    p.id                                                        AS pedido_id,
    p.cliente_id,
    p.producto_id,
    p.fecha_pedido,
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio_lista)                AS precio_final,
    p.cantidad * COALESCE(p.precio_unitario, pr.precio_lista)   AS total_pedido,
    COALESCE(pr.categoria, 'Sin categoría')                     AS categoria,
    (p.precio_unitario IS NULL)                                 AS precio_imputado
FROM pedidos  p
JOIN productos pr ON pr.id = p.producto_id;

--	Control de calidad: la vista debe tener la misma cantidad de filas
-- 	que la tabla original (un JOIN mal hecho podría duplicar o perder
-- 	pedidos) y ya no debe quedar ningún precio nulo.
SELECT
    (SELECT COUNT(*) FROM pedidos)                                AS filas_tabla_original,
    (SELECT COUNT(*) FROM pedidos_limpios)                        AS filas_vista_limpia,
    (SELECT COUNT(*) FROM pedidos_limpios WHERE precio_final IS NULL) AS precios_nulos_restantes;

-- ETAPA 2: ANÁLISIS

-- Consulta 1: Top 5 clientes por gasto total (JOIN + GROUP BY + SUM)
-- Por qué: identificar al segmento más valioso para campañas de
-- fidelización. Se muestra también la cantidad de pedidos para
-- distinguir al que compra seguido del que hizo pocas compras grandes.

SELECT
    c.id,
    c.nombre,
    COALESCE(c.ciudad, 'Sin ciudad')   AS ciudad,
    COUNT(pl.pedido_id)    	           AS cantidad_pedidos,
    SUM(pl.total_pedido)               AS gasto_total
FROM clientes c
JOIN pedidos_limpios pl ON pl.cliente_id = c.id
GROUP BY c.id, c.nombre, c.ciudad
ORDER BY gasto_total DESC
LIMIT 5;

-- Consulta 2: Ventas totales por mes (funciones de fecha + LAG)
-- LAG() compara cada mes con el anterior sin perder el detalle de fila.
-- Los pedidos sin fecha se informan en una fila aparte: no se pueden ubicar en el calendario, pero tampoco se deben ocultar.

WITH ventas_mensuales AS (
    SELECT
        DATE_TRUNC('month', fecha_pedido)::DATE AS mes,
        COUNT(*)                                AS pedidos,
        SUM(total_pedido)                       AS ventas
    FROM pedidos_limpios
    WHERE fecha_pedido IS NOT NULL
    GROUP BY DATE_TRUNC('month', fecha_pedido)
)
SELECT
    TO_CHAR(mes, 'YYYY-MM')  AS mes,
    pedidos,
    ventas,
    -- variación porcentual respecto del mes anterior
    ROUND(100.0 * (ventas - LAG(ventas) OVER (ORDER BY mes))
          / NULLIF(LAG(ventas) OVER (ORDER BY mes), 0), 1) AS variacion_pct
FROM ventas_mensuales

UNION ALL

SELECT
    COALESCE(TO_CHAR(fecha_pedido, 'YYYY-MM'), 'Sin fecha'),
    COUNT(*),
    SUM(total_pedido),
    NULL
FROM pedidos_limpios
WHERE fecha_pedido IS NULL
GROUP BY fecha_pedido

ORDER BY mes;  
-- 'Sin fecha' queda al final por orden alfabético

-- Consulta 3: Los 3 productos menos vendidos (LEFT JOIN + GROUP BY)
-- Por qué: son candidatos a liquidar, mejorar su publicación o sacar del catálogo. Se usa LEFT JOIN para no perder los productos con CERO
-- ventas (con un INNER JOIN justamente los peores no aparecerían).
-- El nombre desempata para que el resultado sea siempre el mismo.

SELECT
    pr.id,
    pr.nombre,
    COALESCE(pr.categoria, 'Sin categoría')  AS categoria,
    COALESCE(SUM(p.cantidad), 0)             AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos p ON p.producto_id = pr.id
GROUP BY pr.id, pr.nombre, pr.categoria
ORDER BY unidades_vendidas ASC, pr.nombre
LIMIT 3;

-- Consulta 4: Ranking de pedidos por categoría (Window Function RANK)
-- Por qué: ver cuáles son los pedidos de mayor valor dentro de cada
-- categoría, algo que un GROUP BY simple no permite porque colapsa las
-- filas. RANK() reinicia la numeración en cada categoría (PARTITION BY)
-- y deja empates con el mismo puesto. Se queda con el top 3 de cada una.

WITH ranking AS (
    SELECT
        categoria,
        pedido_id,
        total_pedido,
        RANK() OVER (
            PARTITION BY categoria
            ORDER BY total_pedido DESC
        ) AS puesto
    FROM pedidos_limpios
)
SELECT categoria, puesto, pedido_id, total_pedido
FROM ranking
WHERE puesto <= 3
ORDER BY categoria, puesto, pedido_id;
