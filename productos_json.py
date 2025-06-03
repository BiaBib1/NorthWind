import json
import psycopg2

# Carica il file JSON
with open('C:/Users/Biabibi/Documents/GitHub/InProgress/NorthWind/productos.json', 'r') as file:
    data = json.load(file)

# Connessione al database
connection = psycopg2.connect(
    dbname='northwind',
    user='postgres',      # <-- Sostituisci con il tuo username
    password='0000',  # <-- Sostituisci con la tua password
    host='localhost',
    port='5432'
)
cursor = connection.cursor()

# Aggiorna i prodotti
for product in data['products']:
    product_id = product['product_id']
    caracteristicas_json = json.dumps(product['caracteristicas'])
    cursor.execute("""
        UPDATE products
        SET caracteristicas_json = %s
        WHERE product_id = %s
    """, (caracteristicas_json, product_id))

connection.commit()
cursor.close()
connection.close()