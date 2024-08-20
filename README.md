# Active HLL

:fire: HyperLogLog for Rails and Postgres

For fast, approximate count-distinct queries

[![Build Status](https://github.com/ankane/active_hll/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/active_hll/actions)

## Installation

First, install the [hll extension](https://github.com/citusdata/postgresql-hll) on your database server:

```sh
cd /tmp
curl -L https://github.com/citusdata/postgresql-hll/archive/refs/tags/v2.18.tar.gz | tar xz
cd postgresql-hll-2.18
make
make install # may need sudo
```

Then add this line to your application’s Gemfile:

```ruby
gem "active_hll"
```

And run:

```sh
bundle install
rails generate active_hll:install
rails db:migrate
```

## Getting Started

HLLs provide an approximate count of unique values (like unique visitors). By rolling up data by day, you can quickly get an approximate count over any date range.

Create a table with an `hll` column

```ruby
class CreateEventRollups < ActiveRecord::Migration[7.2]
  def change
    create_table :event_rollups do |t|
      t.date :time_bucket, index: {unique: true}
      t.hll :visitor_ids
    end
  end
end
```

You can use [batch](#batch) and [stream](#stream) approaches to build HLLs

### Batch

To generate HLLs from existing data, use the `hll_agg` method

```ruby
hlls = Event.group_by_day(:created_at).hll_agg(:visitor_id)
```

> Install [Groupdate](https://github.com/ankane/groupdate) to use the `group_by_day` method

And store the result

```ruby
EventRollup.upsert_all(
  hlls.map { |k, v| {time_bucket: k, visitor_ids: v} },
  unique_by: [:time_bucket]
)
```

For a large number of HLLs, use SQL to generate and upsert in a single statement

### Stream

To add new data to HLLs, use the `hll_add` method

```ruby
EventRollup.where(time_bucket: Date.current).hll_add(visitor_ids: ["visitor1", "visitor2"])
```

or the `hll_upsert` method (experimental)

```ruby
EventRollup.hll_upsert({time_bucket: Date.current, visitor_ids: ["visitor1", "visitor2"]})
```

## Querying

Get approximate unique values for a time range

```ruby
EventRollup.where(time_bucket: 30.days.ago.to_date..Date.current).hll_count(:visitor_ids)
```

Get approximate unique values by time bucket

```ruby
EventRollup.group(:time_bucket).hll_count(:visitor_ids)
```

Get approximate unique values by month

```ruby
EventRollup.group_by_month(:time_bucket, time_zone: false).hll_count(:visitor_ids)
```

Get the union of multiple HLLs

```ruby
EventRollup.hll_union(:visitor_ids)
```

## Data Protection

Cardinality estimators like HyperLogLog do not [preserve privacy](https://arxiv.org/pdf/1808.05879.pdf), so protect `hll` columns the same as you would the raw data.

For instance, you can check membership with a good probability with:

```sql
SELECT
    time_bucket,
    visitor_ids = visitor_ids || hll_hash_text('visitor1') AS likely_member
FROM
    event_rollups;
```

## Data Retention

Data should only be retained for as long as it’s needed. Delete older data with:

```ruby
EventRollup.where("time_bucket < ?", 2.years.ago).delete_all
```

There’s not a way to remove data from an HLL, so to delete data for a specific user, delete the underlying data and recalculate the rollup.

## Hosted Postgres

The `hll` extension is available on a number of [hosted providers](https://github.com/ankane/active_hll/issues/4).

## History

View the [changelog](CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/active_hll/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/active_hll/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/active_hll.git
cd active_hll
bundle install
bundle exec rake test
```
