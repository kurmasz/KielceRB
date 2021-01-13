##############################################################################################
#
# KielceData
#
# An object representing the data loaded from the various Kielce data files.
# The files return a Hash:  a set of key-value pairs.
# +KielceData+ allows users to access the data using the more convenient method syntax (i.e.,
# $d.itemName instead of $d[:itemName] or $d['itemName])
# +KielceData+ is a child of +BasicObject+ instead of +Object+ so that there aren't conflicts
# with methods defined on +Object+ and +Kernel+ (+freeze+, +method+, +trust+, etc. )
#
# For convenience, +KielceData+ does provide a few key methods including +is_a+ and +inspect+
#
# (c) 2020 Zachary Kurmas
#
##############################################################################################

module Kielce
  class NoKeyError < ::NameError
  end

  class InvalidKeyError < ::NameError
  end

  INVALID_KEYS =  [:root, :method_missing, :inspect]

  # Access KielceData instance variables.
  # (We don't want public accessors on the KielceData object because the name
  # we choose may potentially conflict with user data.)
  class KielceDataAnalyzer
    class << self
      def root(obj)
        obj.instance_eval { @xx_kielce_root }
      end

      def name(obj)
        obj.instance_eval { @xx_kielce_obj_name }
      end

      def data(obj)
        obj.instance_eval { @xx_kielce_data }
      end
    end
  end

  # By extending BasicObject instead of Object, we don't have to worry
  # about user data conflicting with method names in Object or Kernel
  #
  # @xx_kielce_data is the hash passed to the constructor.
  # @xx_kielce_obj_name is the key that maps to the value.
  # @xx_kielce_root refers to the root object.  It is used so that lambdas have access to
  # the data.
  #
  # (The strange "xx_kielce_" naming is to avoid conflicts with user-chosen names)
  class KielceData < BasicObject
    @@error_output = $stderr

    def self.error_output
      @@error_output
    end

    def self.error_output=(val)
      @@error_output=val
    end

    def initialize(data, root = nil, obj_name = nil)
      
      INVALID_KEYS.each do |key|
        ::Kernel.send(:raise, InvalidKeyError.new("Invalid Key: #{key} may not be used as a key.", key)) if data.has_key?(key)
      end

      @xx_kielce_obj_name = obj_name.nil? ? "" : obj_name

      @xx_kielce_data = data

      # Remember, root may be a BasicObject and, therefore, not define .nil
      @xx_kielce_root = (root == nil) ? self : root

      @xx_kielce_data.each do |key, value|
        if value.is_a?(::Hash)
          @xx_kielce_data[key] = ::Kielce::KielceData.new(value, @xx_kielce_root, "#{@xx_kielce_obj_name}#{key}.")
        end
      end
    end

    def root
      @xx_kielce_root
    end

    def inspect
      "KielceData: #{@xx_kielce_obj_name} #{@xx_kielce_data.inspect}"
    end

    def is_a?(klass)
      klass == ::Kielce::KielceData
    end

    # Provides the "magic" that allows users to access data using method syntax.
    # This method is called whenever a method that doesn't exist is invoked.  It
    # then looks through the hash for a key with the same name as the method.
    def method_missing(name, *args, **keyword_args, &block)

      # $stderr.puts "Processing #{name} in #{@xx_kielce_obj_name}"

      # Convert the name to a symbol. (It is probably already a symbol, but the extra .to_sym won't hurt)
      # Then complian if there isn't a data object by that name.
      name_sym = name.to_sym
      full_name = "#{@xx_kielce_obj_name}#{name}"
      unless @xx_kielce_data.has_key?(name_sym)
        # The first ("message") parameter is currently unused.  The message can be changed, if desired.
        ::Kernel.send(:raise, NoKeyError.new("Unrecognized Key: #{full_name}", full_name))
      end

      # Get the requested data object.
      # If the object is a lambda, execute the lambda.
      # Otherwise, just return it.
      item = @xx_kielce_data[name_sym]
      if item.is_a?(::Proc)
        if item.parameters.any? { |i| i.last == :root }
          @@error_output.puts 'WARNING! Lambda parameter named root shadows instance method root.'
        end

        #$stderr.puts item.parameters.inspect
        keyword_params = item.parameters.select { |i| i.first == :keyreq || i.first == :key }
        num_keyword = keyword_params.size
        num_args = item.parameters.size - num_keyword

        #$stderr.puts "-----------"
        #$stderr.puts args.inspect
        #$stderr.puts keyword_args.inspect
        #$stderr.puts "Num each: #{num_args} #{num_keyword}"

        if num_args == 0 && num_keyword == 0
          return instance_exec(&item)
        elsif num_args > 0 && num_keyword == 0
          return instance_exec(*args, &item)
        elsif num_keyword > 0
          return instance_exec(*args, **keyword_args, &item)
        else
          $stderr.puts "FAIL.  Shouldn't get here!"
        end
      end

      if args.length != 0 || keyword_args.size != 0
        @@error_output.puts "WARNING! #{full_name} is not a function and doesn't expect parameters."
      end

      @xx_kielce_data[name_sym]
    end
  end # class
end # module
