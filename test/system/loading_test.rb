##############################################################################################
#
# LoadingTest
#
#
# (c) 2020 Zachary Kurmas
##############################################################################################

require "test/unit"
require_relative "system_test_helper"

class LoadingTest < Test::Unit::TestCase
  include SystemTestHelper

#
# Test file hierarchy
#

  def test_internal_only
    (out, err, ev) = verify_kielce("dir1/internal_only.txt.erb", "",
                                   "Drive through Florida and Georgia.",
                                   "Processing #{f("dir1/internal_only.txt.erb")}")
  end

  def test_local_data_file
    (out, err, ev) = verify_kielce("dir2/local_only.txt.erb", "",
                                   "Visiting Idaho and Montana.\nOrigin: Maine and Vermont.",
                                   "Processing #{f("dir2/local_only.txt.erb")}")
  end

  def test_unknown_local_key
    (out, err, ev) = verify_kielce("dir2/unknown_local_key.txt.erb", "",
                                   "",
                                   /Unrecognized key noSuchKey at test\/system_data\/dir2\/unknown_local_key.txt.erb:4/, ERROR)
  end

  def test_unknown_local_variable
    (out, err, ev) = verify_kielce("dir1/unknown_local_variable.txt.erb", "", "",
                                   /dir1\/unknown_local_variable.txt.erb:5.*undefined local variable or method .not_a_var./, ERROR)
  end

  def test_invalid_key
    (out, err, ev) = verify_kielce("dir5/root_as_key/file1.txt.erb", "",
                                   "",
                                   /ERROR: Data file.*kielce_data_root_as_key.rb uses the key \"root\", which is not allowed./, ERROR)
  end

  # keys in kielce_data files should be symbols.  They won't work if they are strings.
  def test_string_as_key
    (out, err, ev) = verify_kielce("dir5/string_as_key/file1.txt.erb", "",
                                   "",
                                   /Unrecognized key lname at.*file1.txt.erb:1/, ERROR)
  end

#
# Test the render method (including files in each other)
#

  def test_nested_render
    expected_output = [
      "First line of the nesting check",
      "First line of outer nested file aaMontanabb",
      "This is the inner nested file xxIdahoyy",
      "Last line of outer nested file.",
      "Last line of the nesting check",
    ].join("\n")

    (out, err, ev) = verify_kielce("dir2/nesting_check.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_level_relative_render
    expected_output = [
      "First line of the relative nesting check",
      "First line of outer relative nested file qqMainerr",
      "This is the inner nested file xxIdahoyy",
      "Last line of outer relative nested file.",
      "Last line of the relative nesting check",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/relative_nesting_check.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_deep_relative_render
    expected_output = [
      "First line of the deep relative nesting check",
      "Going deep:",
      ". Deepest nested file",
      ". Magic word is kazam",
      ".. This is step 2",
      '.. It\'s magic word is Vermont',
      "... On to step 3",
      ".... This is the inner nested file xxIdahoyy",
      "... End of step 3",
      ".. End of step 2",
      ". End deepest nested file",
      "Last line of the deep relative nesting check",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/deep_relative_nesting_check.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_wide_relative_render
    expected_output = [
      "First line of the wide relative nesting check",
      ". A step to the left ...",
      ".. Right and down",
      ".. Some data: kazam",
      ".. Done",
      ". End of step to left",
      "Last line of the wide relative nesting check",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/dir2a/wide_relative_nesting_check.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_nested_relative_render_not_found
    missing_file = File.absolute_path(f("dir2/dir2d/oops.txt.erb"))
    included_from = File.absolute_path(f("dir2/dir2d/step4.txt.erb"))
    (out, err, ev) = verify_kielce("dir2/dir2d/step1.txt.erb", "", "",
                                   /ERROR: Unable to read #{missing_file}\s+\(included from #{included_from}\)/, ERROR)
  end

  def test_nested_render_not_found
    missing_file = f("dir2/dir2e/oops.txt.erb")
    included_from = f("dir2/dir2e/step4.txt.erb")
    (out, err, ev) = verify_kielce("dir2/dir2e/step1.txt.erb", "", "",
                                   /ERROR: Unable to read #{missing_file}\s+\(included from #{included_from}\)/, ERROR)
  end

  def test_multiple_include
    expected_output = [
      "Enter Multiple Include Level 1",
      "Line 2",
      "Line 3",
      "Line 4",
      ". Enter Level 2a",
      ".. Level 3a: Nevada",
      ". Back in 2a",
      ".. Level 3b: California",
      ". Back in 2a",
      ".. Level 3c: Oregon",
      ". Exit Level 2a",
      "Line 6",
      "Line 7",
      ". Enter Level 2b",
      ".. Level 3a: Nevada",
      ". Back in 2b",
      ".. Level 3b: California",
      ". Back in 2b",
      ".. Level 3c: Oregon",
      ". Exit Level 2b",
      "Line 8",
      ". Enter Level 2c",
      ".. Level 3a: Nevada",
      ". Back in 2c",
      ".. Level 3b: California",
      ". Back in 2c",
      ".. Level 3c: Oregon",
      ". Exit Level 2c",
      "Exit Multiple Include Level 1",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/dir2f/multiple_include.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_multiple_include_missing
    # a deeply nested include is a missing file.
    # this tests that the stack is maintained properly so the "included from" is correct
    missing_file = File.absolute_path(f("dir2/dir2f/level3x.txt.erb"))
    included_from = File.absolute_path(f("dir2/dir2f/level2d.txt.erb"))
    (out, err, ev) = verify_kielce("dir2/dir2f/multiple_include_missing.txt.erb", "", "",
                                   /ERROR: Unable to read #{missing_file}\s+\(included from #{included_from}\)/, ERROR)
  end

  def test_included_files_use_root_file_data
    # Suppose file dir1/myFile.txt.erb includes dir2/includedFile.txt.erb
    # kielce_data files in dir2 are not loaded (they are only loaded relative to the original, root file)
    expected_output = [
      "Enter level 1",
      ". This is level 2:",
      ". Nevada",
      ". California",
      "Exit",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/dir2f/include_neighbor.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_passing_local_variables_to_included_file  
    expected_output = [ 
      "Outer file",
      "Inner file",
      "References Carter, Jimmy",
      "Done",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir2/outer_passes_local_to_render.txt.erb", "--quiet", expected_output, "", quiet: true)
  end


  def test_end_of_chain
    expected_output = [
      "Val 1 is gamma",
      "Val 2 is eta",
      "Val 3 is omega",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/dir3a/dir3a1/dir3a1a/end_of_chain.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

#
# Test functions (i.e., lambdas as values)
#

  # The tested function references only parameters (no data variables)
  def test_function1_simple_with_params 
    expected_output = [
      "Testing a function that uses parameters only (it does not reference other variables)",
      "Names:  Harry Dick Tom",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/function1.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  # The tested function references only variables in the same object.
  def test_function2_vars_same_object_L0
    expected_output = [
      "The quote: ->alpha<- to ->mu<- (L0)",
      "Version 2: =>alpha<= to =>mu<= (L0)",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/function2_L0.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  # The tested function references only variables in the same object. 
  # Verifies that correct variables used (i.e., the one closest to the file being processed)
  def test_function2_vars_same_object_L1
    expected_output = [
      "The quote: ->alpha<- to ->eta<- (L1)",
      "Version B: =>alpha<= to =>eta<= (L1)",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/dir3a/function2_L1.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  # The tested function references only variables in the same object. 
  # Verifies that correct variables used (i.e., the one closest to the file being processed)
  def test_function2_vars_same_object_L3 
    expected_output = [
      "The quote: ->gamma<- to ->omega<-",
      "Version 2: =>gamma<= to =>omega<=",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/dir3a/dir3a1/dir3a1a/function2_L3.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  # The tested function references variables in a sibling object
  # (i.e., verifies that 'root' works as expected)
  def test_function3_vars_sibling_object_L0
    expected_output = [
      "The quote: ->aleph<- to ->gimmel<- (L0 other)",
      "Version 2: =>aleph<= to =>gimmel<= (L0 other)",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/function3_L0.txt.erb", "--quiet", expected_output, "", quiet: true)
  end


#
# Test module loading
#


  def test_module_load1 # module is loaded using require_relative with a single, constant string
    expected_output = [
      "Testing module system from file",
      "Get ready:",
      '"something" (ha ha)',
    ].join("\n")
    (out, err, ev) = verify_kielce("dir4/testModule1.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_module_load2 # module is loaded using require_relative with an interpolated string
    expected_output = [
      "Testing module system from file using data for root",
      "Get ready:",
      'woof!',
    ].join("\n")
    (out, err, ev) = verify_kielce("dir4/testModule2.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

end
