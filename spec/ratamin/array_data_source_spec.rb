# frozen_string_literal: true

RSpec.describe Ratamin::ArrayDataSource do
  subject(:ds) do
    described_class.new(
      columns: [
        Ratamin::Column.new(key: :id, width: 6),
        Ratamin::Column.new(key: :name),
        Ratamin::Column.new(key: :bio, type: :text)
      ],
      rows: [
        {id: 1, name: "Alice", bio: "Engineer"},
        {id: 2, name: "Bob", bio: "Designer"}
      ]
    )
  end

  describe "#columns" do
    it "returns column definitions" do
      expect(ds.columns.map(&:key)).to eq(%i[id name bio])
    end
  end

  describe "#rows" do
    it "returns all rows" do
      expect(ds.row_count).to eq(2)
      expect(ds.rows[0][:name]).to eq("Alice")
    end

    it "does not share references with the original data" do
      original = [{id: 1, name: "Alice"}]
      source = described_class.new(
        columns: [Ratamin::Column.new(key: :name)],
        rows: original
      )
      source.update_row(0, {name: "Modified"})
      expect(original[0][:name]).to eq("Alice")
    end
  end

  describe "#update_row" do
    it "updates values at the given index" do
      ds.update_row(0, {name: "Alicia"})
      expect(ds.rows[0][:name]).to eq("Alicia")
    end

    it "leaves other fields unchanged" do
      ds.update_row(0, {name: "Alicia"})
      expect(ds.rows[0][:bio]).to eq("Engineer")
    end

    it "returns a successful UpdateResult" do
      result = ds.update_row(0, {name: "Alicia"})
      expect(result).to be_ok
    end
  end

  describe "#reload!" do
    it "does not raise" do
      expect { ds.reload! }.not_to raise_error
    end
  end
end
