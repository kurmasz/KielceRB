require 'rubyXL'
require_relative 'assignment'

# https://www.ablebits.com/office-addins-blog/2015/03/11/change-date-format-excel/

module KielcePlugins
  module Schedule

    class Schedule

      #SCHEDULE_KEYS = [:week, :date, :topics, :notes, :reading, :milestones, :comments]
      SCHEDULE_KEYS = [:week, :date, :topics, :reading, :milestones, :comments]

      attr_accessor :assignments, :schedule_days

      def initialize(filename)       
        workbook = RubyXL::Parser.parse(filename)
        @assignments = build_assignments(build_rows(workbook['Assignments'], Assignment::ASSIGNMENT_KEYS))
        @schedule_days = build_schedule_days(build_rows(workbook['Schedule'], SCHEDULE_KEYS))
      end

      def transform(value)
        if value.is_a? String
          # Replace link markup
          value.gsub!(/\[\[([^\s]+)(\s+(\S.*)|\s*)\]\]/) do
            text = $3.nil? ? "<code>#{$1}</code>" : $3
            "<a href='#{$1}'>#{text}</a>"
          end

          value.gsub!(/<<(assign|due|ref)\s+(\S.+)>>/) do
            #$stderr.puts "Found assignment ref #{$1} --- #{$2} -- #{@assignments[$2].inspect}"
            $stderr.puts "Assignment #{$2} not found" unless @assignments.has_key?($2)

            text = @assignments[$2].title(:full, true)
            if $1 == 'assign'
              "Assign #{text}"
            elsif $1 == 'due'
              "<b>Due</b> #{text}"
            elsif $1 == 'ref'
              text
            else
              $stderr.puts "Unexpected match #{$1}"
            end
          end # end gsub!

          value.gsub!(/{{([^{}:]+):\s*([^{}]+)}}/) do
              text = $1
              link_rule = $2

              if (link_rule =~ /(.*)\!(.+)/)
                method = $1
                param = $2
             
                method = 'default' if method.empty?  
                # $stderr.puts "Found link rule  =>#{method}<= #{method.empty?} =>#{param}<="

                link = $d.course.notesTemplates.method_missing(method, param)                
              else
                link = link_rule
              end                            
              "(<a href='#{link}'>#{text}</a>)"
          end # end gsub

        end # end if value is string
        value
      end

      def build_rows(worksheet, keys)
        # Remove the first (header) row, and any empty rows.
        # Also, remove any rows after "END"
        first = true
        done = false
        rows = []
        worksheet.each do |row|
          done = true if !row.nil? && !row[0].nil? && row[0].value == "END"

          unless first || row.nil? || done
            rows << row
          end
          first = false
        end

        # For each row, build a Hash describing the row.
        rows.map do |row|
          row_hash = { original: {} }
          keys.each_with_index do |item, index|
            row_hash[:original][item] = row[index].nil? ? nil : row[index].value
            row_hash[item] = row[index].nil? ? nil : transform(row[index].value)
          end
          row_hash
        end # end map
      end

      def build_assignments(rows)
        assignment_hash = {}
        rows.each { |row| assignment_hash[row[:id]] = Assignment.new(row) }
        assignment_hash
      end

      def build_schedule_days(schedule_rows)
        array_keys = SCHEDULE_KEYS.slice(2, SCHEDULE_KEYS.length - 2)
        current_week = nil
        schedule_days = []
        schedule_day = nil

        schedule_rows.each do |row|

          # if there is a date, start a new day
          unless row[:date].nil?

            # push day in progress into array
            schedule_days << schedule_day unless schedule_day.nil?

            # create a new schedule_day Hash
            schedule_day = {
              begin_week: false
            }

            unless row[:week].nil?
              current_week = row[:week]
              schedule_day[:begin_week] = true
            end

            schedule_day[:week] = current_week
            schedule_day[:date] = row[:date]
            array_keys.each { |key| schedule_day[key] = [] }
          end

          # push non-nil values onto the corresponding array
         # array_keys.each { |key| schedule_day[key] << row[key] unless row[key].nil? }
         array_keys.each do |key| 
          val = row[key]

          # skip any completely empty cells (they produce a value of nil)
          # Replace a single period with a whitespace.  (Thus producing an empty cell in the table)
          # Similarly, treat cells beginnign with // as a comment and produce an empty cell in the table)
          unless row[key].nil? 
            val = "&nbsp;" if val == '.' || val =~ /^\s*\/\//
            schedule_day[key] << val 
          end
         end

          # Look for assignments / due dates and add information to @assignment objects
          original_milestones = row[:original][:milestones]
          if !original_milestones.nil? && original_milestones =~ /<<due\s+(.*)>>/
            #$stderr.puts "Assignment #{$1} has due date of #{schedule_day[:date].strftime("%a. %-d %b.")}"
            @assignments[$1].due = schedule_day[:date]
          end
          if !original_milestones.nil? && original_milestones =~ /<<assign\s+(.*)>>/
            #$stderr.puts "Assignment #{$1} has assignment date of #{schedule_day[:date].strftime("%a. %-d %b.")}"
            unless @assignments.has_key?($1)
              $stderr.puts "Key #{$1} not found in #{@assignments.keys.inspect}"
            end
            @assignments[$1].assigned = schedule_day[:date]
          end
        end # end each row

        schedule_days << schedule_day unless schedule_day.nil?

        schedule_days
      end

      def timeline_table
        table = []
        table << <<TABLE
      <table class='kielceSchedule'>
       <tr>
        <th>Week</th>
        <th>Date</th>
        <th>Topics</th>
        <!-- <th>Notes</th> -->
        <th>Reading</th>
        <th>Milestones</th>
       </tr>
