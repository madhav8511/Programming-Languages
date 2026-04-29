# --- Variables ---
COMPILER = ocamlopt
INCLUDES = -I types -I io -I operations

# 1. Separate the Core Engine from the Main Execution Files
CORE_SOURCES  = \
    types/data_type.ml \
    io/csv_reader.ml \
    io/csv_writer.ml \
    io/json_reader.ml \
    io/json_writer.ml \
    operations/int_ops.ml \
    operations/float_ops.ml \
    operations/string_ops.ml \
    operations/join_ops.ml \
    operations/aggregate_ops.ml

# --- Rules ---

# Default rule builds both executables
all: pipeline_csv pipeline_json

# 2. Build rules for independent executables
pipeline_csv: $(CORE_SOURCES) csv_main.ml
	$(COMPILER) $(INCLUDES) -o pipeline_csv $(CORE_SOURCES) csv_main.ml

pipeline_json: $(CORE_SOURCES) json_main.ml
	$(COMPILER) $(INCLUDES) -o pipeline_json $(CORE_SOURCES) json_main.ml

# 3. Independent Run Commands
run_csv: pipeline_csv
	./pipeline_csv

run_json: pipeline_json
	./pipeline_json

# Target to build and run the Eager Memory Benchmark
run_eager: $(CORE_SOURCES) benchmark/eager_benchmark.ml
	$(COMPILER) $(INCLUDES) -o eager_run types/data_type.ml io/csv_reader.ml benchmark/eager_benchmark.ml
	./eager_run

# 5. Clean up all generated executables
clean:
	rm -f pipeline_csv pipeline_json eager_run
	rm -f *.cmi *.cmx *.o
	rm -f types/*.cmi types/*.cmx types/*.o
	rm -f io/*.cmi io/*.cmx io/*.o
	rm -f operations/*.cmi operations/*.cmx operations/*.o
	rm -f benchmark/*.cmi benchmark/*.cmx benchmark/*.o

.PHONY: all run_csv run_json run_eager clean