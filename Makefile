# --- Variables ---
COMPILER = ocamlopt
INCLUDES = -I types -I io -I operations
TARGET   = pipeline

# Source files
SOURCES  = \
	types/data_type.ml \
	io/file_reader.ml \
	io/file_writer.ml \
	operations/int_ops.ml \
	operations/float_ops.ml \
	operations/string_ops.ml \
	main.ml

# --- Rules ---

all: $(TARGET)

# Rule to build the executable
$(TARGET): $(SOURCES)
	$(COMPILER) $(INCLUDES) -o $(TARGET) $(SOURCES)


run: $(TARGET)
	./$(TARGET)


clean:
	rm -f $(TARGET)
	rm -f *.cmi *.cmx *.o
	rm -f types/*.cmi types/*.cmx types/*.o
	rm -f io/*.cmi io/*.cmx io/*.o
	rm -f operations/*.cmi operations/*.cmx operations/*.o

.PHONY: all run clean