{
  reverse: -> (a, b, c) { "#{c} #{b} #{a}"},

  local: {
    val1: 'alpha',
    val2: 'mu',
  
    lfrom: -> (open, close) { "#{open}#{val1}#{close} to #{open}#{val2}#{close}"},
    ofrom: -> (open, close) { "#{open}#{root.range.start}#{close} to #{open}#{root.range.finish}#{close}"}
  },
  
  range: {
    start: 'aleph',
    finish: 'gimmel'
  }

}