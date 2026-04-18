open Data_type
open File_reader
open File_writer
open Int_ops
open Float_ops
open String_ops

let () =
  let input_file = "data/input.csv" in
  let output_file = "data/output.csv" in

  if not (Sys.file_exists input_file) then
    Printf.printf "Error: Cannot find %s\n" input_file
  else begin
    (* 1. Read schema and lazy sequence *)
    let schema, stream = File_reader.read_csv_with_schema input_file in

    (* 2. Build Pipeline using Type-Specific Operations *)
    let processed_stream = 
      stream
      |> Int_ops.filter_min "Age" 99
      |> String_ops.to_uppercase "Name"
      |> Float_ops.add_bonus "Salary" 50.0
    in

    (* 3. Write out to new CSV (Preserving the Schema row!) *)
    File_writer.write_csv output_file schema processed_stream;
    Printf.printf "Successfully processed data to output.csv\n";

    (* 4. Analytics Phase (Purely Lazy, NO Lists!) *)
    Printf.printf "--- Analytics on Output Data ---\n";

    (* Pass 1: Calculate Average Age *)
    let _, stream_for_age = File_reader.read_csv_with_schema output_file in
    let avg_age = Int_ops.mean "Age" stream_for_age in
    Printf.printf "Average Age : %.2f\n" avg_age;

    (* Pass 2: Calculate Total Salary *)
    let _, stream_for_salary = File_reader.read_csv_with_schema output_file in
    let tot_sal = Float_ops.total "Salary" stream_for_salary in
    Printf.printf "Total Salary: %.2f\n" tot_sal;
  end