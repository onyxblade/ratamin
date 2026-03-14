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
      expect(ds.rows[0][:name]).to eq("Alice")
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
end
