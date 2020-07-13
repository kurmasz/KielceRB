##############################################################################################
#
# Helpers
#
# (c) 2020 Zachary Kurmas
#
##############################################################################################

class ::String
  def link(text = nil)
    $k.link(self, text)
    #%Q(<a href="#{self}">#{text}</a>)
  end
end

class ::Hash
  # Merges two hashes recursively.  Specificaly, if the value of one item in the hash is itself a hash,
  # merge that nested hash.
  #
  # Hash#merge by default returns a new Hash containing the key/value pairs of both hashes.
  # If a key appears in both "self" and "second", the value in "second" takes precedence.
  # Alternately, you can specify a block to be called if a key appears in both Hashes.
  # The "merger" lambda below merges two nested hashes instead of simply choosing the version in 
  # "second"
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end