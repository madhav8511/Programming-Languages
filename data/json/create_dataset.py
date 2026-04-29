import json
import os

# Adjust 'rows' to scale the file size (e.g., 5000000 for a massive dataset)
rows = 10
file1 = "input1.json"
file2 = "input2.json"


print(f"Generating {file1} and {file2}...")
departments = ["HR", "Engineering", "Marketing", "Sales", "Finance"]

# 1. Generate data for input1.json (Name, Age, Salary)
data1 = []
for i in range(rows):
    data1.append([f"User_{i}", i % 100, i * 1.5])

json1_payload = {
    "columns": ["Name", "Age", "Salary"],
    "datatypes": ["String", "Int", "Float"],
    "data": data1
}

with open(file1, mode='w') as f1:
    # Using indent=2 makes the JSON human-readable. 
    # For a massive 5M row file, you can remove indent=2 to save disk space!
    json.dump(json1_payload, f1, indent=2)


# 2. Generate data for input2.json (Name, Age, Department)
data2 = []
for i in range(rows):
    data2.append([f"User_{i}", i % 100, departments[i % len(departments)]])

json2_payload = {
    "columns": ["Name", "Age", "Department"],
    "datatypes": ["String", "Int", "String"],
    "data": data2
}

with open(file2, mode='w') as f2:
    json.dump(json2_payload, f2, indent=2)

print("Test JSON data generated successfully! Ready for the Laminar Engine (JSON Mode).")