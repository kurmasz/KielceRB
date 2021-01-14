require "open3"

module SystemTestHelper
  KIELCE_COMMAND = "ruby -I lib bin/kielce" # test dev
  # KIELCE_COMMAND = 'kielce' # test installed gem
  VERSION = /KielceRB\s+\(version 2.0.1\)\n/
  SUCCESS = 0
  ERROR = 1

  def f(file)
    return "" if file.nil? || file.empty?
    "test/system_data/#{file}"
  end

  def run_command(command_line)
    Open3.popen3(command_line) do |i, o, e, t|
      i.close
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }

      out_reader.join
      err_reader.join
      # puts "exit value is =>#{t.class}<="

      # if wait_thread is nil, then we are running a ruby version of 1.8 or older.
      # In this case, we can't get the process exit value from open3.  Instead,
      # we have to run the process again  to capture the exit value.
      exit_value = t.nil? ? run_exit_only(command_line) : t.value.exitstatus

      [out_reader.value.chomp, err_reader.value.chomp, exit_value]
    end
  end

  def run_kielce(file, flags = "")
    command_line = "#{KIELCE_COMMAND} #{flags} #{f(file)}"
    puts "Running -->#{command_line}<---" if $debug
    run_command(command_line)
  end

  def verify_kielce(file, flags, expected_out, expected_err, expected_return = SUCCESS,
                    strip_output: true, quiet: false)
    (observed_out, observed_err, observed_return) = run_kielce(file, flags)
    puts "Observed out:  -->#{observed_out}<--" if $debug
    puts "Observed err:  -->#{observed_err}<--" if $debug

    assert_equal expected_return, observed_return

    err_lines = observed_err.lines
    unless quiet
      # Remove the first line of the observed error and compare to the standard header
      first_err_line = err_lines.shift
      assert_match VERSION, first_err_line, "Version line"
    end

    if (expected_err.instance_of?(Regexp))
      assert_match expected_err, err_lines.join("\n")
    else
      assert_equal expected_err, err_lines.join("\n")
    end

    observed_out.gsub!(/^\s+/, "") if strip_output

    if (expected_out.instance_of?(Regexp))
      assert_match expected_out, observed_out
    else
      assert_equal expected_out, observed_out
    end

    #  if (expected_err.instance_of?(String))
    #    assert_equal err_lines.join("\n"), expected_err
    #  elsif (expected_err.instance_of?(Array))
    #    expected_err.each do |expected_line|
    #      if (expected_line.instance_of?(Regexp))
    #        assert_match expected_line, err_lines
    #  }

    #  observed_out = lines.length >= 4 ? lines[3..-1].join : ""

    #  if (expected_out.instance_of? Regexp)
    #    expect(observed_out).to match(expected_out)
    #  else
    #    expect(observed_out).to eq(expected_out)
    #  end
    #
    #  if (expected_err.instance_of? Regexp)
    #    expect(observed_err).to match(expected_err)
    #  else
    #    expect(observed_err).to eq(expected_err)
    #  end
    #
    #  expect(observed_return).to eq(expected_return)
  end
end
