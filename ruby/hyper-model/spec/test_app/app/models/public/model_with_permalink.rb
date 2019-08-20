class ModelWithPermalink < ActiveRecord::Base

  def update_permitted?
    return true
  end

  def self.create_table
    connection.create_table(self.name.tableize, force: true) do |t|
      t.string :permalink, null: false
    end
  end

  before_validation :update_permalink, on: :create

  def update_permalink
    return unless self.permalink.present?
    self.permalink = 'permalink' # fake
  end

end
