import urllib.request
import urllib.error
import json

# ── Same credentials as populate_orders.py ────────────────────────────────────
URL = "https://bdgwzkpteyxhlgprlmye.supabase.co/rest/v1"
KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU"

HEADERS = {
    'apikey': KEY,
    'Authorization': f"Bearer {KEY}",
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

def req(path, method, body=None):
    data = json.dumps(body).encode('utf-8') if body is not None else None
    request = urllib.request.Request(f"{URL}/{path}", data=data, headers=HEADERS, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} — {e.read().decode('utf-8')}")
        return None

def run():
    print("Fetching products...")
    products = req("products?select=id,name,base_price,cost_price", "GET")
    if not products:
        print("No products found.")
        return

    print(f"Found {len(products)} products. Setting cost_price = base_price × 0.45...\n")

    updated = 0
    skipped = 0

    for p in products:
        pid         = p["id"]
        name        = p.get("name", "Unknown")
        base_price  = p.get("base_price", 0)
        cost_price  = p.get("cost_price")

        # Only update if cost_price is missing or unrealistically high (> 80% of base)
        if base_price and base_price > 0:
            new_cost = round(float(base_price) * 0.45, 2)
            if cost_price is None or float(cost_price) > float(base_price) * 0.80:
                result = req(f"products?id=eq.{pid}", "PATCH", {"cost_price": new_cost})
                if result is not None:
                    print(f"  ✅ {name[:40]:<40}  base=₹{base_price}  →  cost=₹{new_cost}")
                    updated += 1
                else:
                    print(f"  ❌ Failed to update: {name}")
            else:
                print(f"  ⏭  {name[:40]:<40}  cost already set to ₹{cost_price} (skipping)")
                skipped += 1
        else:
            print(f"  ⚠️  {name[:40]:<40}  no base_price, skipping")
            skipped += 1

    print(f"\nDone! Updated: {updated}  |  Skipped: {skipped}")

if __name__ == "__main__":
    run()
