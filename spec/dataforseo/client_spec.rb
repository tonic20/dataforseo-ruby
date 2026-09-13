# frozen_string_literal: true

RSpec.describe DataForSeo::Client do
  let(:t) { DataForSeo::Testing }

  def client(*bodies, **options)
    @transport = t::FakeTransport.new(*bodies)
    described_class.new(login: "l", password: "p", transport: @transport, **options)
  end

  it "requires credentials" do
    expect { described_class.new(login: "l") }.to raise_error(ArgumentError)
  end

  it "posts the tasks and wraps the answer" do
    response = client(t.ok_body(result: [{ "k" => 1 }], cost: 0.02)).post("/v3/x", [{ "a" => 1 }], requested: %w[a])

    expect(@transport.calls).to eq([["/v3/x", [{ "a" => 1 }]]])
    expect(response).to have_attributes(path: "/v3/x", cost: 0.02, items: [{ "k" => 1 }], requested: %w[a])
  end

  it "extracts nested items when asked" do
    body = t.ok_body(result: [{ "items" => [{ "k" => 1 }, { "k" => 2 }] }])

    expect(client(body).post("/v3/x", [{}], extract: described_class::ITEMS).items).to eq([{ "k" => 1 }, { "k" => 2 }])
  end

  it "raises the mapped class for an envelope error" do
    expect { client(t.error_body(status_code: 40100)).post("/v3/x", [{}]) }
      .to raise_error(DataForSeo::AuthenticationError) { expect(it.path).to eq("/v3/x") }
  end

  it "raises the mapped class for a task error, with the task id" do
    expect { client(t.error_body(status_code: 50401, on: :task)).post("/v3/x", [{}]) }
      .to raise_error(DataForSeo::TransientError) { expect(it.task_id).to eq("fake-task") }
  end

  # A 20100 is a task-based endpoint's "created"; post does not support those.
  it "treats 20100 as a failure" do
    expect { client(t.error_body(status_code: 20100, on: :task)).post("/v3/x", [{}]) }
      .to raise_error(DataForSeo::ApiError)
  end

  it "raises when the response has fewer tasks than were posted, instead of silently returning less" do
    expect { client(t.ok_body(result: [])).post("/v3/x", [{ "a" => 1 }, { "b" => 2 }]) }
      .to raise_error(DataForSeo::ApiError) { |error|
        expect(error.message).to eq("expected 2 task(s), got 1")
        expect(error.path).to eq("/v3/x")
      }
  end

  it "raises when the envelope has no status code at all" do
    expect { client({ "tasks" => [] }).post("/v3/x", [{}]) }.to raise_error(DataForSeo::ApiError)
  end

  describe "slicing" do
    # Exercised through a typed method in endpoints_spec; here through the
    # private helper so the rule is pinned independently of any endpoint.
    def sliced(client, inputs, &block)
      client.send(:sliced, "/v3/x", inputs, described_class::RESULT, block) { |slice| { "keywords" => slice } }
    end

    it "sends one request per slice and combines them" do
      c = client(t.ok_body(result: [{ "k" => "a" }], cost: 1.0),
                 t.ok_body(result: [{ "k" => "b" }], cost: 1.0),
                 t.ok_body(result: [{ "k" => "c" }], cost: 1.0), batch_size: 2)

      combined = sliced(c, %w[a b c d e])

      expect(@transport.calls.map { it.last.first["keywords"] }).to eq([%w[a b], %w[c d], %w[e]])
      expect(combined.cost).to eq(3.0)
      expect(combined.items.map { it["k"] }).to eq(%w[a b c])
      expect(combined.requested).to eq(%w[a b c d e])
    end

    it "yields each slice with only that slice's requested inputs, before the next request" do
      c = client(t.ok_body(result: []), t.ok_body(result: []), t.ok_body(result: []), batch_size: 2)
      seen = []

      sliced(c, %w[a b c d e]) { |response| seen << [response.requested, @transport.calls.size] }

      expect(seen).to eq([[%w[a b], 1], [%w[c d], 2], [%w[e], 3]])
    end

    it "has already yielded slice 1 when slice 2 fails" do
      c = client(t.ok_body(result: []), DataForSeo::ConnectionError.new("down"), batch_size: 2)
      seen = []

      expect { sliced(c, %w[a b c]) { seen << it.requested } }.to raise_error(DataForSeo::ConnectionError)
      expect(seen).to eq([%w[a b]])
    end

    it "makes no request for no inputs" do
      c = client
      expect(sliced(c, []).items).to eq([])
      expect(@transport.calls).to be_empty
    end
  end
end
