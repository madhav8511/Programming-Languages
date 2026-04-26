(* benchmark.ml *)
open Data_type
open File_reader
open Int_ops
open Float_ops
open String_ops

(* --- Benchmarking Engine --- *)
let run_benchmark name pipeline_func =
  (* Force Garbage Collection before starting for a clean slate *)
  Gc.compact (); 
  
  (* Helper to get total allocated memory in words *)
  let get_allocated_words () =
    let st = Gc.quick_stat () in
    st.Gc.minor_words +. st.Gc.major_words -. st.Gc.promoted_words
  in

  let start_time = Sys.time () in
  let start_mem = get_allocated_words () in
  
  pipeline_func ();
  
  let end_time = Sys.time () in
  let end_mem = get_allocated_words () in
  
  let mem_used_words = end_mem -. start_mem in
  let mem_used_mb = (mem_used_words *. 8.0) /. (1024.0 *. 1024.0) in

  Printf.printf "[%s]\n" name;
  Printf.printf "  Time Executed: %f seconds\n" (end_time -. start_time);
  Printf.printf "  Memory Alloc : %.0f words (~ %.2f MB)\n\n" mem_used_words mem_used_mb


(* --- The Two Pipelines --- *)
let () =
  let input_file = "data/input.csv" in

  if not (Sys.file_exists input_file) then
    Printf.printf "Error: Cannot find %s\n" input_file
  else begin
    Printf.printf "Starting Performance Benchmarks...\n";
    Printf.printf "----------------------------------\n";

    (* 1. Functional Lazy Pipeline (Your Engine) *)
    let lazy_pipeline () =
      let _, stream = File_reader.read_csv_with_schema input_file in
      stream
      |> Int_ops.filter_min "Age" 5
      |> String_ops.to_uppercase "Name"
      |> Float_ops.add_bonus "Salary" 50.0
      (* Force consumption without writing to disk to isolate CPU/Memory performance *)
      |> Seq.iter ignore 
    in

    (* 2. Eager "Imperative" Pipeline *)
    let eager_pipeline () =
      let _, stream = File_reader.read_csv_with_schema input_file in
      
      (* Mimic imperative behavior: Load EVERYTHING into RAM first *)
      let in_memory_data = List.of_seq stream in 
      
      (* Process the massive lists in memory *)
      let filtered = List.filter (fun row -> 
        match List.assoc_opt "Age" row with Some (VInt i) -> i >= 5 | _ -> false
      ) in_memory_data in
      
      let uppercased = List.map (fun row -> 
        List.map (fun (k, v) -> if k = "Name" then 
          match v with VString s -> (k, VString (String.uppercase_ascii s)) | _ -> (k, v)
        else (k, v)) row
      ) filtered in
      
      let bonused = List.map (fun row ->
        List.map (fun (k, v) -> if k = "Salary" then
          match v with VFloat f -> (k, VFloat (f +. 50.0)) | _ -> (k, v)
        else (k, v)) row
      ) uppercased in
      
      ignore bonused
    in

    run_benchmark "2. Traditional Imperative (In-Memory Lists)" eager_pipeline;
    run_benchmark "1. Pure Functional (Lazy Stream)" lazy_pipeline;
    
  end