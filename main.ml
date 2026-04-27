(* main.ml *)
open Data_type
open File_reader
open File_writer
open Int_ops
open Float_ops
open String_ops
open Join_ops
open Aggregate_ops

let () =
  let file1 = "data/input1.csv" in
  let file2 = "data/input2.csv" in
  let joined_file = "data/joined.csv" in
  let output_file = "data/output.csv" in
  let normalized_output_file = "data/normalized_output.csv" in

  if not (Sys.file_exists file1) || not (Sys.file_exists file2) then
    Printf.printf "Error: Cannot find input files!\n"
  else begin
    Printf.printf "Igniting the Laminar Data Engine...\n";

    (* PHASE 1: Data Integration (Join)*)
    Printf.printf "\n--- Phase 1: Joining Files ---\n";
    let schema1, stream1 = File_reader.read_csv_with_schema file1 in
    let schema2, stream2 = File_reader.read_csv_with_schema file2 in
    
    let joined_schema, joined_stream = Join_ops.fully_lazy_join "Name" schema1 stream1 schema2 stream2 in
    
    (* Write intermediate joined data to disk *)
    File_writer.write_csv joined_file joined_schema joined_stream;
    Printf.printf "Successfully joined input1 and input2 into joined.csv\n";



    (* PHASE 2: Group-By Aggregation*)
    (* Stream the new joined file to calculate Department averages *)
    let _, agg_stream = File_reader.read_csv_with_schema joined_file in
    let group_results = Aggregate_ops.group_by "Department" "Salary" Aggregate_ops.Mean agg_stream in
    
    Aggregate_ops.print_group_results "Average Salary per Department (Raw Joined Data)" group_results;


    (* PHASE 3: Main Transformation Pipeline*)
    Printf.printf "\n--- Phase 3: Core Transformations ---\n";
    let schema_joined, stream_joined = File_reader.read_csv_with_schema joined_file in

    let processed_stream = 
      stream_joined
      |> Int_ops.filter_min "Age" 10
      |> String_ops.to_uppercase "Name"
      |> String_ops.append_suffix "Department" "_DEPT"
      |> Float_ops.add_bonus "Salary" 10.0
    in

    File_writer.write_csv output_file schema_joined processed_stream;
    Printf.printf "Successfully processed data to output.csv\n";



    (* PHASE 4: Normalization & Scaling*)
    Printf.printf "\n--- Phase 4: Normalization ---\n";
    let schema_out, stream_ns_stats = File_reader.read_csv_with_schema output_file in
    let mean_sal, std_dev_sal = Float_ops.get_stats "Salary" stream_ns_stats in
    Printf.printf "Post-Processing Salary - Mean: %.2f, Std Dev: %.2f\n" mean_sal std_dev_sal;

    let _, stream_ns_apply = File_reader.read_csv_with_schema output_file in
    let normalized_stream = Float_ops.standardize "Salary" mean_sal std_dev_sal stream_ns_apply in
    File_writer.write_csv normalized_output_file schema_out normalized_stream;
    Printf.printf "Successfully wrote normalized data to normalized_output.csv\n";



    (* PHASE 5: Final Analytics*)
    Printf.printf "\n--- Phase 5: Analytics on Output Data ---\n";

    let _, stream_for_age = File_reader.read_csv_with_schema output_file in
    let avg_age = Aggregate_ops.global_agg "Age" Aggregate_ops.Mean stream_for_age in
    Aggregate_ops.print_agg_results "Average Age" "Age" avg_age;

    let _, stream_for_salary = File_reader.read_csv_with_schema normalized_output_file in
    let out_mean_sal, out_std_sal = Float_ops.get_stats "Salary" stream_for_salary in
    Printf.printf "Final Normalized Salary - Mean: %.2f | Std Dev: %.2f\n" out_mean_sal out_std_sal;
    
    Printf.printf "\nPipeline execution complete!\n";
  end