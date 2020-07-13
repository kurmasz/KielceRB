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

  def test_end_of_chain
    expected_output = [
      "Val 1 is gamma",
      "Val 2 is aleph",
      "Val 3 is omega",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/dir3a/dir3a1/dir3a1a/end_of_chain.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

  def test_function1
    expected_output = [
      "The quote: ->gamma<- to ->omega<-",
      "Version 2: =>gamma<= to =>omega<=",
    ].join("\n")
    (out, err, ev) = verify_kielce("dir3/dir3a/dir3a1/dir3a1a/function1.txt.erb", "--quiet", expected_output, "", quiet: true)
  end

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
