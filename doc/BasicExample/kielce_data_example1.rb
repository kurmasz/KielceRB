require 'date'

{
  semester: {
    term: 'Fall',
    year: '2020',
    full_name: -> () {"#{term} #{year}"}
  },

  general: {
    office_hours: ['Monday 10:00 - 11:00', 'Thursday 2:00 - 3:00']
  },

  course: {
    name: 'Computer Science I',
    prefix: 'CIS',
    number: '162',
    
    # Objects can be nested
    exam_dates: {
      midterm: Date.new(2020, 10, 22),
      final: Date.new(2020, 12, 14)
    },

   #
   # Functions
   #

    # Other keys in the same object are in scope within lambdas
    informal_name: -> () {"#{prefix} #{number}"},

    # Keys outside the same object can be accessed through "root"
    formal_full_name: -> () {"#{name} #{root.semester.term} #{root.semester.year}"},

    # Functions can call other functions
    informal_full_name: -> () {"#{informal_name} #{root.semester.full_name}"},

    # Functions can take parameters.  Notice that the parameter variable 'name' 
    # shadows the data item 'name'.  (Avoid when possilble.  If it can't be avoid, just
    # access the item from the data object through 'root'.)
    greeting: -> (name) { "Greetings, #{name}.  How are you today?"}
  },

  
}