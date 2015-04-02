require_relative 'spec_helper'

def create_argument(**args, &blk)
  Luban::CLI::Argument.new(:test, "Test argument", **args, &blk)
end

describe Luban::CLI::Argument do
  it "creates an argument with default config" do
    arg = create_argument
    arg.name.must_equal :test
    arg.display_name.must_equal "TEST"
    arg.description.must_equal "Test argument"
    arg.default_imperative.must_equal true
    arg.required?.must_equal true
    arg.optional?.must_equal false
    arg.multiple?.must_equal false
    arg.has_default?.must_equal false
    arg.default_type.must_equal :string
    arg[:type].must_equal arg.default_type
  end

  it "creates an argument with non-default config" do
    arg = create_argument(required: false, multiple: true, type: :symbol, default: [:value])
    arg.name.must_equal :test
    arg.display_name.must_equal "TEST"
    arg.description.must_equal "Test argument"
    arg.required?.must_equal false
    arg.optional?.must_equal true
    arg.value.must_equal [:value] 
    arg.multiple?.must_equal true
    arg.has_default?.must_equal true
    arg[:type].must_equal :symbol
  end

  it "sets its kind correctly" do
    create_argument.kind.must_equal "argument"
  end

  it "verifies config type" do
    [:string, :integer, :float, :symbol, 
     :time, :date, :datetime, :bool].each do |type|
      assert_silent { create_argument(type: type) }
    end
    assert_raises(ArgumentError) { create_argument(type: :array) }
  end 

  it "verifies config default value" do
    [ { type: :integer, default: 10 },
      { type: :integer, default: [10, 20], multiple: true },
      { type: :integer, default: [], multiple: true },
      { type: :string,  default: "right pattern", match: /^right pattern/ },
      { type: :symbol,  default: [:sym1, :sym2], multiple: true, within: [:sym1, :sym2, :sym3] },
      { type: :integer, default: [10, 50, 100], multiple: true, within: 10..100 },
      { type: :integer, default: [10, 50, 90], multiple: true, assure: ->(v) { v < 100 } } 
    ].each do |config|
      arg = nil
      assert_silent { arg = create_argument(**config) }
      arg[:type].must_equal config[:type]
      arg[:default].must_equal config[:default]
    end

    [ { type: :integer, default: "10" },
      { type: :integer, default: "10", multiple: true },
      { type: :integer, default: [10, "20"], multiple: true },
      { type: :string,  default: "wrong pattern", match: /^right pattern/ },
      { type: :symbol,  default: [:sym1, :sym4], multiple: true, within: [:sym1, :sym2, :sym3] },
      { type: :integer, default: [10, 50, 120], multiple: true, within: 10..100 },
      { type: :integer, default: [10, 50, 120], multiple: true, assure: ->(v) { v < 100 } }
    ].each do |config|
      assert_raises(ArgumentError) { create_argument(type: :integer, **config) }
    end
  end

  it "verifies config match" do
    arg = nil
    assert_silent { arg = create_argument(match: /^Test/) }
    arg[:match].must_equal /^Test/

    assert_raises(ArgumentError) { create_argument(match: 100) }
  end

  it "verifies config within" do
    arg = nil
    [ [0, 1], (0..10) ].each do |range|
      assert_silent { arg = create_argument(within: range) }
      arg[:within].must_equal range
    end

    assert_raises(ArgumentError) { create_argument(within: 100) }
  end

  it "verifies config assurance" do
    arg = nil
    assert_silent { arg = create_argument(assure: ->(v) { true }) }
    assert_raises(ArgumentError) { create_argument(assure: "wrong validation") }
  end

  it "sets default value" do
    arg = create_argument(type: :integer, default: 5)
    arg.has_default?.must_equal true
    arg.value.must_equal 5

    require 'time'
    arg = create_argument(type: :time, default: Time.parse("2011-10-05T22:26:12-04:00"))
    arg.has_default?.must_equal true
    arg.value.must_equal Time.parse("2011-10-05T22:26:12-04:00") 
  end

  it "casts value to the specified object" do
    require "time"
    iso8601_dates = ["2011-10-05T22:26:12-04:00", "2015-03-06T08:26:12-04:00"]
    times = iso8601_dates.collect { |d| Time.parse(d) }
    dates = iso8601_dates.collect { |d| Date.parse(d) }
    datetimes = iso8601_dates.collect { |d| DateTime.parse(d) }
    [[false, :string, "abc", "abc"],
     [true,  :string, ["abc", "def"], ["abc", "def"]],
     [false, :integer, "10", 10], 
     [true,  :integer, ["10", "20"], [10, 20]], 
     [false, :float, "1.2", 1.2],
     [true,  :float, ["1.2", "2.1"], [1.2, 2.1]],
     [false, :symbol, "symbol1", :symbol1],
     [true,  :symbol, ["symbol1", "symbol2"], [:symbol1, :symbol2]],
     [false, :time, iso8601_dates[0], times[0]],
     [true,  :time, iso8601_dates.clone, times], 
     [false, :date, iso8601_dates[0], dates[0]],
     [true,  :date, iso8601_dates.clone, dates],
     [false, :dateTime, iso8601_dates[0], datetimes[0]],
     [true,  :dateTime, iso8601_dates.clone, datetimes],
     [false, :bool, "true",  true],
     [false, :bool, "false", false],
     [false, :bool, "yes",  true],
     [false, :bool, "no", false],
     [false, :bool, "wrong bool", false],
     [true,  :bool, ["true", "false"], [true, false]],
     [true,  :bool, ["true", false], [true, false]],
     [true,  :bool, ["yes", "no"], [true, false]],
     [true,  :bool, ["wrong bool", "invalid bool"], [false, false]]
    ].each do |multiple, type, value, expected|
      arg = create_argument(type: type, multiple: multiple)
      arg.value = value
      arg.value.must_equal expected
    end
  end

  it "sets value" do
    arg = create_argument(type: :integer) { |v| v >= 100 ? 50 : v }
    arg.value = "10"
    arg.value.must_equal 10
    arg.value = "200"
    arg.value.must_equal 50
  end

  it "resets value" do
    arg = create_argument(type: :integer, default: 5)
    arg.value = "10"
    arg.value.must_equal 10
    arg.reset
    arg.value.must_equal 5
  end

  it "validates required value" do
    arg = create_argument(required: true)
    arg.valid?.must_equal false
    arg.missing?.must_equal true
    arg = create_argument(required: false)
    arg.valid?.must_equal true
    arg.missing?.must_equal false
  end

  it "validates value matching" do
    arg = create_argument(match: /^Matched/)
    arg.valid?("Matched value").must_equal true
    arg.valid?("Mismatched value").must_equal false
    assert_raises(Luban::CLI::Argument::InvalidArgumentValue) { arg.value = "Mismatched value" }
  end

  it "validates value within" do
    [[["a", "b", "c"], "d"], [1..10, 11]].each do |range, out_of_range|
      arg = create_argument(within: range)
      range.each { |v| arg.valid?(v).must_equal true }
      arg.valid?(out_of_range).must_equal false
      assert_raises(Luban::CLI::Argument::InvalidArgumentValue) { arg.value = out_of_range }
    end
  end

  it "validates value" do
    arg = create_argument(type: :integer, assure: ->(v) { v >= 5 })
    arg.valid?(10).must_equal true
    arg.valid?(1).must_equal false
    assert_raises(Luban::CLI::Argument::InvalidArgumentValue) { arg.value = 1 }
  end
end
