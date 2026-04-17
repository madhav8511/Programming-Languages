(* main.ml *)
open Types
open Operations
open Io

let () =
  let input_file = "input.csv" in
  let output_file = "output.csv" in
  let headers = ["Name"; "Age"; "Salary"] in

  (* Provide a warning if input file doesn't exist to prevent crashes *)
  if not (Sys.file_exists input_file) then
    Printf.printf "Error: Please create an '%s' file first!\n" input_file
  else begin
    Printf.printf "Starting Data Processing Pipeline...\n";

    (* =============================================== *)
    (* STEP 1: PREPROCESSING PIPELINE (Maps & Filters) *)
    (* =============================================== *)
    let pipeline_stream = 
      Io.read_csv_lazy input_file
      |> filter_min_age 5        (* Keep Age >= 5 *)
      |> name_to_uppercase        (* Convert Names to UPPERCASE *)
      |> give_salary_bonus 50.0   (* Add $50 to Salary *)
    in

    (* Consumer 1: Consume the stream and write to CSV *)
    Io.write_csv output_file headers pipeline_stream;
    Printf.printf "Transformation complete. Check '%s'.\n\n" output_file;

    (* =============================================== *)
    (* STEP 2: AGGREGATIONS (Analytics)                *)
    (* =============================================== *)
    (* Because writing to the CSV consumed the lazy stream, 
       we open the NEW output file lazily to run analytics on it. *)
    
    let analytics_stream = Io.read_csv_lazy output_file in
    
    (* NOTE: We must convert the stream to a list here because 
       aggregations consume the sequence, and we want to run 3 of them. *)
    let memory_data = List.of_seq analytics_stream in

    let tot_sal = total_salary (List.to_seq memory_data) in
    let avg_sal = mean_salary (List.to_seq memory_data) in
    let avg_age = mean_age (List.to_seq memory_data) in

    Printf.printf "--- Analytics on Output Data ---\n";
    Printf.printf "Total Salary: %.2f\n" tot_sal;
    Printf.printf "Mean Salary : %.2f\n" avg_sal;
    Printf.printf "Mean Age    : %.2f\n" avg_age;
  end