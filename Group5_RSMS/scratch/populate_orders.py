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
        print("No stores found, skipping...")
        return

    print("Fetching existing products...")
    products = req("products?select=id,base_price,category", "GET")
    if not products:
        print("No products found, skipping...")
        return

    print("Generating Orders and Items...")
    statuses = ["placed", "processing", "shipped", "delivered", "delivered", "delivered", "cancelled"]
    now = datetime.now()
    thirty_days_ago = now - timedelta(days=30)
    customer_ids = [
        "4734345a-525a-4d59-9e61-e7f813b5f977",
        "00000000-0000-0000-0000-000000000000",
        "81266347-e4ac-40c6-82d4-4eba96428458",
        "59324246-79dc-4f0c-b991-88f9e93b32f1",
        "3bb61198-7f75-4d11-9e72-28c5afdb53a7"
    ]

    for s in stores:
        for _ in range(15):
            order_id = str(uuid.uuid4())
            status = random.choice(statuses)
            date = random_date(thirty_days_ago, now).isoformat()
            customer_id = random.choice(customer_ids)
            order_number = f"ORD-{random.randint(100000, 999999)}"
            
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
                    "price_at_purchase": p["base_price"]
                })

            req("customer_orders", "POST", [{
                "id": order_id,
                "store_id": s["id"],
                "total_amount": total_amount,
                "status": status,
                "created_at": date,
                "user_id": customer_id,
                "order_number": order_number,
                "subtotal": total_amount
            }])

            req("customer_order_items", "POST", items)

    print("Done populating DB!")

if __name__ == "__main__":
    run()
