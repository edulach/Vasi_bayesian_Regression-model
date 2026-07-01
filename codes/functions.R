
read_data <- function(file_name, base_dir = getwd()) {
  # Construct full path to datasets folder
  file_path <- file.path(base_dir, "datasets", file_name)
  
  # Check if file exists
  if(!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  ext <- tolower(tools::file_ext(file_path))
  
  data <- switch(ext,
                 "csv" = read.csv(file_path, stringsAsFactors = FALSE),
                 "txt" = read.table(file_path, header = TRUE, stringsAsFactors = FALSE),
                 "xls" = readxl::read_xls(file_path),
                 "xlsx" = readxl::read_xlsx(file_path),
                 stop("Unsupported file type: ", ext)
  )
  
  return(data)
}

