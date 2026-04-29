(* eager_benchmark.ml *)
open Csv_reader

(* Helper function to measure and print exact RAM usage *)
let print_memory_usage stage =
  Gc.compact (); 
  let stat = Gc.stat () in
  (* On a 64-bit system, 1 word = 8 bytes. Convert words to Megabytes *)
  let live_words = float_of_int stat.Gc.live_words in
  let mb = (live_words *. 8.0) /. (1024.0 *. 1024.0) in
  Printf.printf "[%s] Current RAM Usage: %.2f MB\n%!" stage mb

let () =
  Printf.printf "Igniting TRADITIONAL Eager Pipeline...\n";
  let file = "data/csv/input1.csv" in

  if not (Sys.file_exists file) then
    Printf.printf "Error: Cannot find %s\n" file
  else begin
    (* 1. Check memory before doing anything *)
    print_memory_usage "Baseline";

    let schema, stream = Csv_reader.read_csv_with_schema file in
    
    Printf.printf "\nLoading entire dataset into RAM...\n%!";
    
    (* 2. THE FATAL FLAW: Forcing the lazy stream into a strict List *)
    let eager_list = List.of_seq stream in 
    
    (* 3. Check memory after the list is loaded into RAM *)
    print_memory_usage "After Eager Load";
    
    let row_count = List.length eager_list in
    Printf.printf "Successfully loaded %d rows into memory.\n" row_count;
  end