open Data_type
open File_reader
open File_writer
open Int_ops
open Float_ops
open String_ops

let () =
  let input_file = "data/input.csv" in
  let output_file = "data/output.csv" in
  let normalized_output_file = "data/normalized_output.csv" in

  if not (Sys.file_exists input_file) then
    Printf.printf "Error: Cannot find %s\n" input_file
  else begin
    (* 1. Read schema and lazy sequence *)
    let schema, stream = File_reader.read_csv_with_schema input_file in

    (* 2. Build Pipeline using Type-Specific Operations *)
    let processed_stream = 
      stream
      |> Int_ops.filter_min "Age" 5
      |> String_ops.to_uppercase "Name"
      |> Float_ops.add_bonus "Salary" 50.0
    in

    (* 3. Write out to new CSV (Preserving the Schema row!) *)
    File_writer.write_csv output_file schema processed_stream;
    Printf.printf "Successfully processed data to output.csv after filtering and transformation\n";

    (*Normalization and Scaling*)

    let schema, stream_ns = File_reader.read_csv_with_schema output_file in
    let mean_sal, std_dev_sal = Float_ops.get_stats "Salary" stream_ns in
    Printf.printf "Salary - Mean: %.2f, Std Dev: %.2f\n" mean_sal std_dev_sal;

    let _, stream_ns1 = File_reader.read_csv_with_schema output_file in
    let normalized_stream = Float_ops.standardize "Salary" mean_sal std_dev_sal stream_ns1 in
    File_writer.write_csv normalized_output_file schema normalized_stream;

    (* 4. Analytics Phase (Purely Lazy, NO Lists!) *)
    Printf.printf "--- Analytics on Output Data ---\n";

    (* Pass 1: Calculate Average Age *)
    let _, stream_for_age = File_reader.read_csv_with_schema output_file in
    let avg_age = Int_ops.mean "Age" stream_for_age in
    Printf.printf "Average Age : %.2f\n" avg_age;

    (* Pass 2: Calculate Salary Stats *)
    let _, stream_for_salary = File_reader.read_csv_with_schema normalized_output_file in
    let out_mean_sal, out_std_sal = Float_ops.get_stats "Salary" stream_for_salary in
    Printf.printf "Output Salary - Mean: %.2f | Std Dev: %.2f\n" out_mean_sal out_std_sal;
  end