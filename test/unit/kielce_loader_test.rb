##############################################################################################
#
# KielceLoaderTest
#
#
# (c) 2020 Zachary Kurmas
##############################################################################################

require "test/unit"
require_relative "unit_test_helper"
require "kielce"

class KielceLoaderTest < Test::Unit::TestCase

  include UnitTestHelper

  #############################################
  #
  # load_file_raw
  #
  #############################################
  def test_load_file_raw_returns_simple_hash
    observed = Kielce::KielceLoader.load_file_raw(f("simple1"), current: {}, context: Object.new)
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
    }

    assert_equal "value_a", observed[:a]
    assert_equal 46, observed[:c]
    assert_equal expected, observed
  end

  def test_load_file_raw_default_parameters_work
    observed = Kielce::KielceLoader.load_file_raw(f("simple1"))
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
    }

    assert_equal "value_a", observed[:a]
    assert_equal 46, observed[:c]
    assert_equal 3, observed.keys.size
    assert_equal expected, observed
  end

  def test_load_file_raw_returns_nested_hash
    observed = Kielce::KielceLoader.load_file_raw(f("nested1"), current: {})
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
      d: {
        d1: 15,
        d2: "value_d2",
        d3: {
          d3a: 11,
          d3b: "value_d3b",
        },
      },
      e: [1, 2, 3, 4, "a"],
      f: [1, 2, { f1: "vf1", f2: 44 }],
    }
    assert_equal "value_a", observed[:a]
    assert_equal 46, observed[:c]
    assert_equal 11, observed[:d][:d3][:d3a]
    assert_equal 2, observed[:f][1]
    assert_equal 44, observed[:f][2][:f2]
    assert_equal expected, observed
  end

  def test_load_file_raw_replaces_data
    initial = {
      a: "initial_value",
      d: "not_replaced",
    }

    observed = Kielce::KielceLoader.load_file_raw(f("simple1"), current: initial, context: Object.new)
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
      d: "not_replaced",
    }

    assert_equal "value_a", observed[:a]
    assert_equal 46, observed[:c]
    assert_equal "not_replaced", observed[:d]
    assert_equal expected, observed
  end

  def test_load_file_raw_non_hash_replaces_hash
    # hashes are only merged when both values are hashes.  If the incoming value is not a hash, the
    # incoming value replaces the hash.
    initial = {
      a: {
        a1: "gone",
        a2: "also gone",
      },
    }
    observed = Kielce::KielceLoader.load_file_raw(f("simple1"), current: initial, context: Object.new)
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
    }

    assert_equal "value_a", observed[:a]
    assert_equal 46, observed[:c]
    assert_equal expected, observed
  end

  def test_load_file_raw_replaces_arrays
    # Notice that arrays are entirely replaced:  We make no attempt to merge them.  (It is not clear that such a feature would
    # be useful.  Even if it was occasionally useful, it's not clear that merging would be the preferred behavior.  It's also
    # not clear how we could distinguish which behavior is desired.)
    initial = {
      e: [:a, :b, :c],
      g: [:q, :r, :s],
    }

    observed = Kielce::KielceLoader.load_file_raw(f("nested1"), current: initial, context: Object.new)
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
      d: {
        d1: 15,
        d2: "value_d2",
        d3: {
          d3a: 11,
          d3b: "value_d3b",
        },
      },
      e: [1, 2, 3, 4, "a"],
      f: [1, 2, { f1: "vf1", f2: 44 }],
      g: [:q, :r, :s],
    }
    assert_equal 1, observed[:e][0]
    assert_equal "a", observed[:e][4]
    assert_equal :s, observed[:g][2]
    assert_equal expected, observed
  end

  def test_load_file_raw_deep_merges_hashes
    initial = {
      d: {
        d1: "should_be_replaced",
        d4: "should_remain",
        d3: {
          d3a: "should_be_replaced",
          d3c: "new value",
        },
        d5: {
          d5a: "still here",
          d5b: 443,
        },
      },
    }

    observed = Kielce::KielceLoader.load_file_raw(f("nested1"), current: initial, context: Object.new)
    expected = {
      a: "value_a",
      b: "value_b",
      c: 46,
      d: {
        d1: 15,
        d2: "value_d2",
        d3: {
          d3a: 11,
          d3b: "value_d3b",
          d3c: "new value",
        },
        d4: "should_remain",
        d5: {
          d5a: "still here",
          d5b: 443,
        },
      },
      e: [1, 2, 3, 4, "a"],
      f: [1, 2, { f1: "vf1", f2: 44 }],
    }

    assert_equal 11, observed[:d][:d3][:d3a]
    assert_equal "new value", observed[:d][:d3][:d3c]
    assert_equal "should_remain", observed[:d][:d4]
    assert_equal "still here", observed[:d][:d5][:d5a]
    assert_equal expected, observed
  end

  def test_load_file_raw_hashes_in_arrays_not_merged
    # Arrays are always replaced in their entirety.  In particular, Hashes inside arrays are not merged.
    # This test *describes* the current behavior.  It does not necessarily *request* that behavior.
    # In other words, this test documents that hashes inside arrays are not merged.  That does not mean that
    # we don't believe they shouldn't be merged, it just means that we didn't write code to merge them.
    # (Having said that, we can see some potential issues with such a feature, so think carefuly before implementing it.)
    initial = {
      f: [1, 2, { f1: "original f1", f3: "original f3" }],
    }
    observed = Kielce::KielceLoader.load_file_raw(f("nested1"), current: initial, context: Object.new)
    assert_equal "vf1", observed[:f][2][:f1]
    assert_false observed[:f][2].has_key?(:f3)
  end

  def test_load_file_raw_retains_instance_variables
    # Instance variables created/assigned in the data files are accessible
    # after the load method terminates.
    context = Object.new
    observed = Kielce::KielceLoader.load_file_raw(f("instance1"), current: {}, context: context)
    assert_equal "first", context.instance_eval { @instance_a }
    assert_equal 19, context.instance_eval { @instance_b }
  end

  def test_load_file_raw_retains_instance_methods
    # Methods defined in the data file are added to the context object.
    context = Object.new
    observed = Kielce::KielceLoader.load_file_raw(f("instance1"), context: context)
    assert_true context.respond_to?("say_hi")
    assert_equal "Hello", context.say_hi
  end

  def test_load_file_raw_replaces_existing_instance_variables
    context = Object.new
    context.instance_eval { @instance_a = 442, @instance_c = "still here" }
    observed = Kielce::KielceLoader.load_file_raw(f("instance1"), context: context)
    assert_equal "first", context.instance_eval { @instance_a }
    assert_equal 19, context.instance_eval { @instance_b }
    assert_equal "still here", context.instance_eval { @instance_c }
  end

  def test_load_file_raw_replaces_existing_methods
    context = Object.new
    def context.say_hi
      "It's good to see you"
    end

    def context.speak
      "Woof"
    end
    observed = Kielce::KielceLoader.load_file_raw(f("instance1"), context: context)
    assert_true context.respond_to?("say_hi")
    assert_equal "Hello", context.say_hi
    assert_true context.respond_to?("speak")
    assert_equal "Woof", context.speak
  end

  def test_load_file_raw_returns_empty_if_empty_file
    observed = Kielce::KielceLoader.load_file_raw(f("empty"), current: {}, context: Object.new)
    expected = {}
    assert_equal expected, observed
    assert_equal 0, observed.keys.size
  end

  def test_load_file_raw_returns_empty_if_nil_return
    observed = Kielce::KielceLoader.load_file_raw(f("nil_return"))
    expected = {}
    assert_equal expected, observed
    assert_equal 0, observed.keys.size
  end

  def test_load_file_raw_correctly_merges_empty
    observed = Kielce::KielceLoader.load_file_raw(f("empty"), current: { a: "first" })
    expected = {
      a: "first",
    }
    assert_equal expected, observed
  end

  def test_load_file_raw_correctly_merges_nil
    observed = Kielce::KielceLoader.load_file_raw(f("nil_return"), current: { a: "first" })
    expected = {
      a: "first",
    }
    assert_equal expected, observed
  end

  def test_load_file_raw_complains_if_hash_not_returned_string
    assert_raises(Kielce::LoadingError) { Kielce::KielceLoader.load_file_raw(f("string_return")) }
  end

  def test_load_file_raw_complains_if_hash_not_returned_array
    assert_raises(Kielce::LoadingError) { Kielce::KielceLoader.load_file_raw(f("array_return")) }
  end

  def test_load_file_raw_raises_exception_if_file_not_found
    # This test describes what *does* happen.  It is not intended to describe what should happen.
    # This is the default behavior. We see no reason not to change it should the need arise.
    assert_raises(Errno::ENOENT) { Kielce::KielceLoader.load_file_raw(f("no_such_file")) }
  end

  #############################################
  #
  # load_directory_raw
  #
  #############################################

  # We test differently entered start and stop paths to make sure there aren't any quirks
  # with how File and Pathname represent and compare paths with '.', '..', symlinks, etc.
  def merges_all_files_in_heirarchy(start_path, stop_path)
    context = Object.new
    initial_data = {
      common: "initial_data",
      unique_initial: "12345",
    }

    observed = Kielce::KielceLoader.load_directory_raw(start_path, current: initial_data, context: context, stop_dir: stop_path)

    expected = {
      common: "data from 1a1a-d1",
      unique_initial: "12345",
      unique_1a1a_d1: "43234334",
      unique_1a1_d1: "343234",
      unique_1a_d1: "54321",
      unique_1_d1: "4885",
      array: [:g],
    }

    assert_equal 7, observed.keys.size
    assert_equal "data from 1a1a-d1", expected[:common]
    assert_equal expected, observed

    assert_equal "Keep Me", context.instance_eval { @common_instance }
    assert_equal "i1d1", context.instance_eval { @instance_1_d1 }
    assert_equal "i1ad1", context.instance_eval { @instance_1a_d1 }
    assert_equal "i1a1d1", context.instance_eval { @instance_1a1_d1 }
    assert_equal "i1a1ad1", context.instance_eval { @instance_1a1a_d1 }
  end

  def test_load_directory_raw_merges_all_files_in_hierarchy_regular
    start_path = Pathname.new(f("dir1/dir1a/dir1a1/dir1a1a"))
    stop_path = Pathname.new(f(""))
    merges_all_files_in_heirarchy(start_path, stop_path)
  end

  def test_load_directory_raw_merges_all_files_in_hierarchy_stop_v1
    start_path = Pathname.new(f("dir1/dir1a/dir1a1/dir1a1a"))
    stop_path = Pathname.new(f("dir1/dir1a/../dir1a/../.."))
    merges_all_files_in_heirarchy(start_path, stop_path)
  end

  def test_load_directory_raw_stop_path_sym_link
    start_path = Pathname.new(f("dir1/dir1a/dir1a1/dir1a1a"))
    # dir_sa1 is a symlink back to dir1
    stop_path = Pathname.new(f("dir_s/dir_sa/dir_sa1/"))
    merges_all_files_in_heirarchy(start_path, stop_path)
  end

  def test_load_directory_raw_stops_at_root_if_stop_path_not_encountered
    # dir2 is not on the path to dir1a1a.  Thus, the typical stop
    # condition is never met.  To avoid a stack overflow, the algorithm
    # stops at the root.
    #
    # IMPORTANT: This test will fail if there are kielce_data files between
    # the project root and the file system root
    start_path = Pathname.new(f("dir1/dir1a/dir1a1/dir1a1a"))
    stop_path = Pathname.new(f("dir2"))
    merges_all_files_in_heirarchy(start_path, stop_path)
  end

  def test_load_directory_raw_stops_at_root_if_stop_path_nil
    # IMPORTANT: This test will fail if there are kielce_data files between
    # the project root and the file system root
    start_path = Pathname.new(f("dir1/dir1a/dir1a1/dir1a1a"))
    stop_path = nil
    merges_all_files_in_heirarchy(start_path, stop_path)
  end

  def test_load_directory_raw_loads_all_in_single_dir
    start_path = Pathname.new(f("dir2"))
    stop_path = Pathname.new(f(""))
    observed = Kielce::KielceLoader.load_directory_raw(start_path, stop_dir: stop_path)

    assert_equal 4, observed.keys.length
    assert_equal "Michigan", observed[:d2_d1]
    assert_equal "Ohio", observed[:d2_d2]
    assert_equal "China", observed[:d2_all_shared]
    assert_true observed[:d2_shard] == "Poland" || observed[:d2_shared] == "Portugal"
  end

  def test_load_directory_raw_loads_all_in_several_dir
    start_path = Pathname.new(f("dir2/dir2a"))
    stop_path = Pathname.new(f(""))
    observed = Kielce::KielceLoader.load_directory_raw(start_path, current: {}, stop_dir: stop_path)

    assert_equal 7, observed.keys.length
    assert_equal "Michigan", observed[:d2_d1]
    assert_equal "Ohio", observed[:d2_d2]
    assert_true observed[:d2_shared] == "Poland" || observed[:d2_shared] == "Portugal"
    assert_equal "Georgia", observed[:d2a_d1]
    assert_equal "Florida", observed[:d2a_d2]
    assert_true observed[:d2a_shared] == "Germany" || observed[:d2a_shared] == "Japan"
    assert_equal "Mongolia", observed[:d2_all_shared]
  end

  def test_load_directory_raw_raises_exception_if_start_not_found
    # This test describes what *does* happen.  It is not intended to describe what should happen.
    # This is the default behavior. We see no reason not to change it should the need arise.
    assert_raises(Errno::ENOENT) do
      Kielce::KielceLoader.load_directory_raw(Pathname.new(f("no_such_file")))
    end
  end

  #############################################
  #
  # load_directory
  #
  #############################################

  KielceLoader2 = Kielce::KielceLoader.clone

  # Create a "mock" KielceLoader with a mock +load_directory_raw+ so we can verify that
  # the +load+ method calls +load_directory_raw+ with the correct parameters.
  class KielceLoader2
    class << self
      attr_reader :observed_start, :observed_current, :observed_context, :observed_stop

      def load_directory_raw(start, current:, context:, stop_dir:)
        @observed_start = start
        @observed_current = current
        @observed_context = context
        @observed_stop = stop_dir
        {}
      end
    end
  end

  def test_load_with_dir_name
    start_dir_name = f('dir1/dir1a')
    stop_dir_name = f('dir1')
    KielceLoader2.load(start_dir_name, current: :the_current, context: :the_context, stop_dir: stop_dir_name)
    assert_equal Pathname.new(File.absolute_path(start_dir_name)), KielceLoader2.observed_start
    assert_equal :the_current, KielceLoader2.observed_current
    assert_equal :the_context, KielceLoader2.observed_context
    assert_equal Pathname.new(File.absolute_path(stop_dir_name)), KielceLoader2.observed_stop
  end

  def test_load_with_file_name
    start_dir_name = f('dir1/dir1a')
    start_file_name = f('dir1/dir1a/kielce_data_dir1a_d1.rb')
    stop_dir_name = f('dir1')
    KielceLoader2.load(start_file_name, current: :the_current, context: :the_context, stop_dir: stop_dir_name)
    assert_equal Pathname.new(File.absolute_path(start_dir_name)), KielceLoader2.observed_start
    assert_equal :the_current, KielceLoader2.observed_current
    assert_equal :the_context, KielceLoader2.observed_context
    assert_equal Pathname.new(File.absolute_path(stop_dir_name)), KielceLoader2.observed_stop
  end

  def test_load_with_default_params
    start_dir_name = f('dir1/dir1a')
    KielceLoader2.load(start_dir_name)
    assert_equal Pathname.new(File.absolute_path(start_dir_name)), KielceLoader2.observed_start
    expected = {}
    assert_equal expected, KielceLoader2.observed_current
    assert_equal Object, KielceLoader2.observed_context.class
    assert_nil KielceLoader2.observed_stop
  end
end
