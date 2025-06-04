# Modificaciones Northwind - Resumen y Código SQL

Este archivo contiene todas las modificaciones realizadas sobre la base de datos Northwind para PostgreSQL, incluyendo vistas por departamento, triggers, relaciones normalizadas, uso de JSONB y pasos para clonar e instalar la base de datos modificada.

---

## Vistas por Departamento

### 1. Departamento Ventas

**Resumen de ventas por cliente:**
```sql
CREATE VIEW vw_sales_summary_by_customer AS
SELECT c.customer_id, c.company_name, c.country,
COUNT(o.order_id) AS Total_Orders, SUM(od.unit_price * od.quantity) AS Total_Sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name, c.country;
```

**Productos más vendidos por cantidad:**
```sql
CREATE VIEW vw_top_selling_products AS
SELECT p.product_id, p.product_name,
SUM(od.quantity) AS Total_Quantity_Sold
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY Total_Quantity_Sold DESC;
```

---

### 2. Departamento Almacén

**Estado del inventario (productos bajo stock mínimo):**
```sql
CREATE VIEW vw_inventory_status AS
SELECT product_id, product_name, units_in_stock, reorder_level,
  CASE
    WHEN units_in_stock < reorder_level THEN 'LOW STOCK'
    ELSE 'OK'
  END AS stock_status
FROM products;
```

**Pedidos pendientes de envío:**
```sql
CREATE VIEW vw_pending_orders AS
SELECT o.order_id, c.customer_id, c.company_name,
o.order_date, o.shipped_date, o.ship_via, o.freight, o.ship_name,
o.ship_address, o.ship_city, o.ship_region, o.ship_postal_code, o.ship_country    
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.shipped_date IS NULL;
```

---

### 3. Departamento Contabilidad

**Facturas por cliente:**
```sql
CREATE VIEW vw_invoices_by_customer AS
SELECT c.customer_id, c.company_name,
SUM(od.unit_price * od.quantity) AS Total_Invoice
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name;
```

**Ventas por empleado:**
```sql
CREATE VIEW vw_employee_sales AS
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS Employee_Name,
COUNT(o.order_id) AS Total_Orders,
SUM(od.unit_price * od.quantity * (1 - od.discount)) AS Total_Sales
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY e.employee_id, employee_name;
```

---

## Trigger de Actualización de Inventario

```sql
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
```

---

## Relación entre `us_states` y `region`

**Agregar columna y normalizar valores:**
```sql
ALTER TABLE us_states
ADD COLUMN region_id INT;

INSERT INTO "public"."region" ("region_id", "region_description") VALUES (5, 'Midwest');

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
```

**Crear clave foránea:**
```sql
ALTER TABLE us_states
ADD CONSTRAINT fk_region_id
FOREIGN KEY (region_id)
REFERENCES region(region_id)
ON DELETE SET NULL;
```

---

## Uso de JSONB en Products

**Añadir columna JSONB:**
```sql
ALTER TABLE products
ADD COLUMN caracteristicas_json JSONB;
```

**Crear índice GIN para JSONB:**
```sql
CREATE INDEX idx_products_caracteristicas_jsonb
ON products USING GIN (caracteristicas_json);
```

**Nota:** Ejecutar el script Python `productos_json.py` para cargar datos en la columna JSONB.

---

## Dump de la Base de Datos Northwind

**Comando para crear el dump:**
```bash
pg_dump -U postgres -h localhost -p 5432 -d northwind -F p -f "C:\Users\rutanorthwind_dump.sql"  # Modifica la ruta según tu sistema
```

---

## Clonar e Instalar la Base de Datos Modificada

**Clonar el repositorio y entrar en la carpeta:**
```bash
git clone https://github.com/BiaBib1/NorthWind.git
cd NorthWind\northwind_dump
```

**Entrar en la consola de PostgreSQL y crear la base de datos:**
```bash
psql -U postgres
CREATE DATABASE northwind;
quit
```

**Importar el archivo dump:**
```bash
psql -U postgres -d northwind -f northwind_dump.sql  # Modifica la ruta según tu sistema
```