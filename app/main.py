import os
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, HTTPException, status

app = FastAPI(
    title="AnyCompany Retail Modernization API",
    version="1.0.0",
    description="Backend microservice serving retail data from Amazon RDS PostgreSQL on AWS EKS"
)

# Database configuration sourced from environment variables
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "anycompany")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "AnyCompanySecure2026!")
DB_PORT = os.getenv("DB_PORT", "5432")

def get_db_connection():
    """Establishes connection to the PostgreSQL database."""
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT,
        cursor_factory=RealDictCursor,
        connect_timeout=3
    )

# --- Kubernetes Health Probes ---

@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
def health_check():
    """Liveness probe to check if the application process is running."""
    return {"status": "healthy", "service": "anycompany-api"}

@app.get("/ready", status_code=status.HTTP_200_OK, tags=["Health"])
def readiness_check():
    """Readiness probe to verify database connectivity before receiving traffic."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1;")
        cur.close()
        conn.close()
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database unreachable: {str(e)}"
        )

# --- Data Endpoints ---

@app.get("/products", tags=["Retail Data"])
def get_products():
    """Fetches all product records from RDS."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, sku, name, price, stock FROM products ORDER BY id ASC;")
        products = cur.fetchall()
        cur.close()
        conn.close()
        return {"count": len(products), "products": products}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/customers", tags=["Retail Data"])
def get_customers():
    """Fetches all customer records from RDS."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, email, created_at FROM customers ORDER BY id ASC;")
        customers = cur.fetchall()
        cur.close()
        conn.close()
        return {"count": len(customers), "customers": customers}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/orders", tags=["Retail Data"])
def get_orders():
    """Fetches enriched order records with joined customer and product details."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        query = """
            SELECT 
                o.id AS order_id,
                c.name AS customer_name,
                c.email AS customer_email,
                p.name AS product_name,
                p.sku AS product_sku,
                o.quantity,
                o.total_price,
                o.order_date
            FROM orders o
            JOIN customers c ON o.customer_id = c.id
            JOIN products p ON o.product_id = p.id
            ORDER BY o.id ASC;
        """
        cur.execute(query)
        orders = cur.fetchall()
        cur.close()
        conn.close()
        return {"count": len(orders), "orders": orders}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))