require_relative 'spec_helper'

def create_option(**opts, &blk)
  Luban::CLI::Option.new(:test, "Test option", **opts, &blk)
end

describe Luban::CLI::Option do
  it "creates an option with default config" do
    opt = create_option
    opt.default_imperative.must_equal false
    opt.required?.must_equal false
    opt.optional?.must_equal true
    opt.default_str.must_be_empty
    opt.multiple?.must_equal false
  end

  it "sets its kind correctly" do
    create_option.kind.must_equal "option"
  end

  it "builds specs with description" do
    create_option.specs.must_include "Test option"
  end

  it "builds specs with long option" do
    create_option.specs.must_include "--test TEST"
  end

  it "builds specs with customized long opt name" do
    create_option(long: "my_option").specs.must_include "--my-option TEST"
  end

  it "builds specs with short option" do
    create_option(short: :t).specs.must_include "-t"
    create_option(short: "t").specs.must_include "-t"
  end

  it "supports options with multiple arguments" do 
    create_option(multiple: true).specs.must_include Array
  end

  it "builds specs with default values" do
    create_option(default: "value").default_str.must_equal "--test \"value\""
    [[:string, ["value1", "value2"], "--test \"value1,value2\""],
     [:integer, [1, 2], "--test \"1,2\""],
    ].each do |type, default, expected|
      create_option(type: type, multiple: true, default: default).default_str.must_equal expected
    end
  end
end

def create_nullable_option(**opts, &blk)
  Luban::CLI::NullableOption.new(:test, "Test option", **opts, &blk)
end

describe Luban::CLI::NullableOption do
  it "sets its kind correctly" do
    create_nullable_option.kind.must_equal "nullable option"
  end

  it "builds specs with long option" do
    create_nullable_option.specs.must_include "--test [TEST]"
  end

  it "builds specs with customized long opt name" do
    create_nullable_option(long: "my_option").specs.must_include "--my-option [TEST]"
  end

  it "sets true when nil value is presented" do
    opt = create_nullable_option
    opt.value.must_equal nil
    opt.value = nil
    opt.value.must_equal true
  end
end