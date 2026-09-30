-- Borro primero la vista de limpieza (creada en analisis.sql) porque
-- depende de las tablas, y luego las tablas en orden inverso a sus FK.
-- Así el script se puede re-ejecutar las veces que haga falta sin errores.

DROP VIEW  IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- Ahora creo las tablas: 

-- Tabla clientes

CREATE TABLE clientes (
    id              SERIAL       PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,  -- identifica al cliente aunque haya homónimos
    ciudad          VARCHAR(80),                   -- opcional: no todos la informan
    fecha_registro  DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- Tabla productos

CREATE TABLE productos (
    id            SERIAL        PRIMARY KEY,
    nombre        VARCHAR(100)  NOT NULL,
    categoria     VARCHAR(50),
    -- NUMERIC (no REAL) porque es dinero: evita errores de redondeo
    precio_lista  NUMERIC(10,2) NOT NULL CHECK (precio_lista >= 0)
);

-- Tabla pedidos (una fila = un producto comprado por un cliente)

-- fecha_pedido y precio_unitario admiten NULL a propósito: simulo los
-- datos "sucios" del mundo real que se limpia en analisis.sql.
CREATE TABLE pedidos (
    id               SERIAL        PRIMARY KEY,
    cliente_id       INTEGER       NOT NULL REFERENCES clientes(id),
    producto_id      INTEGER       NOT NULL REFERENCES productos(id),
    fecha_pedido     DATE,
    cantidad         INTEGER       NOT NULL CHECK (cantidad > 0),
    precio_unitario  NUMERIC(10,2) CHECK (precio_unitario >= 0)
);



-- Carga de datos (dataset propio: 16 clientes, 12 productos, 90 pedidos)

INSERT INTO clientes (nombre, email, ciudad, fecha_registro) VALUES
  ('Lucía Fernández', 'lucia.fernandez@mail.com', 'Neuquén', '2024-01-10'),
  ('Martín Gómez', 'martin.gomez@mail.com', 'Buenos Aires', '2024-01-22'),
  ('Sofía Rodríguez', 'sofia.rodriguez@mail.com', 'Córdoba', '2024-02-03'),
  ('Julián Pérez', 'julian.perez@mail.com', 'Rosario', '2024-02-14'),
  ('Valentina López', 'valentina.lopez@mail.com', 'Neuquén', '2024-03-01'),
  ('Facundo Díaz', 'facundo.diaz@mail.com', 'Mendoza', '2024-03-18'),
  ('Camila Torres', 'camila.torres@mail.com', 'Buenos Aires', '2024-04-05'),
  ('Nicolás Ruiz', 'nicolas.ruiz@mail.com', 'Bariloche', '2024-04-20'),
  ('Agustina Sosa', 'agustina.sosa@mail.com', 'Córdoba', '2024-05-09'),
  ('Tomás Álvarez', 'tomas.alvarez@mail.com', 'Neuquén', '2024-05-27'),
  ('Micaela Romero', 'micaela.romero@mail.com', 'Rosario', '2024-06-11'),
  ('Bruno Acosta', 'bruno.acosta@mail.com', 'Mendoza', '2024-06-25'),
  ('Carolina Medina', 'carolina.medina@mail.com', 'Buenos Aires', '2024-06-26'),
  ('Ignacio Herrera', 'ignacio.herrera@mail.com', 'Bariloche', '2024-06-27'),
  ('Florencia Silva', 'florencia.silva@mail.com', NULL, '2024-06-28'),
  ('Santiago Castro', 'santiago.castro@mail.com', 'Neuquén', '2024-06-29');

INSERT INTO productos (nombre, categoria, precio_lista) VALUES
  ('Notebook 15"', 'Computación', 950.00),
  ('Mouse inalámbrico', 'Computación', 25.50),
  ('Teclado mecánico', 'Computación', 80.00),
  ('Monitor 24"', 'Computación', 210.00),
  ('Auriculares Bluetooth', 'Audio', 60.00),
  ('Parlante portátil', 'Audio', 45.00),
  ('Micrófono USB', 'Audio', 70.00),
  ('Smartwatch', 'Wearables', 130.00),
  ('Pulsera fitness', 'Wearables', 35.00),
  ('Cargador rápido USB-C', 'Accesorios', 18.00),
  ('Funda para notebook', 'Accesorios', 22.00),
  ('Soporte para monitor', 'Accesorios', 40.00);

INSERT INTO pedidos (cliente_id, producto_id, fecha_pedido, cantidad, precio_unitario) VALUES
  (11, 4, '2024-07-02', 1, 187.91),
  (16, 10, '2024-07-03', 1, 17.14),
  (1, 5, '2024-07-18', 2, 52.16),
  (10, 8, '2024-07-19', 2, NULL),
  (3, 5, '2024-07-20', 1, 51.46),
  (3, 3, '2024-07-21', 1, 72.56),
  (16, 5, '2024-07-21', 1, 60.0),
  (16, 10, '2024-07-24', 2, 15.75),
  (3, 3, '2024-07-27', 4, 79.69),
  (10, 1, '2024-07-28', 1, 838.68),
  (13, 1, '2024-08-10', 1, 855.99),
  (7, 10, '2024-08-11', 2, 17.11),
  (10, 5, '2024-08-13', 3, 55.64),
  (1, 11, '2024-08-15', 3, 18.83),
  (1, 10, '2024-08-18', 4, 15.3),
  (10, 6, '2024-08-19', 4, 42.82),
  (9, 10, '2024-08-22', 3, 16.66),
  (4, 8, '2024-08-24', 4, 115.24),
  (13, 10, '2024-08-28', 3, 16.38),
  (10, 11, '2024-08-30', 2, 21.61),
  (9, 3, '2024-08-30', 2, 77.68),
  (5, 2, '2024-09-01', 2, 23.35),
  (7, 3, '2024-09-02', 3, 77.19),
  (7, 11, '2024-09-06', 2, 20.38),
  (7, 6, '2024-09-06', 4, 44.76),
  (4, 5, '2024-09-08', 2, 57.16),
  (7, 6, '2024-09-09', 3, NULL),
  (10, 4, '2024-09-10', 1, 208.96),
  (10, 2, '2024-09-15', 4, 22.92),
  (15, 6, '2024-09-16', 1, 40.3),
  (10, 3, '2024-09-19', 1, 68.11),
  (8, 4, '2024-09-19', 1, 209.5),
  (1, 10, '2024-09-24', 4, 17.47),
  (5, 5, '2024-09-25', 4, 53.5),
  (5, 7, '2024-10-01', 1, 59.98),
  (5, 5, '2024-10-08', 4, 57.52),
  (7, 2, '2024-10-11', 2, 23.12),
  (5, 7, '2024-10-11', 3, 69.36),
  (6, 10, '2024-10-16', 2, NULL),
  (16, 3, '2024-10-25', 4, 69.86),
  (9, 10, '2024-10-26', 4, 15.51),
  (3, 10, '2024-10-26', 2, 15.9),
  (2, 1, '2024-10-30', 1, 917.01),
  (1, 6, '2024-11-06', 2, 38.63),
  (5, 7, '2024-11-08', 2, 68.31),
  (1, 10, '2024-11-10', 4, NULL),
  (11, 6, '2024-11-13', 3, 41.55),
  (13, 10, '2024-11-13', 1, 17.62),
  (1, 5, '2024-11-16', 1, 52.86),
  (9, 6, '2024-11-17', 3, 39.14),
  (6, 3, '2024-11-18', 4, NULL),
  (10, 5, '2024-11-18', 2, 57.69),
  (1, 4, '2024-11-19', 1, 208.33),
  (7, 2, '2024-11-19', 2, 23.93),
  (12, 8, '2024-11-21', 4, 122.45),
  (1, 10, '2024-11-23', 3, 15.87),
  (9, 1, '2024-11-24', 1, 822.11),
  (1, 10, '2024-11-24', 2, 16.04),
  (5, 11, '2024-11-26', 1, 21.17),
  (16, 6, '2024-11-26', 1, 41.08),
  (10, 6, '2024-11-27', 4, 40.69),
  (6, 10, '2024-11-27', 1, 17.61),
  (1, 9, '2024-11-28', 3, 30.12),
  (12, 8, '2024-11-28', 1, 119.4),
  (10, 6, '2024-11-29', 1, 38.88),
  (15, 6, '2024-12-03', 3, 42.46),
  (3, 10, '2024-12-03', 4, 16.49),
  (4, 4, '2024-12-03', 1, NULL),
  (2, 11, '2024-12-04', 3, 21.5),
  (10, 2, '2024-12-06', 1, 22.67),
  (13, 10, '2024-12-07', 4, 16.9),
  (3, 6, '2024-12-08', 4, 42.23),
  (8, 5, '2024-12-08', 3, 54.56),
  (1, 6, '2024-12-11', 2, 39.28),
  (7, 10, '2024-12-12', 3, NULL),
  (7, 3, '2024-12-12', 3, 73.22),
  (7, 5, '2024-12-12', 4, 54.7),
  (15, 10, '2024-12-13', 3, NULL),
  (13, 1, '2024-12-15', 1, 821.52),
  (7, 3, '2024-12-15', 3, 79.18),
  (7, 10, '2024-12-16', 4, 15.96),
  (5, 2, '2024-12-18', 4, 23.82),
  (2, 8, '2024-12-20', 4, 120.82),
  (1, 11, '2024-12-24', 1, 21.45),
  (8, 2, '2024-12-26', 1, 25.11),
  (4, 10, '2024-12-27', 3, 15.42),
  (16, 2, NULL, 1, 22.26),
  (7, 10, NULL, 2, 16.39),
  (5, 10, NULL, 2, 17.21),
  (9, 2, NULL, 2, 23.45);

  -- Verificación rápida de la carga
SELECT 'clientes'  AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'pedidos',   COUNT(*) FROM pedidos;
