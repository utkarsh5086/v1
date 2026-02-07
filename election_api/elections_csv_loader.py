# elections_csv_loader.py
import csv

def load_elections(csv_file):
    elections = []
    with open(csv_file, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            elections.append({
                "id": int(row["id"]),
                "name": row["name"],
                "date": row["date"],
                "start_time": row["start_time"] or None,
                "end_time": row["end_time"] or None,
                "level": row["level"],
                "state": row["state"] or None,
                "county": row["county"] or None,
                "city": row["city"] or None,
                "races_count": int(row["races_count"]) or 0,
                "measures": int(row["measures"]) or 0
            })
    return elections
