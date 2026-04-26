import csv

# Adjust 'rows' to scale the file size 500000000
rows = 10
filename = "input.csv"

print(f"Generating {filename}...")

with open(filename, mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Name", "Age", "Salary"])
    writer.writerow(["String", "Int", "Float"])
    for i in range(rows):
        writer.writerow([f"User_{i}", i % 100, i * 1.5])

print("Test data generated.")
