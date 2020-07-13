# from https://test-unit.github.io/test-unit/en/file.how-to.html

$debug = false
if (ARGV.any? { |i| i =~ /^(-d|--debug)/})
  # Remove the argument that test-unit won't recognize
  ARGV.reject! { |i| i =~ /^(-d|--debug)/}
  $debug = true
end

puts "Debug is #{$debug}"

base_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
lib_dir = File.join(base_dir, "lib")
test_dir = File.join(base_dir, "test")

$LOAD_PATH.unshift(lib_dir)

require "test/unit"

exit Test::Unit::AutoRunner.run(true, test_dir)
