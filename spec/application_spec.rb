require_relative 'spec_helper'

describe Luban::CLI::Application do
  it "sets up default application" do
    app = Luban::CLI::Application.new { program 'test_app' }
    assert_respond_to(app, :run)
    app.rc.must_equal app.default_rc
    app.default_rc.must_be_empty
    app.rc_file.must_equal '.test_apprc'
    app.rc_path.to_s.must_equal "#{ENV['HOME']}/.test_apprc"
    app.rc_file_exists?.must_equal false
  end

  it "loads rc file" do
    File.open(TMP_RC_FILE, 'w') { |f| f.write(RC_CONTENT) }
    klass = Class.new Luban::CLI::Application do
              def rc_path; TMP_RC_FILE; end
            end
    app = klass.new { program 'test_app' }
    app.rc.wont_be_empty
    app.rc['stages'].must_equal ['production', 'sandbox', 'staging']
    app.rc['default_stage'].must_equal 'staging'
    File.delete(TMP_RC_FILE)
  end
end

TMP_RC_FILE = "/tmp/.test_apprc"
RC_CONTENT = <<-CONTENT
stages:
  - production
  - sandbox
  - staging
default_stage: staging
CONTENT