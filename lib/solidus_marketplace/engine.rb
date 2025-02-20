module SolidusMarketplace
  class Engine < Rails::Engine
    require 'spree/core'
    require 'spree/config'

    isolate_namespace Spree
    engine_name 'solidus_marketplace'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'solidus_marketplace.custom_splitters', after: 'spree.register.stock_splitters' do |app|
      require 'spree/stock/splitter/marketplace'
      app.config.spree.stock_splitters << Spree::Stock::Splitter::Marketplace
    end

    initializer "solidus_marketplace.preferences", before: :load_config_initializers  do |app|
      require 'spree/marketplace_configuration'
      SolidusMarketplace::Config = Spree::MarketplaceConfiguration.new
    end

    initializer "solidus_marketplace.menu", before: :load_config_initializers  do |app|
      Spree::Backend::Config.configure do |config|
        config.menu_items << Spree::BackendConfiguration::MenuItem.new(
          [:stock_locations],
          'globe',
          condition: -> { can?(:index, Spree::StockLocation) },
        )

        config.menu_items << Spree::BackendConfiguration::MenuItem.new(
          [:suppliers],
          'home',
          condition: -> { can?(:index, Spree::Supplier) },
        )

        config.menu_items << Spree::BackendConfiguration::MenuItem.new(
          [:shipments],
          'plane',
          condition: -> { can?(:index, Spree::Shipment) },
        )
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Spree::Ability.register_ability(Spree::SupplierAbility)
    end

    config.to_prepare &method(:activate).to_proc
  end
end
