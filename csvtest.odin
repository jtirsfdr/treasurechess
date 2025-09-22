package treasurechess

import "core:fmt"
import "core:encoding/csv"
import "core:os"

iterate_csv_from_stream :: proc(filename: string) {
	r: csv.Reader
	r.trim_leading_space  = true
	r.reuse_record        = true
	r.reuse_record_buffer = true
	defer csv.reader_destroy(&r)

	csv_data, ok := os.read_entire_file(filename)
	
	if ok {
		csv.reader_init_with_string(&r, string(csv_data))
	} else {
		fmt.println("Unable to open file: %v", filename)
		return
	}

	defer delete(csv_data)
	for r, i, err in csv.iterator_next(&r){
		if err != nil { fmt.println("iterator error") }
		for f, j in r {
			fmt.printfln("Record %v, field %v: %q", i, j, f)
		}
	}
}


