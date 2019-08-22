require 'spec_helper'
require 'test_components'

describe 'callbacks', js: true do
  before(:all) do
    class ActiveRecord::Base
      class << self
        def public_columns_hash
          @public_columns_hash ||= {}
        end
      end
    end
  end

  describe 'before_validation update_permalink on create', js: true do
    before(:each) do
      policy_allow_all

      isomorphic do
        class ModelWithPermalink < ActiveRecord::Base

          def self.build_tables
            connection.create_table(:model_with_permalinks, force: true) do |t|
              t.string :permalink, null: false
              t.timestamps
            end
            ActiveRecord::Base.public_columns_hash[name] = columns_hash
          end

          before_validation :update_permalink, on: :create

          def update_permalink
            return if self.permalink.present?
            self.permalink = 'permalink' # fake
          end
        end
      end

      ModelWithPermalink.build_tables
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
end
