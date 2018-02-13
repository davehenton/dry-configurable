RSpec.describe Dry::ConfigurableV2 do
  context 'when extended' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database_url, Test::Types::Strict::String
        setting :path, Test::Types::String.default('test')
      end
    end

    context 'try to access config without configuring it first' do
      it 'raises NotConfigured' do
        expect {
          klass.config
        }.to raise_error(Dry::ConfigurableV2::NotConfiguredError)
      end

      context 'all setting has defaults' do
        let(:klass) do
          Class.new do
            extend Dry::ConfigurableV2

            setting :database_url, Test::Types::String.default('localhost')
            setting :path, Test::Types::String.default('test')
          end
        end

        it 'returns config' do
          expect(klass.config.database_url).to eq 'localhost'
          expect(klass.config.path).to eq 'test'
        end
      end

      context 'all nested settings has default values' do
        let(:klass) do
          Class.new do
            extend Dry::ConfigurableV2

            setting :database do
              setting :url, Test::Types::String.default('localhost')
              setting :name do
                setting :secret, Test::Types::String.default('dry-rb RULES!')
              end
            end
          end
        end

        it 'returns config' do
          expect(klass.config.database.url).to eq 'localhost'
          expect(klass.config.database.name.secret).to eq 'dry-rb RULES!'
        end
      end
    end

    context 'basic example' do
      before do
        klass.configure do
          config :database_url, 'jdbc:sqlite:memory'
        end
      end

      it 'allow to set values' do
        expect(klass.config.database_url).to eq 'jdbc:sqlite:memory'
      end

      it 'will use default values' do
        expect(klass.config.path).to eq 'test'
      end
    end

    context 'nested configuration' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :database_url, Test::Types::String

          setting :preview do
            setting :testing, Test::Types::String
          end
        end
      end

      it 'allow to set values for nested configuration' do
        klass.configure do
          config :preview do
            config :testing, 'tested'
          end

          config :database_url, 'localhost'
        end

        expect(klass.config.preview.testing).to eq 'tested'
      end
    end

    context 'big nested configuration' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :preview do
            setting :testing do
              setting :allowed, Test::Types::Bool
            end
          end
        end
      end

      it 'allow to set values for nested configuration' do
        klass.configure do
          config :preview do
            config :testing do
              config :allowed, true
            end
          end
        end

        expect(klass.config.preview.testing.allowed).to eq true
      end
    end

    context 'Use of processors' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :database_url, Test::Types::String.constructor { |value| "foo::#{value}" }
        end
      end

      before do
        klass.configure do
          config :database_url, 'localhost'
        end
      end

      it 'use types constructor to generate config value' do
        expect(klass.config.database_url).to eq 'foo::localhost'
      end
    end

    context 'Use of processors with default values' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :wait_time, Test::Types::Strict::Integer.constructor(&:to_i).default { 3 }
        end
      end

      it 'will use default value if no value is provided' do
        expect(klass.config.wait_time).to eq 3
      end

      it 'will use value provided' do
        klass.configure do
          config :wait_time, '34'
        end

        expect(klass.config.wait_time).to eq 34
      end
    end

    context 'Use of processors with nested configuration' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :database do
            setting :url, Test::Types::String.constructor { |value| "foo::#{value}" }
          end
        end
      end

      before do
        klass.configure do
          config :database do
            config :url, 'localhost'
          end
        end
      end

      it 'use types constructor to generate config value' do
        expect(klass.config.database.url).to eq 'foo::localhost'
      end
    end

    context 'Use of processors with nested configuration and default values' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :wait do
            setting :time, Test::Types::Strict::Integer.constructor(&:to_i).default { 3 }
          end
        end
      end

      it 'will use default value if no value is provided' do
        expect(klass.config.wait.time).to eq 3
      end

      it 'will use value provided' do
        klass.configure do
          config :wait do
            config :time, '34'
          end
        end

        expect(klass.config.wait.time).to eq 34
      end
    end

    context 'reader option' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :database_url, Test::Types::String.meta(reader: true)
        end
      end

      before do
        klass.configure do
          config :database_url,'localhost'
        end
      end

      it 'allows to access the configuration value directly' do
        expect(klass.database_url).to eq 'localhost'
      end
    end

    context 'reader option nested configuration' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting :database do
            setting :url, Test::Types::String.meta(reader: true)
          end
        end
      end

      before do
        klass.configure do
          config :database do
            config :url,'localhost'
          end
        end
      end

      it 'allows to access the configuration value directly' do
        expect(klass.database.url).to eq 'localhost'
      end
    end

    context 'try to set new value after config has been created' do
      before do
        klass.configure do
          config :database_url, 'localhost'
        end
      end

      it 'raise an exception' do
        expect { klass.setting :pool, 5 }.to raise_error(
          Dry::ConfigurableV2::AlreadyDefinedConfigError
        )
      end
    end
  end
end
