import json
from pathlib import Path

# Adjust 'rows' to scale the file size.
rows = 100000
script_dir = Path(__file__).resolve().parent
file1 = script_dir / "input1.jsonl"
file2 = script_dir / "input2.jsonl"

print(f"Generating {file1.name} and {file2.name}...")
departments = ["HR", "Engineering", "Marketing", "Sales", "Finance"]


def write_jsonl(path, schema, rows_iter):
    with path.open(mode="w", encoding="utf-8") as f:
        f.write(json.dumps({"__schema__": schema}, separators=(",", ":")) + "\n")
        for row in rows_iter:
            f.write(json.dumps(row, separators=(",", ":")) + "\n")


write_jsonl(
    file1,
    {"Name": "String", "Age": "Int", "Salary": "Float"},
    (
        {"Name": f"User_{i}", "Age": i % 100, "Salary": i * 1.5}
        for i in range(rows)
    ),
)

write_jsonl(
    file2,
    {"Name": "String", "Age": "Int", "Department": "String"},
    (
        {"Name": f"User_{i}", "Age": i % 100, "Department": departments[i % len(departments)]}
        for i in range(rows)
    ),
)

print("Test JSONL data generated successfully! Ready for the Laminar Engine.")
