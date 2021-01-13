# KielceRB

`KielceRB` is a highly customizable templating engine for generating assignments, syllabi, web pages and other course documents.  It loads a hierarchy of key-value pairs from files at various file system levels.  These values can then be inserted into documents using Ruby's ERB templating engine. `KielceRB` simplifies the maintenance of course documents by moving data that changes regularly into external data files where they can be easily identified and updated.  By loading data from various file system levels, it is easy to share values among all documents for a particular course and/or semester. 

`KielceRB` also provides a method for including one document inside another allowing users to easily share common content among several pages (navigation bars, contact information, assignment headers, etc.).

## Simple Example

Data files are Ruby files that return a hash containing key-value pairs. The names of these files must mach the pattern `kielce_data*.rb`.

``` ruby
{
  semester: 'Fall',
  year: '2020',
  credit_hours: 12
}
```

Values from these hashes can be inserted into documents using Ruby's ERB syntax: 

```erb
<html>
   <body>
      <h1>Computer Science 1 <%= $d.semester %> <%= $d.year %>
      ...
```

Notice that the hash returned by the data file is converted to an object for which each key in the hash is now a method (hence the method-call syntax above as opposed to "square-bracket" syntax used by a plain Hash).  This object is placed in the global variable `$d`.

The simplest use case is:

1. Create a data file named `kielce_data.rb`
2. Create an erb file using the data (let's call it `my_file.html.erb`)
3. Run `kielce my_file.html.erb > my_file.html`

## Intermediate Features

### Hierarchical data

The values in the data files can any type of Ruby object (including nested Hashes)

```ruby 
{
  course: {
    name: 'Computer Science I',
    code: 'CIS 162',
    exam_dates: {
      midterm: Date.new(2020, 10, 22),
      final: Date.new(2020, 12, 14)
    }
  },

  semester: {
    term: 'Fall',
    year: '2020'
  },

  general: {
    office_hours: ['Monday 10:00 - 11:00', 'Thursday 2:00 - 3:00']
  }
}
```

Nested hashes are converted into objects just as the root hash is.  Thus, the syntax for accessing the term is `<%= $d.semester.term %>`.  

Objects that are not hashes are simply returned.  Thus, one could use the following to display the final exam date: 
<code><%=&#160;$d.course.exam_dates.final.strftime("%A, %-d %B %Y")></code>

Note: Only directly nested hashes are converted to objects.

```ruby
{
  # Note:  KielceRB will *not* convert the hashes in the array to objects.
  books: [{
    author: 'Homer',
    name: 'Odyssey'
  },
  {
    author: 'Chaucer',
    name: 'Canterbury Tales'
  }]
}
```

### Functions

The values in the data file may be functions (i.e., Ruby Lambdas):

```ruby
{
  semester: {
    term: 'Fall',
    year: '2020',
    full_name: -> () {"#{term} #{year}"}
  }
}
```

Referencing the key calls the function: `<%= $d.semester.full_name %>`

Notice in the example above that other keys in the same hash may be referenced without qualification.  Keys in other objects can be referenced using the `root` method:

```ruby 
{
  course: {
    name: 'Computer Science I',
    full_name: () -> {"#{name} #{root.semester.term} #{root.semester.year}"}
  },

  semester: {
    term: 'Fall',
    year: '2020'  
  }
}
```

Functions may take parameters:

```ruby
{
  greeting: -> (name) { "Greetings, #{name}.  How are you today?"}
}
```
Parameters are passed in the usual way:

```erb
<%= $d.greeting('Bob') %>
```

Parameter names will shadow (i.e., hide) keys in the local data object.  It is, of course, best to avoid parameter names that are identical to data object keys.  If this can't be avoided, you can reference the data object through `self`:

```ruby
{
   city: 'London',
   my_func: -> (city) {"parameter: #{city} data value: #{self.city}"}
}
```

Similarly, avoid using `root` as a variable name.  If that can't be avoided, you can reference the object hierarchy through `self.root`


### Data File Hierarchy

`KielceRB` searches for multiple data files.  Specifically, it begins in the directory containing the source file and searches each ancestor directory for files matching the pattern `kielce_data*rb`.  The data in these files are merged into a single object hierarchy.  

* If a key is used in multiple files, the value defined deepest in the hierarchy (i.e., closest to the template file) takes precedence.  (See the `SampleSite` directory for an example.)

* If the same key appears in multiple files in the same directory (i.e., at the same level of the hierarchy), there is no guarantee which value will be used.  (Therefore, avoid including the same key in multiple files unless those files are in different directories.)

* Data files must have a name that matches this pattern: `kielce_data*.rb`.  The specific value matched by `*` doesn't matter.  I tend to have multiple data files open at once (usually because I'm working on multiple courses at once) and found it helpful for each data file to have a different name.

