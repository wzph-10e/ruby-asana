require 'support/stub_api'
require_relative 'unicorn'

# rubocop:disable RSpec/FilePath
RSpec.describe Asana::Resources::Unicorn do
  RSpec::Matchers.define :be_john do
    match do |unicorn|
      unicorn.class == described_class &&
        unicorn.id == 1 &&
        unicorn.name == 'John' &&
        unicorn.world == 123
    end
  end

  RSpec::Matchers.define :be_laura do
    match do |unicorn|
      unicorn.class == described_class &&
        unicorn.id == 2 &&
        unicorn.name == 'Laura' &&
        unicorn.world == 184
    end
  end

  let(:api) { StubAPI.new }
  let(:auth) { Asana::Authentication::TokenAuthentication.new('foo') }
  let(:client) do
    Asana::HttpClient.new(authentication: auth, adapter: api.to_proc)
  end

  let(:john_data) { { 'id' => 1, 'name' => 'John', 'world' => 123 } }
  let(:laura_data) { { 'id' => 2, 'name' => 'Laura', 'world' => 184 } }

  describe '.plural_name' do
    it 'returns the resource plural name' do
      expect(described_class.plural_name).to eq('unicorns')
    end
  end

  describe '.create' do
    it 'creates a new unicorn, with the world passed in as a param' do
      api.on(:post, '/unicorns', data: { name: 'John',
                                         world: 123 }) do |response|
        response.body = { data: john_data }
      end
      john = described_class.create(client, name: 'John', world: 123)
      expect(john).to be_john
    end
  end

  describe '.create_in_world' do
    it 'creates a new unicorn, with the world passed in the URL' do
      api.on(:post,
             '/worlds/123/unicorns',
             data: { name: 'John' }) do |response|
        response.body = { data: john_data }
      end
      john = described_class.create_in_world(client, name: 'John', world: 123)
      expect(john).to be_john
    end
  end

  describe '.find_by_id' do
    it 'finds a unicorn by id' do
      api.on(:get, '/unicorns/1') do |response|
        response.body = { data: john_data }
      end
      john = described_class.find_by_id(client, 1)
      expect(john).to be_john
    end
  end

  describe '.find_all' do
    it 'finds all unicorns in all worlds of any breed' do
      api.on(:get, '/unicorns') do |response|
        response.body = { data: [john_data, laura_data] }
      end

      unicorns = described_class.find_all(client)
      expect(unicorns).to be_a(Asana::Resources::Collection)
      expect(unicorns.size).to eq(2)

      john, laura = unicorns.to_a
      expect(john).to be_john
      expect(laura).to be_laura
    end

    it 'finds all unicorns by world' do
      api.on(:get, '/unicorns', data: { world: 123 }) do |response|
        response.body = { data: [john_data] }
      end

      unicorns = described_class.find_all(client)
      expect(unicorns).to be_a(Asana::Resources::Collection)
      expect(unicorns.size).to eq(1)
      expect(unicorns.first).to be_john
    end

    it 'finds all unicorns by breed' do
      api.on(:get, '/unicorns', data: { breed: 'magical' }) do |response|
        response.body = { data: [laura_data] }
      end

      unicorns = described_class.find_all(client)
      expect(unicorns).to be_a(Asana::Resources::Collection)
      expect(unicorns.size).to eq(1)
      expect(unicorns.first).to be_laura
    end
  end

  describe '.find_by_world' do
    it 'finds all unicorns by world in the URL' do
      api.on(:get, '/worlds/123/unicorns') do |response|
        response.body = { data: [john_data] }
      end

      unicorns = described_class.find_by_world(client, world: 123)
      expect(unicorns).to be_a(Asana::Resources::Collection)
      expect(unicorns.size).to eq(1)
      expect(unicorns.first).to be_john
    end
  end

  describe '#update' do
    it 'updates a unicorn' do
      api.on(:put, '/unicorns/1', name: 'Jan') do |response|
        response.body = { data: john_data.merge(name: 'Jan') }
      end

      john = described_class.new(john_data, client: client)
      jan = john.update(name: 'Jan')
      expect(jan.id).to eq(1)
      expect(jan.name).to eq('Jan')
      expect(jan.world).to eq(123)
    end
  end

  describe '#paws' do
    it 'returns a collection of paws as generic resources' do
      paw_data = { id: 9, size: 4 }
      api.on(:get, '/unicorns/1/paws') do |response|
        response.body = { data: [paw_data] }
      end

      john = described_class.new(john_data, client: client)
      paws = john.paws
      expect(paws).to be_a(Asana::Resources::Collection)
      expect(paws.size).to eq(1)
      expect(paws.first).to be_a(Asana::Resources::Resource)
      expect(paws.first.size).to eq(4)
    end
  end

  describe '#delete' do
    it 'deletes a unicorn' do
      api.on(:delete, '/unicorns/1') do |response|
        response.body = { data: {} }
      end

      john = described_class.new(john_data, client: client)
      expect(john.delete).to eq(true)
    end
  end
end
# rubocop:enable RSpec/FilePath