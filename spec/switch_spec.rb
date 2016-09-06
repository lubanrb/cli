require_relative 'spec_helper'

def create_switch(**opts, &blk)
  Luban::CLI::Switch.new(:test, "Test switch", **opts, &blk)
end

describe Luban::CLI::Switch do
  it "sets its kind correctly" do
    create_switch.kind.must_equal "switch"
  end

  it "ensures value type to be boolean" do
    create_switch[:type].must_equal :bool
    create_switch(type: :integer)[:type].must_equal :bool
  end

  it "ensures single value instead of multiple" do 
    create_switch.multiple?.must_equal false
    create_switch(multiple: true).multiple?.must_equal false
  end

  it "ensures default switch status is set properly" do
    [[{default: true}, true], 
     [{default: false}, false],
     [{}, nil]].each do |config, expected|
      create_switch(**config)[:default].must_equal expected 
    end
  end

  it "builds specs with long option" do
    create_switch.specs.must_include "--test"
  end

  it "builds specs with customized long opt name" do
    create_switch(long: "my_switch").specs.must_include "--my-switch"
  end

  it "builds specs with default values" do
    [[{default: true}, "--test"], 
     [{default: false}, ""],
     [{}, ""]].each do |config, expected|
      create_switch(**config).default_str.must_equal expected
    end
  end
end

def create_negatable_switch(**opts, &blk)
  Luban::CLI::NegatableSwitch.new(:test, "Test switch", **opts, &blk)
end

describe Luban::CLI::NegatableSwitch do
  it "sets its kind correctly" do
    create_negatable_switch.kind.must_equal "negatable switch"
  end

  it "builds specs with long option" do
    create_negatable_switch.specs.must_include "--[no-]test"
  end

  it "builds specs with customized long opt name" do
    create_negatable_switch(long: "my_switch").specs.must_include "--[no-]my-switch"
  end

  it "builds specs with default values" do
    [[{default: true}, "--test"], 
     [{default: false}, "--no-test"], 
     [{}, "--no-test"]].each do |config, expected|
      create_negatable_switch(**config).default_str.must_equal expected
    end
  end
end

