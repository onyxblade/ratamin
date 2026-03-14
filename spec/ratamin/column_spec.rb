# frozen_string_literal: true

RSpec.describe Ratamin::Column do
  it "uses key as default label" do
    col = described_class.new(key: :name)
    expect(col.label).to eq("Name")
  end

  it "accepts custom label" do
    col = described_class.new(key: :name, label: "Full Name")
    expect(col.label).to eq("Full Name")
  end

  it "defaults type to :string" do
    col = described_class.new(key: :name)
    expect(col.type).to eq(:string)
  end

  it "defaults width to nil" do
    col = described_class.new(key: :name)
    expect(col.width).to be_nil
  end

  it "is immutable" do
    col = described_class.new(key: :name, width: 10, type: :text)
    expect(col).to be_frozen
  end
end