TABLE

        first = true
        @schedule_days.each do |schedule_day|
          table << '<tr>'

          if schedule_day[:begin_week]
            unless first
              # Add a blank row of horizontal lines
              table << '<td></td><td></td><td></td><td></td><td></td><td></td></tr>'
              table << "<tr class='week_end'><td></td><td></td><td></td><td></td><td></td><td></td></tr>"
              table << '<tr>'
            end
            first = false
            week_value = schedule_day[:week]
          else
            week_value = ''
          end

          table << "  <td class='week_column'>#{week_value}</td>"
          formatted_date = schedule_day[:date].strftime("%a. %-d %b.")
          table << "  <td class='date_column'>#{formatted_date}</td>"
          table << "  <td class='topics_column'>#{schedule_day[:topics].join("<br>")}</td>"
          # table << "  <td class='topics_column'>#{schedule_day[:notes].join("<br>")}</td>"
          table << "  <td class='reading_column'>#{schedule_day[:reading].join("<br>")}</td>"
          table << "  <td class='milestones_column'>#{schedule_day[:milestones].join("<br>")}</td>"
          table << "</tr>"
        end
        table << "</table>"
        table.join("\n")
      end

      def timeline_style
        <<STYLE
        table.kielceSchedule {
          border-collapse: separate;
          border-spacing: 2px;
        }

        .kielceSchedule tr th {
          text-align: left;
        }

        .kielceSchedule tr td {
          vertical-align: top;
          padding-right: 10px;
        }

        .week_column, .date_column {
          white-space: nowrap;
        }

        .kielceSchedule tr th, .date_column, .topics_column, .notes_column, .reading_column, .milestones_column, .week_end td {
          border-bottom: 1px solid;
        }
STYLE
      end

      def timeline_page
        <<PAGE
    <html>
      <head>
         <style>
           #{timeline_style}
         </style>
      </head>
      <body>
           #{timeline_table}
      </body>
     </html>
PAGE
      end

      def assignment_style
        <<STYLE
        .kielceAssignmentTable {
           border-spacing: 35px 0;
        }        

        .kielceAssignmentTable tr th {
          text-align: left;          
        }

        .kielceAssignmentTable tr td {
          vertical-align: top;
        }

        .kielceAssignmentTable_due {
           white-space:  nowrap;
        }

        .kielceAssignmentTable_title {
            white-space: nowrap;
        }

        .exam {
            background-color: lightgreen;
        }
STYLE
      end


      def assignment_list
        list = <<TABLE
    <table class='kielceAssignmentTable'>
      <tr>
         <th>Due</th>
         <th>Name</th>
         <th>Details</th>
      </tr>
TABLE

        by_date = @assignments.values.reject { |item| item.due.nil? || item.type == 'Lab' }.sort_by { |a| a.due }
        by_date.each do |assignment|
          list += '  <tr>'
          list += "    <td class='kielceAssignmentTable_due'>#{assignment.due.strftime("%a. %-d %b.")}</td>\n"
          list += "    <td class='kielceAssignmentTable_title'>#{assignment.title(:full, true)}</td>\n"
          list += "    <td class='kielceAssignmentTable_details'>#{assignment.details}</td>\n"
          list += "  </tr>\n\n"
        end
        list += "</table>\n"
      end

      def lab_list
        list = <<TABLE
    <table class='kielceAssignmentTable'>
      <tr>
         <th>Date</th>
         <th>Name</th>
         <th>Details</th>
      </tr>
TABLE
        assigned_labs = @assignments.values.select { |item| item.type == 'Lab' && !item.assigned.nil? }
        by_date = assigned_labs.sort { |a, b| a.assigned <=> b.assigned }
        by_date.each do |assignment|
          list += '  <tr>'
          list += "    <td class='kielceAssignmentTable_due'>#{assignment.assigned.strftime("%a. %-d %b.")}</td>\n"
          list += "    <td class='kielceAssignmentTable_title'>#{assignment.title(:full, true)}</td>\n"
          list += "    <td class='kielceAssignmentTable_details'>#{assignment.details}</td>\n"
          list += "  </tr>\n\n"
        end
        list += "</table>\n"
        list
      end
  end # end Schedule
end # module
end # end KielcePlugins
#puts Schedule.new(ARGV[0]).timeline_page