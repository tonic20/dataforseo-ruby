# frozen_string_literal: true

RSpec.describe DataForSeo::Response do
  def response(cost:, items:, requested:)
    described_class.new(path: "/p", cost:, tasks: [{ "id" => "t" }], items:, requested:)
  end

  it "combines slices: costs summed, tasks and items concatenated, requested is the full input" do
    combined = described_class.combine(
      [response(cost: 0.075, items: [{ "k" => 1 }], requested: %w[a]),
       response(cost: 0.075, items: [{ "k" => 2 }], requested: %w[b])],
      path: "/p", requested: %w[a b]
    )

    expect(combined.cost).to be_within(1e-9).of(0.15)
    expect(combined.items).to eq([{ "k" => 1 }, { "k" => 2 }])
    expect(combined.tasks.size).to eq(2)
    expect(combined.requested).to eq(%w[a b])
  end

  it "combines nothing into an empty, free response" do
    combined = described_class.combine([], path: "/p", requested: [])

    expect(combined).to have_attributes(cost: 0.0, items: [], tasks: [], requested: [])
  end
end
