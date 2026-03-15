# frozen_string_literal: true

require "support/active_record"

RSpec.describe Ratamin::ScopeDataSource do
  before do
    User.delete_all
    User.create!(name: "Alice", email: "alice@example.com", bio: "Engineer")
    User.create!(name: "Bob", email: "bob@example.com", bio: "Designer")
    User.create!(name: "Charlie", email: "charlie@example.com", bio: "A long bio " * 10)
  end

  describe "with inferred columns" do
    subject(:ds) { described_class.new(User.all) }

    it "infers columns from the model" do
      keys = ds.columns.map(&:key)
      expect(keys).to include(:id, :name, :email, :bio)
    end

    it "maps text columns to :text type" do
      bio_col = ds.columns.find { |c| c.key == :bio }
      expect(bio_col.type).to eq(:text)
    end

    it "maps string columns to :string type" do
      name_col = ds.columns.find { |c| c.key == :name }
      expect(name_col.type).to eq(:string)
    end

    it "loads rows from the scope" do
      expect(ds.row_count).to eq(3)
      expect(ds.rows[0][:name]).to eq("Charlie")
    end

    it "marks id as non-editable" do
      id_col = ds.columns.find { |c| c.key == :id }
      expect(id_col.editable).to be false
    end

    it "marks timestamps as non-editable" do
      %i[created_at updated_at].each do |key|
        col = ds.columns.find { |c| c.key == key }
        expect(col.editable).to be(false), "expected #{key} to be non-editable"
      end
    end

    it "marks regular columns as editable" do
      name_col = ds.columns.find { |c| c.key == :name }
      expect(name_col.editable).to be true
    end
  end

  describe "with model config (has_ratamin)" do
    around do |example|
      User.include(Ratamin::ModelMixin)
      User.has_ratamin do
        column :name, label: "Full Name", width: 20
        column :bio
        column :created_at
      end
      example.run
      User.instance_variable_set(:@ratamin_config, nil)
    end

    subject(:ds) { described_class.new(User.all) }

    it "uses columns from model config" do
      expect(ds.columns.map(&:key)).to eq(%i[name bio created_at])
    end

    it "respects label override from config" do
      col = ds.columns.find { |c| c.key == :name }
      expect(col.label).to eq("Full Name")
    end

    it "only includes configured columns in rows" do
      expect(ds.rows[0].keys).to eq(%i[name bio created_at])
    end

    it "inherits type from schema (text column stays :text)" do
      col = ds.columns.find { |c| c.key == :bio }
      expect(col.type).to eq(:text)
    end

    it "inherits editable: false for readonly schema columns" do
      col = ds.columns.find { |c| c.key == :created_at }
      expect(col.editable).to be false
    end

    it "falls back to infer when config is absent" do
      User.instance_variable_set(:@ratamin_config, nil)
      ds2 = described_class.new(User.all)
      expect(ds2.columns.map(&:key)).to include(:id, :name, :email, :bio)
    end

    it "does not cause stack overflow when User.ratamin is called without Railtie" do
      app_double = instance_double(Ratamin::App, run: nil)
      allow(Ratamin::App).to receive(:new).and_return(app_double)
      expect { User.ratamin }.not_to raise_error
    end
  end

  describe "with explicit columns" do
    let(:columns) do
      [
        Ratamin::Column.new(key: :name, width: 20),
        Ratamin::Column.new(key: :email, width: 30)
      ]
    end

    subject(:ds) { described_class.new(User.all, columns: columns) }

    it "uses the provided columns" do
      expect(ds.columns.map(&:key)).to eq(%i[name email])
    end

    it "only includes specified columns in rows" do
      expect(ds.rows[0].keys).to eq(%i[name email])
    end
  end

  describe "with a filtered scope" do
    subject(:ds) { described_class.new(User.where(name: "Alice")) }

    it "only loads matching records" do
      expect(ds.row_count).to eq(1)
      expect(ds.rows[0][:name]).to eq("Alice")
    end
  end

  describe "#update_row" do
    subject(:ds) { described_class.new(User.all) }

    it "saves valid changes and returns success" do
      result = ds.update_row(0, {"name" => "Alicia"})
      expect(result).to be_ok
      expect(User.find_by(name: "Alicia")).not_to be_nil
    end

    it "returns failure with errors on invalid changes" do
      result = ds.update_row(0, {"name" => ""})
      expect(result).to be_failed
      expect(result.errors).to include(match(/Name/))
    end

    it "does not persist invalid changes" do
      ds.update_row(0, {"name" => ""})
      expect(User.first.name).to eq("Alice")
    end

    it "returns failure for invalid email format" do
      result = ds.update_row(0, {"email" => "not-an-email"})
      expect(result).to be_failed
      expect(result.errors).to include(match(/Email/))
    end
  end

  describe "#reload!" do
    subject(:ds) { described_class.new(User.all) }

    it "refreshes data from the database" do
      expect(ds.row_count).to eq(3)
      User.create!(name: "Diana", email: "diana@example.com")
      ds.reload!
      expect(ds.row_count).to eq(4)
    end
  end

  describe "pagination" do
    before do
      User.delete_all
      10.times { |i| User.create!(name: "User #{i}", email: "user#{i}@example.com") }
    end

    subject(:ds) { described_class.new(User.all, per_page: 3) }

    it "is paginated" do
      expect(ds).to be_paginated
    end

    it "starts on page 1" do
      expect(ds.page).to eq(1)
    end

    it "loads only per_page records" do
      expect(ds.row_count).to eq(3)
    end

    it "reports total_count" do
      expect(ds.total_count).to eq(10)
    end

    it "calculates total_pages" do
      expect(ds.total_pages).to eq(4) # ceil(10/3)
    end

    it "navigates to next page" do
      ds.next_page
      expect(ds.page).to eq(2)
      expect(ds.rows[0][:name]).to eq("User 6")
    end

    it "navigates to previous page" do
      ds.next_page
      ds.prev_page
      expect(ds.page).to eq(1)
    end

    it "does not go below page 1" do
      ds.prev_page
      expect(ds.page).to eq(1)
    end

    it "does not go past last page" do
      4.times { ds.next_page }
      expect(ds.page).to eq(4)
      ds.next_page
      expect(ds.page).to eq(4)
    end

    it "last page may have fewer records" do
      3.times { ds.next_page }
      expect(ds.page).to eq(4)
      expect(ds.row_count).to eq(1) # 10 - 3*3 = 1
    end

    it "go_to_page jumps directly" do
      ds.go_to_page(3)
      expect(ds.page).to eq(3)
      expect(ds.rows[0][:name]).to eq("User 3")
    end

    it "clamps go_to_page to valid range" do
      ds.go_to_page(99)
      expect(ds.page).to eq(4)
      ds.go_to_page(-1)
      expect(ds.page).to eq(1)
    end

    it "updates page on reload when records are deleted" do
      ds.go_to_page(4)
      expect(ds.page).to eq(4)
      User.where("name >= 'User 5'").delete_all # leaves 5 records
      ds.reload!
      expect(ds.total_count).to eq(5)
      expect(ds.page).to eq(2) # clamped: ceil(5/3) = 2
    end
  end
end
