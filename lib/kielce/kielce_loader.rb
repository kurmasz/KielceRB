##############################################################################################
#
# KielceLoader
#
# Methods to find and load Kielce data files.
#
# (c) 2020 Zachary Kurmas
#
##############################################################################################

require 'pathname'

module Kielce

  class LoadingError < StandardError
  end

  class KielceLoader

    # Load the kielce_data_*.rb files beginning from the directory that contains +start+.
    #
    # @param start the name of the file in the directory where the search for data files should begin
    # @param current the current data object (which may contain data loaded from other files)
    # @param context the context in which the data files will be executed.
    # @return a +KielceData+ object containing the collective merged data from all kielce data files.
    #
    # Notice that +start+ need not be either a directory or a data file.  Instead we use
    # +start+'s full pathname to identify the directory where we will begin our search.
    # We allow +start+ to be any file because, in most cases, it is simply the .erb file
    # being processed -- thus, it's easiest/cleaner for the user to pass this filename
    # as a parameter rather than convert it to a starting directory first.
    #
    def self.load(start, current: {}, context: Object.new, stop_dir: nil)
      # File.absolute_path returns a String.  We need a full Pathname object.
      stop_path = nil
      stop_path = Pathname.new(File.absolute_path(stop_dir)) unless stop_dir.nil?
      start_path = Pathname.new(File.absolute_path(start))
      start_path = start_path.parent unless start_path.directory?
      KielceData.new(load_directory_raw(start_path, current: current, context: context, stop_dir: stop_path))
    end

    # loads a kielce_data_*.rb file and returns the file's raw data (the plain Ruby Hash)
    #
    # @param file the file to load
    # @param current the current data object (which may contain data loaded from other files)
    # @param context the context in which to execute the data file's code
    # @return the updated data object.
    #
    def self.load_file_raw(file, current: {}, context: Object.new)
      #$stderr.puts "Processing #{file}"

      # (1) Kielce data files are assumed to return a single Hash.
      # (2) The second parameter to eval, the "binding", is an object
      #     describing the context the code being evaluated will run in.
      #     Among other things, this context determines the local variables
      #     and methods avaiable to the code being evaluated.  In order to
      #     prevent data files from manipuating this KielceLoader object this 
      #     method's local variables, we create an empty object and use its 
      #     binding. Note, however, that the code can still read and set global 
      #     variables. Users can also provide a different, custom, context object.
      # (3) To get the correct binding, we need to run the call to +binding+ 
      #     in the context of an instance method on the context object.
      #     The "obvious" way to do this is to add a method to the object
      #     that calls and returns binding.  We decided not to do this for 
      #     two reasons:  (a) We didn't want to add any methods to the context object
      #     that may possibly conflict with the names chosen by users in the data
      #     files, and (b) Object is the default object used for context; but
      #     in theory, users of the library could chose a different object. We didn't want
      #     our chosen name to conflict with a method that may already exist on the user's
      #     chose context object.
      # (4) The third parameter, +file+, allows Ruby to identify the source of any
      #     errors encountered during the evaluation process.
      b = context.instance_eval { binding }
      data = eval File.read(file), b, file
      #$stderr.puts "Current is #{current}"
      #$stderr.puts "Data is #{data}"

      # If the file is empty, or has a nil return, just use an empty hash
      data = {} if data.nil?

      unless data.is_a?(Hash)
        raise LoadingError, "ERROR: Data file #{file} did not return a Hash.  It returned #{data.inspect}."
        # $stderr.puts "ERROR: Datafile #{file} did not return a Hash.  It returned \"#{data.inspect}\"."
        exit 0
      end

      # The deep_merge method will use the data from +data+ in the event of duplicate keys.
      # helpers.rb opens the Hash class and adds this method.
      x = current.deep_merge(data)
      #$stderr.puts "Post-merge is #{x}"
      x
    end

    #
    # Search +dir+ and all parent directories for kielce data files, load them, and
    # return the raw Hash containing the collective datqa.
    #
    # @param dir the directory to search (as a +Pathname+ object)
    # @param current the current data object
    # @param context the context in which to execute the data files' code
    # @pram stop_dir the last (highest-level) directory to examine (as a +Pathname+ object)
    # @return the updated "raw" data object (i.e., the raw Hash)
    def self.load_directory_raw(dir, current: {}, context: Object.new, stop_dir: nil)

      # $stderr.puts "Done yet? #{File.absolute_path(dir)} #{File.absolute_path(stop_dir)}"

      # recurse until you get to either the "stop directory" or the root of the filesystem.
      # beginning from the root of the file system means that entries "closer" to the
      # file being processed replace entries higher up in the file system.
      # unless File.absolute_path(dir) == File.absolute_path(stop_dir) || dir.root?
      unless (!stop_dir.nil? && (dir.realpath == stop_dir.realpath)) || dir.realpath.root?
        current = load_directory_raw(dir.parent, current: current, context: context, stop_dir: stop_dir)
      end

      # By default, process all files fitting the pattern kielce_data*.rb
      # In addition, look in directories named KielceData for files matching the pattern.
      # (The use of KielceData directories allows users to gather multiple data files up and
      # place them "out of sight")
      # +dir+ is a +pathname+ object.  By placing it in a string interpolation, it is coverted to 
      # a +String+ using +Pathname#to_s+.  
      # On occasion, +dir+ may actually be regular file instead of a directory.  In such cases, the
      # glob below will simply fail to match anything.
      # QZ001
      data = Dir.glob("#{dir}/KielceData/kielce_data*.rb") + Dir.glob("#{dir}/kielce_data*.rb")
      data.each do |file|
        current = load_file_raw(file, current: current, context: context)
      end
      current
    end
  end # class
end # module
