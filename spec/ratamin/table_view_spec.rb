# frozen_string_literal: true

RSpec.describe Ratamin::TableView do
  let(:columns) do
    [
      Ratamin::Column.new(key: :id, width: 6),
      Ratamin::Column.new(key: :name),
      Ratamin::Column.new(key: :bio, type: :text)
    ]
  end

  let(:rows) do
    [
      {id: 1, name: "Alice", bio: "Short"},
      {id: 2, name: "Bob", bio: "A" * 50},
      {id: 3, name: "Charlie", bio: "Medium length bio"}
    ]
  end

  let(:data_source) { Ratamin::ArrayDataSource.new(columns: columns, rows: rows) }
  subject(:view) { described_class.new(data_source) }

  describe "navigation" do
    it "starts with row 0 selected" do
      expect(view.selected_index).to eq(0)
    end

    it "select_next moves down" do
      view.select_next
      expect(view.selected_index).to eq(1)
    end

    it "select_next stops at last row" do
      3.times { view.select_next }
      expect(view.selected_index).to eq(2)
    end

    it "select_previous moves up" do
      view.select_next
      view.select_previous
      expect(view.selected_index).to eq(0)
    end

    it "select_previous stops at first row" do
      view.select_previous
      expect(view.selected_index).to eq(0)
    end

    it "select_first jumps to row 0" do
      2.times { view.select_next }
      view.select_first
      expect(view.selected_index).to eq(0)
    end

    it "select_last jumps to last row" do
      view.select_last
      expect(view.selected_index).to eq(2)
    end
  end

  describe "#selected_row" do
    it "returns the data hash for the selected row" do
      view.select_next
      expect(view.selected_row[:name]).to eq("Bob")
    end

    it "returns nil for out-of-bounds index" do
      empty_ds = Ratamin::ArrayDataSource.new(columns: columns, rows: [])
      empty_view = described_class.new(empty_ds)
      expect(empty_view.selected_row).to be_nil
    end
  end
end
