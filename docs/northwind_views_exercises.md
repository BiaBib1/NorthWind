# Vistas de Ejemplo - NorthWind

## VW_VENTA_MES - Evolución Mensual de Ventas

```sql
CREATE OR REPLACE VIEW vw_venta_mes AS
SELECT TO_CHAR(DATE_TRUNC('month', o.order_date), 'MM-YYYY') AS Mes,
SUM(ROUND((od.unit_price * od.quantity * (1 - od.discount))::numeric, 2)) AS Total_Ventas
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY Mes
ORDER BY Mes DESC;
```

---

## VW_VENTAS_DIARIAS - Tendencia de los últimos 30 días

```sql
CREATE OR REPLACE VIEW vw_ventas_diarias AS
SELECT DATE(o.order_date) AS Fecha,
       SUM(ROUND((od.unit_price * od.quantity * (1 - od.discount))::numeric, 2)) AS Total_Ventas
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
WHERE o.order_date >= (SELECT MAX(order_date) FROM orders) - INTERVAL '30 days'
GROUP BY Fecha
ORDER BY Fecha DESC;
```

---

## performance_empleados - Ventas por Empleado

```sql
CREATE OR REPLACE VIEW performance_empleados AS
SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS Nombre_Empleado,
COUNT(DISTINCT o.order_id) AS Numero_Ordenes,
SUM(ROUND(od.unit_price * od.quantity * (1 - od.discount))) AS Total_Vendido
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY Total_Vendido DESC;
```

---

## productos_top_ventas - Productos Más Vendidos

```sql
CREATE OR REPLACE VIEW productos_top_ventas AS
SELECT p.product_id, p.product_name, SUM(od.quantity) AS total_cantidad, 
SUM(od.unit_price * od.quantity * (1 - od.discount)) AS ricavo_total
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_cantidad DESC;
```

---

## ventas_por_cliente - Ventas por Cliente

```sql
CREATE VIEW ventas_por_cliente AS
SELECT c.customer_id, c.company_name,
SUM(ROUND(od.unit_price * od.quantity * (1 - od.discount))) AS total_ventas
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_ventas DESC;
```

---

## vw_ventas_categoria - Ventas por Categoría

```sql
CREATE OR REPLACE VIEW vw_ventas_categoria AS
SELECT c.category_name,
SUM(ROUND(od.unit_price * od.quantity * (1 - od.discount))) AS Total_Ventas
FROM categories c
JOIN products p ON c.category_id = p.category_id
JOIN order_details od ON p.product_id = od.product_id
JOIN orders o ON od.order_id = o.order_id
GROUP BY c.category_name
ORDER BY Total_Ventas DESC;
```

---

## vw_ventas_pais - Ventas por País

```sql
CREATE OR REPLACE VIEW vw_ventas_pais AS
SELECT c.country,
SUM(ROUND(od.unit_price * od.quantity * (1 - od.discount))) AS Total_Ventas
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.country
ORDER BY Total_Ventas DESC;  
```

---

## vw_ordenes_ciudad - Distribución por Ciudades

```sql
CREATE OR REPLACE VIEW vw_ordenes_ciudad AS
SELECT c.city,
COUNT(o.order_id) AS Numero_Ordenes,
SUM(ROUND(od.unit_price * od.quantity * (1 - od.discount))) AS Total_Ventas
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.city
ORDER BY Total_Ventas DESC;
```

---

## vw_stock_bajo - Productos que Necesitan Reabastecimiento

```sql
CREATE OR REPLACE VIEW vw_stock_bajo AS
SELECT p.product_id, p.product_name, p.units_in_stock, p.reorder_level
FROM products p
WHERE p.units_in_stock < p.reorder_level    
AND p.units_in_stock > 0
ORDER BY p.units_in_stock ASC;
```

---

## vw_precios_categoria - Comparar Rangos de Precios

```sql
CREATE OR REPLACE VIEW vw_precios_categoria AS
SELECT c.category_name,
MIN(p.unit_price) AS Prezzo_Minimo,
MAX(p.unit_price) AS Prezzo_Massimo,    
AVG(p.unit_price) AS Prezzo_Medio
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY Prezzo_Medio DESC;
```

---

## inventario_per_categoria - Cantidad de Productos por Categoría

```sql
CREATE OR REPLACE VIEW inventario_per_categoria AS
SELECT c.category_name, COUNT(p.product_id) AS numero_prodotti, SUM(p.units_in_stock) AS totale_in_magazzino,
SUM(p.units_on_order) AS in_arrivo
FROM categories c
JOIN products p ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY totale_in_magazzino DESC;
```