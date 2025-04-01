# dependencies
require "active_support"

# modules
require_relative "active_hll/hll"
require_relative "active_hll/utils"
require_relative "active_hll/version"

module ActiveHll
  class Error < StandardError; end

  autoload :Type, "active_hll/type"

  module RegisterType
    def initialize_type_map(m = type_map)
      super
      m.register_type "hll", ActiveHll::Type.new
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require_relative "active_hll/model"

  include ActiveHll::Model

  require "active_record/connection_adapters/postgresql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:hll] = {name: "hll"}

  # ensure schema can be loaded
  ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :hll)

  # prevent unknown OID warning
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(ActiveHll::RegisterType)
end
