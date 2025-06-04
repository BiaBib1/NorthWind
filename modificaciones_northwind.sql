

/* Se ha imaginado una empresa que utiliza la base de datos Northwind, dividida en tres departamentos:
 ventas, almacén y contabilidad. Por lo tanto, se han creado dos vistas para cada departamento asì que se pueden realizar consultas específicas.
 Ademas se ha creado tambien un trigger para actualizar automáticamente la disponibilidad del inventario después de un pedido.
 Se modifica la tabla us_states para relacionarla con la tabla region.
 Se añade una columna JSONB a la tabla products para almacenar características adicionales de los productos.
Se crea un índice en la columna JSONB para mejorar el rendimiento de las consultas.
Se crea un dump de la base de datos Northwind modificada
Se explica cómo clonar el repositorio NorthWind modificado de GitHub. */

-- VISTAS --

-- 1. Departamento Ventas

-- Muestra para cada cliente: nombre, país, total de pedidos y suma total de ventas.
CREATE VIEW vw_sales_summary_by_customer AS
SELECT c.customer_id, c.company_name, c.country,
COUNT(o.order_id) AS Total_Orders, SUM(od.unit_price * od.quantity) AS Total_Sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name, c.country;

-- Productos más vendidos por cantidad.
CREATE VIEW vw_top_selling_products AS
SELECT p.product_id, p.product_name,
SUM(od.quantity) AS Total_Quantity_Sold
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY Total_Quantity_Sold DESC;

-- 2. Departamento Almacén

-- Estado del inventario: productos por debajo del stock mínimo.
CREATE VIEW vw_inventory_status AS
SELECT product_id, product_name, units_in_stock, reorder_level,
  CASE
    WHEN units_in_stock < reorder_level THEN 'LOW STOCK'
    ELSE 'OK'
  END AS stock_status
FROM products;

-- Pedidos que aún no han sido enviados.
CREATE VIEW vw_pending_orders AS
SELECT o.order_id, c.customer_id, c.company_name,
o.order_date, o.shipped_date, o.ship_via, o.freight, o.ship_name,
o.ship_address, o.ship_city, o.ship_region, o.ship_postal_code, o.ship_country    
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.shipped_date IS NULL;

--3. Departamento Contabilidad

-- Facturas por cliente: muestra el total de las facturas para cada cliente
CREATE VIEW vw_invoices_by_customer AS
SELECT c.customer_id, c.company_name,
SUM(od.unit_price * od.quantity) AS Total_Invoice
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name;

-- Ventas por empleado
CREATE VIEW vw_employee_sales AS
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS Employee_Name,
COUNT(o.order_id) AS Total_Orders,
SUM(od.unit_price * od.quantity * (1 - od.discount)) AS Total_Sales
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY e.employee_id, employee_name;


-- TRIGGER

--1. Actualiza automáticamente la disponibilidad del almacén después de un pedido.
CREATE OR REPLACE FUNCTION update_stock_after_order()
RETURNS TRIGGER AS $$
BEGIN
  -- Actualiza las unidades en stock del producto después de un pedido
  UPDATE products
  SET units_in_stock = units_in_stock - NEW.quantity
  WHERE product_id = NEW.product_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_update_stock_after_order
AFTER INSERT ON order_details
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_order();


-- MODIFICA TABLAS Y RELACIÓN ENTRE US_STATE Y REGION
/* Para mejorar la base de datos, se ha creado una nuova relación entre la tablas us_states y region.
 Se ha añadido una columna region_id a la tabla us_states, que hace referencia a la tabla region.
 Además, se ha normalizado la columna state_region de la tabla us_states para que coincida con los valores de la tabla region.
 Finalmente se ha creado una Foreign Key entre las tablas */


-- Adición de una columna para la región en la tabla de los estados
ALTER TABLE us_states
ADD COLUMN region_id INT;

-- Agregar el dato "Midwest" a la tabla de regiones.
INSERT INTO "public"."region" ("region_id", "region_description") VALUES (5, 'Midwest');

-- Normalización de los valores de la columna state_region en la tabla us_states.
UPDATE us_states
SET region_id = (
  SELECT region_id
  FROM region
  WHERE region_id = CASE us_states.state_region
    WHEN 'west' THEN 2
    WHEN 'east' THEN 1
    WHEN 'south' THEN 4
    WHEN 'north' THEN 3
    WHEN 'midwest' THEN 5
    ELSE NULL
  END
);

-- Crear la clave foránea entre us_states y region
ALTER TABLE us_states
ADD CONSTRAINT fk_region_id
FOREIGN KEY (region_id)
REFERENCES region(region_id)
ON DELETE SET NULL;

-- JSONB

-- MODIFICACIÓN DE LA TABLA PRODUCTS PARA AÑADIR UN CAMPO JSONB
ALTER TABLE products
ADD COLUMN caracteristicas_json JSONB;

-- Ejecutar el file python productos_json.py para añadir datos a la columna JSONB

-- Crear index
CREATE INDEX idx_products_caracteristicas_jsonb
ON products USING GIN (caracteristicas_json);

--DUMP DE LA BASE DE DATOS NORTHWIND

-- Crear un file dump de la base de datos Northwind modificada
pg_dump -U postgres -h localhost -p 5432 -d northwind -F p -f "C:\Users\rutanorthwind_dump.sql"  -- Modifica la ruta según tu sistema


-- GITHUB

-- Clonar el repositorio NorthWind y entrar en la carpeta northwind_dump
git clone https://github.com/BiaBib1/NorthWind.git
cd NorthWind\northwind_dump

-- Entrar en la consola de PostgreSQL
psql -U postgres
CREATE DATABASE northwind;
quit

-- Importar el archivo dump en la base de datos Northwind
PS C:\Users\ruta\northwind_dump> psql -U postgres -d northwind -f northwind_dump.sql  -- Modifica la ruta según tu sistema