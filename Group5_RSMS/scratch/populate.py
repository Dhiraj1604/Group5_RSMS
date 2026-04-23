import urllib.request
import urllib.error
import json
import uuid
import random
from datetime import datetime, timedelta

URL = "https://bdgwzkpteyxhlgprlmye.supabase.co/rest/v1"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU"

HEADERS = {
    'apikey': KEY,
    'Authorization': f"Bearer {KEY}",
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

def req(table, method, body=None):
    req_url = f"{URL}/{table}"
    data = None
    if body is not None:
        data = json.dumps(body).encode('utf-8')
    request = urllib.request.Request(req_url, data=data, headers=HEADERS, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"Error on {table}: {e.read().decode('utf-8')}")
        return None

def random_date(start, end):
    return start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))

def run():
    print("Fetching existing stores...")
    stores = req("stores?select=id", "GET")
    if not stores:
        print("Inserting stores...")
        stores = req("stores", "POST", [
            {"id": str(uuid.uuid4()), "name": "RSMS Flagship Mumbai", "city": "Mumbai", "country": "India", "code": "BTQ-MUM-01", "is_active": True},
            {"id": str(uuid.uuid4()), "name": "RSMS Delhi Boutique", "city": "New Delhi", "country": "India", "code": "BTQ-DEL-01", "is_active": True},
            {"id": str(uuid.uuid4()), "name": "RSMS Bangalore Store", "city": "Bangalore", "country": "India", "code": "BTQ-BLR-01", "is_active": True}
        ])

    print("Fetching existing products...")
    products = req("products?select=id,base_price,category", "GET")
    if not products:
        print("Inserting products...")
        products = req("products", "POST", [
            {"id": str(uuid.uuid4()), "sku": "JWL-RNG-001", "name": "Maharaja Diamond Ring", "category": "jewellery", "base_price": 485000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "WTC-CHR-001", "name": "Chronograph Prestige", "category": "watches", "base_price": 1250000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "LTH-BAG-003", "name": "Midnight Tote", "category": "leather_goods", "base_price": 95000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "COU-GWN-007", "name": "Evening Cascade Gown", "category": "couture", "base_price": 320000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "ACC-SCF-001", "name": "Silk Cashmere Scarf", "category": "accessories", "base_price": 45000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "FRG-EDP-001", "name": "Oud Noir Extrait", "category": "fragrances", "base_price": 25000, "is_active": True},
            {"id": str(uuid.uuid4()), "sku": "WTC-DVE-002", "name": "Deep Sea Diver", "category": "watches", "base_price": 850000, "is_active": True}
        ])

    if not stores or not products:
        print("Failed to fetch/create basic entities")
        return

    print("Inserting Inventory...")
    inventory_payload = []
    for s in stores:
        for p in products:
            inventory_payload.append({
                "store_id": s["id"],
                "product_id": p["id"],
                "stock_quantity": random.randint(2, 52)
            })
    req("inventory", "POST", inventory_payload)

    print("Generating Orders and Items...")
    statuses = ["completed", "completed", "completed", "completed", "pending", "cancelled"]
    now = datetime.now()
    thirty_days_ago = now - timedelta(days=30)
    customer_ids = [str(uuid.uuid4()) for _ in range(5)] 

    for s in stores:
        for _ in range(15):
            order_id = str(uuid.uuid4())
            status = random.choice(statuses)
            date = random_date(thirty_days_ago, now).isoformat()
            customer_id = random.choice(customer_ids)
            
            total_amount = 0
            items = []
            item_count = random.randint(1, 3)
            for _ in range(item_count):
                p = random.choice(products)
                quantity = random.randint(1, 2)
                total_amount += (p["base_price"] * quantity)
                items.append({
                    "order_id": order_id,
                    "product_id": p["id"],
                    "quantity": quantity,
                    "unit_price": p["base_price"]
                })

            req("customer_orders", "POST", [{
                "id": order_id,
                "boutique_id": s["id"],
                "total_amount": total_amount,
                "status": status,
                "created_at": date,
                "customer_id": customer_id
            }])

            req("customer_order_items", "POST", items)

    print("Inserting Audit Logs...")
    req("audit_logs", "POST", [
        {"action": "Product Created", "event_type": "Products", "user_name": "admin@rsms.com", "entity": "Maharaja Diamond Ring"},
        {"action": "Inventory Updated", "event_type": "Inventory", "user_name": "admin@rsms.com", "entity": "Deep Sea Diver"},
        {"action": "Store Activated", "event_type": "Stores", "user_name": "system", "entity": "RSMS Delhi Boutique"}
    ])

    print("Done populating DB!")

if __name__ == "__main__":
    run()
