##############################################################################################
#
# KielceTest
#
# Note: There are no unit tests for the Render method.  Render is tested with 
#       system tests only
#
# (c) 2020 Zachary Kurmas
##############################################################################################

require "test/unit"
require_relative "unit_test_helper"
require "kielce"

class KielceTest < Test::Unit::TestCase

  include UnitTestHelper

  def setup
    @k = Kielce::Kielce.new(:context)
  end

  #############################################
  #
  # load_file_raw
  #
  #############################################
  def test_http_link_no_params
    observed = @k.link('http://some.url.com/p1/show.html')
    assert_equal "<a href='http://some.url.com/p1/show.html'><code>http://some.url.com/p1/show.html</code></a>", observed
  end

  def test_https_link_no_params
    observed = @k.link('https://some.url.com/p1/show.html')
    assert_equal "<a href='https://some.url.com/p1/show.html'><code>https://some.url.com/p1/show.html</code></a>", observed
  end

  def test_http_link_no_params_no_code
    observed = @k.link('http://some.url.com/p1/show.html', code: false)
    assert_equal "<a href='http://some.url.com/p1/show.html'>http://some.url.com/p1/show.html</a>", observed
  end

  def test_https_link_no_params_no_code
    observed = @k.link('https://some.url.com/p1/show.html', code: false)
    assert_equal "<a href='https://some.url.com/p1/show.html'>https://some.url.com/p1/show.html</a>", observed
  end

  def test_link_and_text
    observed = @k.link('http://some.url.com/p1/show.html', 'the text')
    assert_equal "<a href='http://some.url.com/p1/show.html'>the text</a>", observed
  end

  def test_link_and_text_using_code
    observed = @k.link('http://some.url.com/p1/show.html', 'the text', code: true)
    assert_equal "<a href='http://some.url.com/p1/show.html'><code>the text</code></a>", observed
  end

  def test_class_list_no_code
    observed = @k.link('http://some.url.com/p1/show.html', 'the text', classes: 'a b c')
    assert_equal "<a href='http://some.url.com/p1/show.html' class='a b c'>the text</a>", observed
  end

  def test_class_list_with_code
    observed = @k.link('http://some.url.com/p1/show.html', 'the text', code: true, classes: 'a b c')
    assert_equal "<a href='http://some.url.com/p1/show.html' class='a b c'><code>the text</code></a>", observed
  end

  def test_class_list_with_no_text
    observed = @k.link('http://short.com', classes: 'a b c')
    assert_equal "<a href='http://short.com' class='a b c'><code>http://short.com</code></a>", observed
  end

  def test_class_list_with_no_text_no_code
    observed = @k.link('http://short.com', classes: 'a b c', code: false)
    assert_equal "<a href='http://short.com' class='a b c'>http://short.com</a>", observed
  end

  def test_target_blank_str
    observed = @k.link('http://short.com', target: '_blank')
    assert_equal "<a target='_blank' href='http://short.com'><code>http://short.com</code></a>", observed
  end

  def test_class_list_with_target_top_str
    observed = @k.link('http://short.com', classes: 'a b e', target: '_top')
    assert_equal "<a target='_top' href='http://short.com' class='a b e'><code>http://short.com</code></a>", observed
  end

  def test_target_blank_sym
    observed = @k.link('http://short.com', target: :blank)
    assert_equal "<a target='_blank' href='http://short.com'><code>http://short.com</code></a>", observed
  end

  def test_class_list_with_target_top_sym
    observed = @k.link('http://short.com', classes: 'a b e', target: :top)
    assert_equal "<a target='_top' href='http://short.com' class='a b e'><code>http://short.com</code></a>", observed
  end


end