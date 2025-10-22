require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Schema.verbose = false unless ENV["VERBOSE"]
ActiveRecord::Base.logger = logger

if ActiveRecord::VERSION::STRING.to_f >= 7.2
  ActiveRecord::Base.attributes_for_inspect = :all
end

if ActiveRecord::VERSION::STRING.to_f == 8.0
  ActiveSupport.to_time_preserves_timezone = :zone
elsif ActiveRecord::VERSION::STRING.to_f == 7.2
  ActiveSupport.to_time_preserves_timezone = true
end

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "active_hll_test"

ActiveRecord::Schema.define do
  enable_extension "hll"

  create_table :events, force: true do |t|
    t.integer :visitor_id
    t.datetime :created_at
  end

  create_table :event_rollups, force: true do |t|
    t.date :time_bucket
    t.hll :visitor_ids
  end
  add_index :event_rollups, :time_bucket, unique: true

  create_table :order_rollups, force: true do |t|
    t.hll :visitor_ids, default: -> { "hll_empty()" }
    # TODO support parameters
    # https://github.com/citusdata/postgresql-hll#explanation-of-parameters-and-tuning
    # currently don't appear in schema.rb
    t.column :user_ids, "hll(12, 6, 1024, 0)", default: -> { "hll_empty(12, 6, 1024, 0)" }
  end
end

class Event < ActiveRecord::Base
end

class EventRollup < ActiveRecord::Base
end

class OrderRollup < ActiveRecord::Base
end

class Minitest::Test
  def setup
    Event.delete_all
    EventRollup.delete_all
  end
end
