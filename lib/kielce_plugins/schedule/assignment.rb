module KielcePlugins
  module Schedule

    class Assignment

      ASSIGNMENT_KEYS = [:id, :title, :type, :number, :link, :details]

      SHORT_TYPE = {
        homework: 'HW',
        project: 'P',
        lab: 'L'
      }

      # create a getter for each key (some getters overridden below)
      ASSIGNMENT_KEYS.each { |key| attr_reader key }

      attr_accessor :due, :assigned

      def initialize(row)
        ASSIGNMENT_KEYS.each { |key| instance_variable_set "@#{key.to_s}".to_sym, row[key] }
      end

      def has_type?
        !@type.nil?
      end

      def type
        @type.to_s
      end

      def short_type
        return '' unless has_type?
        key = @type.downcase.to_sym
        $stderr.puts "Unknown type #{@type}" unless SHORT_TYPE.has_key?(key)
        SHORT_TYPE[key]
      end

      def title(style = :original, linked=false)
        case style
        when :original
          text = @title
        when :short_type
          type_num = has_type? ? "#{short_type}#{@number}: " : ''
          text = "#{type_num}#{@title}"
        when :full
          type_string = has_type? ? "#{@type} #{@number}: " : ''
          text = "#{type_string}#{@title}"
        else
          $stderr.puts "Unknown style #{sytle}"
          text = nil
        end

        # build a link, if a link provided
        (linked && !@link.nil?) ?  "<a target='_blank' href='#{@link}'>#{text}</a>" : text
      end # title
    end # class Assignment
  end # module Schedule
end # module KielcePlugins