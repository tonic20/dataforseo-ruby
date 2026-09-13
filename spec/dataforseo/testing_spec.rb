# frozen_string_literal: true

RSpec.describe DataForSeo::Testing do
  it "records calls and replays bodies in order" do
    transport = DataForSeo::Testing::FakeTransport.new({ "a" => 1 }, { "b" => 2 })

    expect(transport.call("/one", [1])).to eq("a" => 1)
    expect(transport.call("/two", [2])).to eq("b" => 2)
    expect(transport.calls).to eq([["/one", [1]], ["/two", [2]]])
  end

  it "raises a queued exception instead of returning it" do
    transport = DataForSeo::Testing::FakeTransport.new(DataForSeo::ConnectionError.new("down"))

    expect { transport.call("/p", []) }.to raise_error(DataForSeo::ConnectionError, "down")
  end

  it "refuses to be called more times than it has bodies" do
    expect { DataForSeo::Testing::FakeTransport.new.call("/p", []) }.to raise_error(RuntimeError, /more times/)
  end

  it "builds a successful body" do
    body = described_class.ok_body(result: [{ "x" => 1 }], cost: 0.5)

    expect(body).to include("status_code" => 20000, "cost" => 0.5)
    expect(body["tasks"]).to eq([{ "id" => "fake-task", "status_code" => 20000, "status_message" => "Ok.",
                                   "cost" => 0.5, "result" => [{ "x" => 1 }] }])
  end

  it "builds envelope and task errors" do
    expect(described_class.error_body(status_code: 40100)).to include("status_code" => 40100, "tasks" => [])
    expect(described_class.error_body(status_code: 40501, on: :task)["tasks"].first).to include("status_code" => 40501)
  end
end
