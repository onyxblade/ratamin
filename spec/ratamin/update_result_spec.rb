# frozen_string_literal: true

RSpec.describe Ratamin::UpdateResult do
  describe ".success" do
    subject(:result) { described_class.success }

    it "is ok" do
      expect(result).to be_ok
    end

    it "is not failed" do
      expect(result).not_to be_failed
    end

    it "has empty errors" do
      expect(result.errors).to eq([])
    end
  end

  describe ".failure" do
    subject(:result) { described_class.failure(["Name can't be blank", "Email is invalid"]) }

    it "is not ok" do
      expect(result).not_to be_ok
    end

    it "is failed" do
      expect(result).to be_failed
    end

    it "has error messages" do
      expect(result.errors).to eq(["Name can't be blank", "Email is invalid"])
    end

    it "wraps a single string in an array" do
      result = described_class.failure("Something went wrong")
      expect(result.errors).to eq(["Something went wrong"])
    end
  end
end
