import csv

# Adjust 'rows' to scale the file size 500000000
rows = 10
filename = "input.csv"

print(f"Generating {filename}...")
departments = ["HR", "Engineering", "Marketing", "Sales", "Finance"]

with open(filename, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Name", "Age", "Salary", "Department"])
    writer.writerow(["String", "Int", "Float", "String"])
    for i in range(rows):
        writer.writerow([f"User_{i}", i % 100, i * 1.5, departments[i % len(departments)]])

print("Test data generated.")
