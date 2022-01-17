require "optparse"

require "kielce/helpers"
require "kielce/kielce_data"
require "kielce/kielce_loader"
require "kielce/kielce"

##############################################################################################
#
# Main (the run method)
#
# (c) 2020 Zachary Kurmas
#
##############################################################################################

module Kielce
  VERSION = "2.0.4"

  # Changelog
  #
  # 2.0.4:  Added a "target" option to "link", and made the timeline links open in a new tab.


  def self.run

    # TODO:
    #idea:  If 1 param:  Assume input and stdout
    #       If 2 params and 2nd param is file, assume input and output
    #       If 2+ params and 2nd param is dir, then process all files.  Place in output dir.  remove.erb from filename.

    options = {
      quiet: false,
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: kielce [options]"

      opts.on("-q", "--[no-]quiet", "Run quietly") do |q|
        options[:quiet] = q
      end
    end.parse!

    $stderr.puts "KielceRB (version #{VERSION})" unless options[:quiet]

    if ARGV.length == 0
      $stderr.puts "Usage: kielce file_to_process"
      exit
    end

    #
    # Get to work
    #

    file = ARGV[0]
    $stderr.puts "Processing #{file}" unless options[:quiet]

    # We use global variables $d and $k to make the data and +Kielce+ objects available to the
    # ERB template engine.  There was a bit of debate about this decision.  The most popular
    # alternative was to create a class named +DataContext+ with +data+ and +kielce+ accessors.
    #
    # Advantages to using global variables:
    # (1) The resulting names were short (two characters) and eye-catching (because the first
    #     character is '$')
    # (2) It keeps the design simpler by eliminating the need for an additional +DataContext+ class.
    # (3) Users can create a custom class to use as a context without worring about conforiming to
    #     any specific interface
    #
    # Advantages to using a special +DataContext+ class:
    # (1) Avoids polluting the global namespace.

    begin
      context = Object.new
      $d = KielceLoader.load(file, context: context)
      $k = Kielce.new(context)
      result = $k.render(file) 
      puts result if $k.error_count == 0
    rescue LoadingError => e
      $stderr.puts e.message
      exit 1
    rescue IncompleteRenderError => e2
      part2 = e2.source_file.nil? ? "" : "(included from #{e2.source_file})"
      $stderr.puts "ERROR: Unable to read #{e2.file_name} #{part2}"
      $stderr.puts "\t(#{e2.source_exception})"
      exit 1
    end
    exit $k.error_count == 0 ? 0 : 1
  end
end

# For now, we just require all plugins here.  Should we ever get to the point where there
# are enough plugins to cause a performance issue, we can do something more clever.
# require_relative 'kielce_plugins/schedule'
