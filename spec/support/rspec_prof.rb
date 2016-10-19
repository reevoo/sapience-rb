require "rspec-prof"

RSpecProf.printer_class = RubyProf::CallStackPrinter
# The printer to be used when writing profiles

RSpecProf::FilenameHelpers.file_extension = "html"
# The file extension for profiles written to disk

RSpecProf::FilenameHelpers.output_dir = "profiles"
# The destination directory into which profiles are written
