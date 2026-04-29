import csv
import time
import sys

def read_csv_lazy(filename):
    """Yields rows one by one (mimics OCaml's Seq.of_dispenser)"""
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        # Skip the OCaml type row (String, Int, Float)
        next(reader) 
        for row in reader:
            # Cast types to match OCaml strictness
            row['Age'] = int(row['Age'])
            if 'Salary' in row: row['Salary'] = float(row['Salary'])
            yield row

def lazy_sort_merge_join(stream1, stream2, key):
    """Exactly mimics your OCaml fully_lazy_join"""
    try:
        row1 = next(stream1)
        row2 = next(stream2)
        while True:
            if row1[key] == row2[key]:
                # Merge dictionaries
                merged = {**row1, **row2}
                yield merged
                row1 = next(stream1)
                row2 = next(stream2)
            elif row1[key] < row2[key]:
                row1 = next(stream1)
            else:
                row2 = next(stream2)
    except StopIteration:
        pass

# --- Pipeline Operations (Mimicking your ops modules) ---

def filter_min(stream, col, min_val):
    for row in stream:
        if row[col] >= min_val:
            yield row

def to_uppercase(stream, col):
    for row in stream:
        row[col] = row[col].upper()
        yield row

def add_dept_bonus(stream, target_col, dept_col, dept_name, bonus):
    for row in stream:
        if row.get(dept_col) == dept_name:
            row[target_col] += bonus
        yield row

# --- Main Execution ---

def main():
    print("Igniting the Python Lazy Pipeline...")
    start_time = time.time()
    
    file1 = "../data/csv/input1.csv"
    file2 = "../data/csv/input2.csv"
    output_file = "python_output.csv"

    # 1. Open Streams
    stream1 = read_csv_lazy(file1)
    stream2 = read_csv_lazy(file2)

    # 2. Lazy Join
    joined_stream = lazy_sort_merge_join(stream1, stream2, "Name")

    # 3. The Grand Pipeline
    processed_stream = joined_stream
    processed_stream = filter_min(processed_stream, "Age", 5)
    processed_stream = to_uppercase(processed_stream, "Name")
    processed_stream = add_dept_bonus(processed_stream, "Salary", "Department", "Engineering", 500.0)

    # 4. Write Lazily
    with open(output_file, 'w', newline='') as f:
        # We know the schema based on the merge
        fieldnames = ["Name", "Age", "Salary", "Department"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        # Consume the generator
        count = 0
        for row in processed_stream:
            writer.writerow(row)
            count += 1

    end_time = time.time()
    print(f"Processed {count} rows successfully.")
    print(f"Python Execution Time: {end_time - start_time:.4f} seconds")

if __name__ == "__main__":
    main()