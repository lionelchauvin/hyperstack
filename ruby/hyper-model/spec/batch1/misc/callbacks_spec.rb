require 'spec_helper'
require 'test_components'
require 'rspec-steps'

RSpec::Steps.steps "before_validation update_permalink on create", js: true do

  before(:step) do
    ModelWithPermalink.create_table
  end

  it "should be called" do
    expect_promise do
      model = ModelWithPermalink.new
      model.save.then do
        model.permalink.present?
      end
    end.to be_truthy
  end

end
