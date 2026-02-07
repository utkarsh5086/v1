import csv
from typing import List, Dict

# Generic CSV loader
def load_csv(path: str) -> List[Dict]:
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))

# Normalize IDs to integers
def normalize_int(value, default=0):
    try:
        return int(value)
    except (ValueError, TypeError):
        return default

# === Election-specific loader ===
def load_elections_data():
    # Load raw CSVs
    elections_raw = load_csv("elections.csv")
    races_raw = load_csv("races.csv")
    candidates_raw = load_csv("candidates.csv")

    # Normalize elections
    elections = []
    for e in elections_raw:
        elections.append({
            "id": normalize_int(e["id"]),
            "name": e["name"],
            "date": e["date"],
            "start_time": e.get("start_time") or None,
            "end_time": e.get("end_time") or None,
            "level": e.get("level") or None,
            "state": e.get("state") or None,
            "county": e.get("county") or None,
            "city": e.get("city") or None,
            "races_count": int(e.get("races_count") or 0),
            "measures": int(e.get("measures") or 0)
        })

    # Normalize races
    races = []
    for r in races_raw:
        races.append({
            "id": normalize_int(r["id"]),
            "election_id": normalize_int(r["election_id"]),
            "term": normalize_int(r["term"]),
            "race_name": r.get("race_name") or "",
            "num_candidates": normalize_int(r["num_candidates"])
        })

    # Normalize candidates
    candidates = []
    for c in candidates_raw:
        candidates.append({
            "id": normalize_int(c["id"]),
            "race_id": normalize_int(c["race_id"]),
            "name": c.get("name") or "",
            "party": c.get("party") or None,
            "description": c.get("description") or None
        })


    return elections, races, candidates


def load_measures(csv_path: str):
    measures = []

    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            measures.append({
                "id": int(row["id"]),
                "election_id": int(row["election_id"]),
                "title": row.get("title", ""),
                "description": row.get("description", ""),
                "yes_description": row.get("yes_description") or None,
                "no_description": row.get("no_description") or None,
            })

    return measures
