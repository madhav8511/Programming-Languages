import csv
import os

# Adjust 'rows' to scale the file size (e.g., 5000000 for a massive dataset)
rows = 10
file1 = "input1.csv"
file2 = "input2.csv"

print(f"Generating {file1} and {file2}...")
departments = ["HR", "Engineering", "Marketing", "Sales", "Finance"]

# 1. Generate input1.csv (Name, Age, Salary)
with open(file1, mode='w', newline='') as f1:
    writer1 = csv.writer(f1)
    writer1.writerow(["Name", "Age", "Salary"])
    writer1.writerow(["String", "Int", "Float"])
    
    for i in range(rows):
        writer1.writerow([f"User_{i}", i % 100, i * 1.5])

# 2. Generate input2.csv (Name, Age, Department)
with open(file2, mode='w', newline='') as f2:
    writer2 = csv.writer(f2)
    writer2.writerow(["Name", "Age", "Department"])
    writer2.writerow(["String", "Int", "String"])
    
    for i in range(rows):
        writer2.writerow([f"User_{i}", i % 100, departments[i % len(departments)]])

print("Test data generated successfully! Ready for the Laminar Engine.")