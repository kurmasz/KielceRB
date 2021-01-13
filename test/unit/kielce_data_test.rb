##############################################################################################
#
# KielceDataTest
#
#
# (c) 2020 Zachary Kurmas
##############################################################################################

require "test/unit"
require_relative "unit_test_helper"
require "kielce"

class KielceDataTest < Test::Unit::TestCase

  include UnitTestHelper

  def setup
    @error_output = StringIO.new
    Kielce::KielceData.error_output = @error_output

    @multi_level_hash_input = {
      hello: "World",
      nest1: {
        fname: "George",
        lname: "Smith",
        address: {
          line1: "42 Wallaby Way",
          city: "Sydney",
        },
      },
      nest2: {
        fname: "Fred",
        lname: "Jones",
        address: {
          line1: "1600 Pennsylvania Ave.",
          city: "Washington",
          zip: 20202,
        },
      },
      chain1: {
        chain2: {
          chain3: {
            chain4: {
              chain5: {
                chain6: {
                  array: [:l, :m, :n],
                },
              },
            },
          },
        },
      },
    }
  end

  def test_constructor_sets_root_properly
    data = Kielce::KielceData.new(@multi_level_hash_input)

    top_root = Kielce::KielceDataAnalyzer.root(data)
    assert_same data, top_root

    nest_root1 = Kielce::KielceDataAnalyzer.root(data.nest1)
    assert_same data, nest_root1

    nest_root2 = Kielce::KielceDataAnalyzer.root(data.nest2)
    assert_same data, nest_root2

    nest_root_last = Kielce::KielceDataAnalyzer.root(data.chain1.chain2.chain3.chain4.chain5.chain6)
    assert_same data, nest_root_last
  end

  def test_single_level_hash
    input = {
      hello: "World",
      age: 38,
      siblings: ["Barb", "Fred", "Joe"],
    }
    data = Kielce::KielceData.new(input)
    assert_equal "World", data.hello
    assert_equal 38, data.age
    assert_equal 3, data.siblings.size
    assert_equal ["Barb", "Fred", "Joe"], data.siblings
  end

  def test_multi_level_hash
    data = Kielce::KielceData.new(@multi_level_hash_input)
    assert_equal "World", data.hello
    assert_equal "George", data.nest1.fname
    assert_equal "Smith", data.nest1.lname
    assert_equal "Sydney", data.nest1.address.city
    assert_equal "Fred", data.nest2.fname
    assert_equal "Jones", data.nest2.lname
    assert_equal "Washington", data.nest2.address.city
    assert_equal 20202, data.nest2.address.zip
    assert_equal [:l, :m, :n], data.chain1.chain2.chain3.chain4.chain5.chain6.array
  end

  def test_unknown_key_raises_error_single_level
    input = {
      hello: "World",
      age: 38,
      siblings: ["Barb", "Fred", "Joe"],
    }
    data = Kielce::KielceData.new(input)

    begin
      data.noSuch
      assert_fails "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "noSuch", e.name
    end
  end

  def test_unknown_key_raises_error_level_three
    data = Kielce::KielceData.new(@multi_level_hash_input)

    begin
      data.nest1.address.zip
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "nest1.address.zip", e.name
    end
  end

  def test_unknown_key_raises_error_deep
    data = Kielce::KielceData.new(@multi_level_hash_input)

    begin
      data.chain1.chain2.chain3.chain4.chain5.chain6.fred
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "chain1.chain2.chain3.chain4.chain5.chain6.fred", e.name
    end
  end

  def test_key_named_root_raises_exception
    input = {
      fname: 'john',
      lname: 'adams',
      root: 'carrot',
    }
    
    begin
      data = Kielce::KielceData.new(input)
      assert false, "Should raise InvalidKeyError"
    rescue Kielce::InvalidKeyError => e
      assert_equal :root, e.name
    end
  end

  def test_key_named_inspect_raises_exception
    input = {
      fname: 'john',
      lname: 'adams',
      inspect: 'carrot',
    }
    
    begin
      data = Kielce::KielceData.new(input)
      assert false, "Should raise InvalidKeyError"
    rescue Kielce::InvalidKeyError => e
      assert_equal :inspect, e.name
    end
  end


  def test_key_named_method_missing_raises_exception
    input = {
      fname: 'john',
      lname: 'adams',
      method_missing: 'carrot',
    }
    
    begin
      data = Kielce::KielceData.new(input)
      assert false, "Should raise InvalidKeyError"
    rescue Kielce::InvalidKeyError => e
      assert_equal :method_missing, e.name
    end
  end

  def test_proc_zero_params
    x = 1
    y = 2
    input = {
      test1: -> { x + y },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 74, data.test1()

    y = 19
    assert_equal 52, data.test1()
  end

  def test_deep_proc_zero_params
    x = 1
    y = 2
    input = {
      level1: {
        level2: {
          level3: {
            test2: -> { x + y },
          },
        },
      },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 74, data.level1.level2.level3.test2()

    y = 19
    assert_equal 52, data.level1.level2.level3.test2()
  end

  def test_proc_with_required_arguments_no_keywords
    x = 2
    y = 3
    input = {
      test1: ->(a, b) { x * a + y * b },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 337, data.test1(4, 5)

    y = 19
    assert_equal 558, data.test1(10, 12)
  end

  def test_proc_with_optional_arguments_no_keywords
    x = 2
    y = 3
    input = {
      test1: ->(a = 7, b = 9) { x * a + y * b },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 600, data.test1

    x = 19
    assert_equal 559, data.test1(10)
  end

  def test_proc_with_mixed_arguments_no_keywords
    x = 2
    y = 3
    input = {
      test1: ->(a, b = 9) { x * a + y * b },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 641, data.test1(7, 10)

    x = 19
    assert_equal 559, data.test1(10)
  end

  def test_proc_with_required_keywords_no_arguments
    x = 2
    y = 3
    input = {
      test1: ->(fred:, george:) { x * fred + y * george },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 337, data.test1(fred: 4, george: 5)

    y = 19
    assert_equal 558, data.test1(fred: 10, george: 12)
  end

  def test_proc_with_optional_keywords_no_arguments
    x = 2
    y = 3
    input = {
      test1: ->(fred: 47, george: 19) { x * fred + y * george },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 41
    assert_equal 2330, data.test1

    y = 19
    assert_equal 1779, data.test1(george: 12)

    assert_equal 493, data.test1(fred: 4)
  end

  def test_proc_with_mixed_keywords_no_arguments
    x = 2
    y = 3
    input = {
      test1: ->(fred:, george: 19) { x * fred + y * george },
    }
    data = Kielce::KielceData.new(input)
    x = 33
    y = 19
    assert_equal 493, data.test1(fred: 4)
  end

  def test_proc_with_required_arguments_and_keywords
    input = {
      test1: ->(a, b, fred:, george:) { a * fred + b * george },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 73, data.test1(2, 7, fred: 5, george: 9)
  end

  def test_proc_with_optional_arguments_and_keywords
    input = {
      test1: ->(a = 2, b = 7, fred: 5, george: 9) { a * fred + b * george },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 73, data.test1
    assert_equal 78, data.test1(3)
    assert_equal 81, data.test1(3, fred: 6)
    assert_equal 76, data.test1(4, george: 8)
  end

  def test_proc_with_mixed_arguments_and_keywords
    input = {
      test1: ->(a, b = 7, fred: 5, george:) { a * fred + b * george },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 73, data.test1(2, george: 9)
    assert_equal 39, data.test1(3, 4, fred: 5, george: 6)
  end

  def test_proc_no_params_use_root
    input = {
      nest1: {
        nest2: 16,
      },
      other1: {
        other2: {
          test1: ->() { root.nest1.nest2 * root.more1.more2.stuff },
        },
      },
      more1: {
        more2: {
          stuff: 21,
        },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 336, data.other1.other2.test1
  end

  def test_proc_no_params_use_local_indirect
    input = {
      val1: 11,
      val2: 23,
      other1: {
        other2: {
          test1: ->() { self.val1 * self.val2 + self.nested.val3 },
          val1: 19,
          val2: 4,
          val3: 9,
          nested: {
            val3: 8,
          },
        },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 84, data.other1.other2.test1
  end

  def test_proc_no_params_use_local_direct
    input = {
      val1: 11,
      val2: 23,
      other1: {
        other2: {
          test1: ->() { val1 * val2 + inner.val2 },
          val1: 19,
          val2: 4,
          val3: 43,
          inner: {
            val2: 12,
          },
        },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 88, data.other1.other2.test1
  end

  def test_proc_no_params_use_root_and_local
    input = {
      val1: 11,
      val2: 23,
      other1: {
        other2: {
          test1: ->() { val1 * root.val2 },
          val1: 19,
          val2: 4,
        },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 437, data.other1.other2.test1
  end

  def test_proc_argument_named_root
    # An argument named root will shadow the instance method root that provides
    # access to the other data.
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      nest1: {
        nest2: 16,
      },
      test1: ->(root) { root * 3 },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 132, data.test1(44)
  end

  def test_proc_argument_named_root_generates_warning
    input = {
      nest1: {
        nest2: 16,
      },
      test1: ->(root) { root * 3 },
    }
    data = Kielce::KielceData.new(input)
    data.test1(44)
    assert_equal "WARNING! Lambda parameter named root shadows instance method root.\n", @error_output.string
  end

  def test_use_self_to_avoid_root_shadow
    input = {
      nest1: {
        nest2: 16,
      },
      test1: ->(root) { root * 3 + self.root.nest1.nest2 },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 148, data.test1(44)
  end

  def test_proc_keyword_named_root
    # An argument named root will shadow the instance method root that provides
    # access to the other data.
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      nest1: {
        nest2: 16,
      },
      test1: ->(root:) { root * 3 },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 132, data.test1(root: 44)
  end

  def test_proc_keyword_named_root_generates_warning
    input = {
      nest1: {
        nest2: 16,
      },
      test1: ->(root:) { root * 3 },
    }
    data = Kielce::KielceData.new(input)
    data.test1(root: 44)
    assert_equal "WARNING! Lambda parameter named root shadows instance method root.\n", @error_output.string
  end

  def test_argument_shadows_direct_local
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      nest1: {
        nest2: 16,
        test1: ->(nest2) { nest2 * 5 },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 275, data.nest1.test1(55)
  end

  def test_keyword_shadows_direct_local
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      nest1: {
        nest2: 16,
        test1: ->(nest2:) { nest2 * 5 },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 275, data.nest1.test1(nest2: 55)
  end

  def test_use_self_to_avoid_shadow
    input = {
      nest1: {
        nest2: 16,
        test1: ->(nest2) { nest2 * 5 + self.nest2 },
      },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 291, data.nest1.test1(55)
  end

  def test_proc_can_access_raw_data
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      val1: "Hello",
      test1: ->() { @xx_kielce_data[:val1] },
    }
    data = Kielce::KielceData.new(input)
    assert_equal "Hello", data.test1
  end

  def test_proc_can_modify_raw_data
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      count: 0,
      test1: ->() { @xx_kielce_data[:count] += 1 },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 1, data.test1
    assert_equal 2, data.test1
    assert_equal 3, data.test1
  end

  def test_proc_can_add_instance_variables
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.
    input = {
      init: ->() { @count = 0 },
      count: ->() { @count += 1 },
    }
    data = Kielce::KielceData.new(input)
    assert_equal 0, data.init
    assert_equal 1, data.count
    assert_equal 2, data.count
  end

  def test_data_can_be_objects
    # Note:  This test describes *obeserved* behavior, not necessarily the *desired* behavior.

    obj = Object.new
    def obj.init
      @count = 0
    end
    def obj.count
      @count += 1
    end

    input = {
      counter: obj,
    }

    data = Kielce::KielceData.new(input)
    assert_equal 0, data.counter.init
    assert_equal 1, data.counter.count
    assert_equal 2, data.counter.count
  end

  def test_unknown_key_in_proc_from_root1
    input = {
      level1: {
        level2: {
          test1: ->() { root.noSuch },
        },
      },
    }

    data = Kielce::KielceData.new(input)
    begin
      data.level1.level2.test1
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "noSuch", e.name
    end
  end

  def test_unknown_key_in_proc_from_root2
    input = {
      level1: {
        level2: {
          test1: ->() { root.level1.noSuch },
        },
      },
    }

    data = Kielce::KielceData.new(input)
    begin
      data.level1.level2.test1
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "level1.noSuch", e.name
    end
  end

  def test_unknown_key_in_proc_from_local
    input = {
      level1: {
        level2: {
          test1: ->() { noSuch },
        },
      },
    }

    data = Kielce::KielceData.new(input)
    begin
      data.level1.level2.test1
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "level1.level2.noSuch", e.name
    end
  end

  def test_unknown_key_in_proc_from_self_local
    input = {
      level1: {
        level2: {
          test1: ->() { self.noSuch },
        },
      },
    }

    data = Kielce::KielceData.new(input)
    begin
      data.level1.level2.test1
      assert false, "Should raise NoKeyError"
    rescue Kielce::NoKeyError => e
      assert_equal "level1.level2.noSuch", e.name
    end
  end

  def test_passing_arguments_to_non_proc_generates_warning
    input = {
      val1: 'Hello'
    }
    data = Kielce::KielceData.new(input)
    assert_equal 'Hello', data.val1(1, 2, 3, 4)
    assert_equal "WARNING! val1 is not a function and doesn't expect parameters.\n", @error_output.string
  end

  def test_passing_keywords_to_non_proc_generates_warning
    input = {
      val1: 'Hello'
    }
    data = Kielce::KielceData.new(input)
    assert_equal 'Hello', data.val1(fred: 'flintstone')
    assert_equal "WARNING! val1 is not a function and doesn't expect parameters.\n", @error_output.string
  end

  # KielceData objects convert keys to method calls using
  # the "method_missing" magic.  Thus, treating a key as a method
  # (as shown below) will work.
  # (Note:  This test isn't specifying what *should* happen; it just
  # documents what *does* happen. Feel free to change the behavior, if desired))
  def test_call_method_on_non_proc
    input = {
      test1: "just data",
    }

    data = Kielce::KielceData.new(input)
    assert_equal "just data", data.test1()
  end
end
