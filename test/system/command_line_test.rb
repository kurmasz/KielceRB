##############################################################################################
#
# CommandLineTest
#
#
# (c) 2020 Zachary Kurmas
##############################################################################################
require "test/unit"
require_relative "system_test_helper"

class CommandLineTest < Test::Unit::TestCase

  include SystemTestHelper

  def test_local_only
    (out, err, ev) = verify_kielce('', '', '', "Usage: kielce file_to_process") 
  end

  def test_quiet_mode_short_no_file
    (out, err, ev) = verify_kielce('', '-q', '', "Usage: kielce file_to_process", quiet: true) 
  end

  def test_quiet_mode_long_no_file
    (out, err, ev) = verify_kielce('', '--quiet', '', "Usage: kielce file_to_process", quiet: true) 
  end

  def test_quiet_mode_suppresses_processing_message
    (out, err, ev) = verify_kielce('dir1/internal_only.txt.erb', '-q', 'Drive through Florida and Georgia.', 
      '', quiet: true) 
  end

  def test_no_such_file_root
    (out, err, ev) = verify_kielce('dir1/noSuch.txt.erb', '', '', 
      /ERROR: Unable to read #{f("dir1/noSuch.txt.erb")}/, ERROR)
  end

  def test_syntax_error_in_tag
    (out, err, ev) = verify_kielce('dir1/syntax_error1.txt.erb', '', '', 
      /syntax_error1.txt.erb:2: syntax error/, ERROR) 
  end

  def test_syntax_error_in_data_file
    (out, err, ev) = verify_kielce('syntax_error_in_data_file/test1.txt.erb', '', '', 
      /kielce_data_syntax_error1.rb:4: syntax error/, ERROR) 
  end

  def test_data_file_no_hash
    re = /ERROR: Data file.*data_file_no_hash\/kielce_data_no_hash.rb did not return a Hash/
    (out, err, ev) = verify_kielce('data_file_no_hash/kielce_data_no_hash.txt.erb', '', '', 
      re, ERROR) 
  end

end