# Functional Data Science: The Lazy Data Engine

This repository contains the Laminar Data Engine, a purely functional and lazily-evaluated data processing pipeline built in OCaml. It is designed to process massive datasets (CSV and JSON) with an $O(1)$ memory footprint using deferred execution and structural sharing.

## Quick Start Guide

### 1. Generating the Dataset
Before running the pipelines, you need to generate the mock data. Navigate to either the CSV or JSON data directory and run the Python generation script:
```bash
# For CSV data:
cd data/csv
python3 create_dataset.py
cd ../..

# For JSON data:
cd data/json
python3 create_dataset.py
cd ../..
```

### 2. Executing the Data Pipeline

Ensure you are in the root directory of the project. You can easily compile and execute the functional data pipelines using the provided Makefile.

### To execute the CSV-based data pipeline

```bash
make run_csv
```

### To execute the JSON-based data pipeline:

```bash
make run_json
```

## Benchmarking & Profiling

This project includes tools to test and compare the performance (execution time and memory footprint) of our lazy functional engine against traditional imperative/eager approaches.

All benchmark commands should be executed from the root directory.

### 1. Time Comparison

To compare the execution time of the compiled OCaml pipeline against a standard Python baseline, use the standard time system call:

```bash
time python3 benchmark/py_benchmark.py
time ./pipeline_csv
```

### 2. Memory Usage Comparison

The primary goal of this project is to eliminate Out-Of-Memory (OOM) crashes by strictly controlling the Maximum Resident Set Size (RAM).

First, compile the traditional "eager" pipeline for comparison:

```bash
make run_eager
```

Next, use the advanced Linux time utility (/usr/bin/time) to profile the memory consumption of both executables.

Look for the "Maximum resident set size" metric in the output to observe the difference between the O(N) eager approach and the O(1) lazy approach.

# Profile the Eager Approach (High Memory)
```bash
/usr/bin/time ./eager
```

# Profile the Lazy Data Engine (Low Memory)
```bash
/usr/bin/time ./pipeline_csv
```
