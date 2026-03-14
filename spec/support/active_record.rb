# frozen_string_literal: true

require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email
    t.text :bio
    t.timestamps
  end
end

class User < ActiveRecord::Base
  validates :name, presence: true
  validates :email, format: {with: /\A[^@\s]+@[^@\s]+\z/, allow_blank: true}
end
