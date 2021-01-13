{
  office: "221B Baker Hall",
  phone: '(616)-331-5000',

  # Data describing the semester goes here and is shared by all courses.
  semester: {
    term: 'Fall',
    year: '2020',
    full_name: -> () {"#{term} #{year}"},
    office_hours: "M 10-11; W 9-10; F 1-2"
  },

  # functions used by all courses go here; but, the data specific to each 
  # course (prefix, number, name, etc.) goes in a file in the directory specific to that course.
  course: {
    short_name: -> () {"#{prefix} #{number}"},
    full_name: -> () {"#{short_name}: #{name}"},
    
    # Notice that this value is replaced by values in the subdirectories.
    # Specifiying a value is not necessary here; but, it can be helpful if
    # there is a meaningful default value.
    number: '<TBD>'
  },

  common_dir: "#{__dir__}/Common",
  contact_info_file: -> () {"#{common_dir}/contactInfo.html.erb"},
  common_style: -> () {"#{common_dir}/commonStyle.css"}

}