### Nesting Files

You can use the `render` or `render_relative` method to include one file inside another.  For example, the main page for both courses in the included `SampleSite` display the professor's contact information by including the external file `Common/contactInfo.html.erb`. 

The template `cs101_index.html.erb` includes the contact info file directly: 
`<%= $k.render_relative('../Common/contactInfo.html.erb')%>`; however, this approach is a bit fragile because if either teplate file is moved, the path won't be correct and will need to be updated.  A better approach is to put the filename in a variable. (See `cs202_index.html.erb`.) That way, if the contact info file ever moves, we need only update the variable. 

The `render` method interprets the file name relative to the current working directory.  `render_relative` interprets the filename relative to the current file (`cs101_index.html.erb` in the case above).  I have found that `render` works best when given an absolute path name.  Notice that in `kielce_data_site.rb`, the `common_dir` value uses Ruby's `Kernel#__dir__` method to dynamically generate an absolute path name for use with `render`. Generating the path name dynamically means that we can move entire web site directory (e.g., `SampleSite`) without breaking any of the `render` calls.

The `render` and `render_relative` methods optionally take a second parameter that is a hash of key/value pairs.  For example `<%= $k.render('fileToInclude.html.erb', { x: 'Hi', y: 'Mom'} %>`. 

**Important**: When rendering an included template, variables are resolved with respect to the *outermost* file (i.e., the one listed on the `kielce` command line).  In the `SampleSite` example, both `CS101/cs101_index.html.erb` and `CS202/cs202_index.html.erb` include `Common/contactInfo.html.erb`.  `contactInfo.html.erb` references the key `short_name`.  Notice that is the the value of `course.short_name` provided by the data file in `CS101/kielce_data_cs101.rb` or `CS202/kielce_data_cs202.rb`.  It does *not* use the value of `course.short_name` given in `Common/kielce_data_common.rb`.  If you want to use key/value pairs specific to the included template, you can 

1. Put the data directly in the erb file in a local variable
2. Put the data in a `kielce_data*.rb` file that is in a common ancestor of both the "outer" and "inner" file.  (In the `SampleSite` example, we could put such data in the `SampleSite` directory because it is the root of both the included `contactInfo.html.erb` and the outer course pages.)

## Advanced Features

*Coming Soon*

##  `Kielce` Methods

`Kielce::Kielce` is the main class.  Running the script creates a singleton object of this type that is placed in the global variable `$k`.  `Kielce` provides the following public methods

### `link(url, link_text=nil, code: nil, classes: nil)`

This method generates an anchor tag with the given URL and link text.  For example, `$k.link(`https://www.gatech.edu`, "Go, Jackets!")` returns `<a href='https://www.gatech.edu'>Go, Jackets!</a>`.  

If `link_text` is `nil`, then the URL is used as the link text and the link text is rendered in a fixed-width font.  For example, `$k.link('https://www.gvsu.edu')` returns `<a href='https://www.gvsu.edu'><code>https://www.gvsu.edu</code></a>`

Setting `code` to true renders the link text in a fixed-width font (as shown in the example above).  The default is to print the link text in a normal font.

The string passed to `classes` is the value for the `class` attribute on the anchor tag.  `$k.link('https://www.gatech.edu', "Go, Jackets!", classes: 'important')` will generate `<a href='https://www.gatech.edu' class='important'>Go, Jackets!</a>`

#### `link` Shortcut

`KielceRB` adds a `link` method to the `String` class to make it easier to generate links.  This `link` method simply calls `Kielce#link`.  For example, to generate a link to `https://www.gvsu.edu` and have the URL as the link text, you can simply add this to the erb document: `<%= "https://www.gatech.edu".link %>`  Similarly, if you want to also specify the link text you can do this:  `<%= "https://www.gatech.edu".link('Go, Jackets!') %>`


### `render(file, local_variables)`
### `render_relative(file, local_variables)`

The `render` and `render_relative` methods includes one .erb file inside another.  See the "Nesting Files" section above.

## Pitfalls


1. Don't use `root`, `inspect`, or `method_missing` as key names.





