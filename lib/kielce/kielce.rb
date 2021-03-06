##############################################################################################
#
# Kielce
#
# Convenience methods available within the ERB templates.
#
# (c) 2020 Zachary Kurmas
#
##############################################################################################

require "erb"

module Kielce
  class IncompleteRenderError < StandardError
    attr_accessor :file_name, :source_file, :source_exception

    def initialize(file_to_load, source, ex)
      @file_name = file_to_load
      @source_file = source
      @source_exception = ex
    end
  end

  class Kielce
    attr_reader :error_count
    @@render_count = 0

    # Constructor
    #
    # @param context default context to use when calling +render+
    def initialize(context)
      @data_context = context
      @error_count = 0
      @file_stack = []
    end

    # Generate an +href+ tag.
    #
    # This could be a class method.  We make it
    # an instance method so it can be used using the "$k.link" syntax.
    def link(url, text_param = nil, code: nil, classes: nil)
      class_list = classes.nil? ? "" : " class='#{classes}'"

      # Make the text the same as the URL if no text given
      text = text_param.nil? ? url : text_param

      # use <code> if either (1) user requests it, or (2) no text_param given and no code param given
      text = "<code>#{text}</code>" if code || (text_param.nil? && code.nil?)

      "<a href='#{url}'#{class_list}>#{text}</a>"
    end

    # Load +file+ and run ERB.  The binding parameter determines
    # the context the .erb code runs in.  The context determines
    # the variables and methods available.  By default, kielce
    # uses the same context for loading and rendering.  However,
    # users can override this behavior by providing different contexts
    #
    #
    # @param the file
    # @param b the binding that the template code runs in.
    # @return a +String+ containing the rendered contents
    def render(file, local_variables = {}, b = @data_context.instance_exec { binding })

      local_variables.each_pair do |key, value|
        b.local_variable_set(key, value)
      end

      # $stderr.puts "In render: #{b.inspect}"
      result = "<!--- ERROR -->"

      begin
        content = File.read(file)
      rescue Errno::ENOENT => e
        # TODO Consider using e.backtrace_locations instead of @file_stack
        # (Question: What exaclty do you want to see if render_relative is called
        # by a method)
        raise IncompleteRenderError.new(file, @file_stack.last, e)
      end
      @file_stack.push(file)

      # The two nil parameters below are legacy settings that don't
      # apply to Kielce.  nil is the default value.  We must specify
      # nil, so we can set the fourth parameter (described below).
      #
      # It is possible for code inside an erb file to load and render
      # another erb template.  In order for such nested calls to work
      # properly, each call must have a unique variable in which to
      # store its output.  This parameter is called "eoutvar". (If you
      # don't specifiy eoutvar and make a nested call, the output
      # can get messed up.)
      @@render_count += 1

      begin
        erb = ERB.new(content, nil, nil, "render_out_#{@@render_count}")
        erb.filename = file.to_s
        result = erb.result(b)
      rescue NoKeyError => e
        line_num = e.backtrace_locations.select { |i| i.path == file }.first.lineno
        $stderr.puts "Unrecognized key #{e.name} at #{file}:#{line_num}"
        @error_count += 1
      ensure
        @file_stack.pop
      end
      result
    end

    def render_relative(file, local_variables = {}, b = @data_context.instance_exec { binding })
      path = Pathname.new(File.absolute_path(@file_stack.last)).dirname
      render(path.join(file), local_variables, b)
    end
  end
end
