# Ecto PSQL Extras [![Hex.pm](https://img.shields.io/hexpm/v/ecto_psql_extras.svg)](https://hex.pm/packages/ecto_psql_extras) [![Hex.pm](https://img.shields.io/hexpm/dt/ecto_psql_extras.svg)](https://hex.pm/packages/ecto_psql_extras) [![Hex.pm](https://img.shields.io/hexpm/l/ecto_psql_extras.svg)](https://github.com/pawurb/ecto_psql_extras/blob/master/LICENSE) [![CI](https://github.com/pawurb/ecto_psql_extras/workflows/CI/badge.svg)](https://github.com/pawurb/ecto_psql_extras/actions)

Elixir port of [Heroku PG Extras](https://github.com/heroku/heroku-pg-extras). The goal of this project is to provide powerful insights into the PostgreSQL database for Elixir apps that are not using the Heroku PostgreSQL plugin.

Queries can be used to obtain information about a Postgres instance, that may be useful when analyzing performance issues. This includes information about locks, index usage, buffer cache hit ratios and vacuum statistics. Elixir API enables developers to easily integrate the tool into e.g. automatic monitoring tasks.

You can check out this blog post for detailed step by step tutorial on how to [optimize PostgreSQL using PG Extras library](https://pawelurbanek.com/postgresql-fix-performance).

This library is an optional dependency of [Phoenix.LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html). Check it out if you want to see SQL metrics in the UI instead of a command line interface.

![Phoenix Ecto Dashboard](https://github.com/pawurb/ecto_psql_extras/raw/master/phoenix-dashboard-diagnose.png)

Alternative versions:

- [Ruby](https://github.com/pawurb/ruby-pg-extras)

- [Ruby on Rails](https://github.com/pawurb/rails-pg-extras)

- [NodeJS](https://github.com/pawurb/node-postgres-extras)

- [Python](https://github.com/pawurb/python-pg-extras)

- [Haskell](https://github.com/pawurb/haskell-pg-extras)

## Installation

`mix.exs`

```elixir
 def deps do
    [
      {:ecto_psql_extras, "~> 0.7"}
    ]
 end
```

Some of the queries (e.g., `calls` and `outliers`) require [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html) extension enabled.

You can check if it is enabled in your database by running:

```elixir
EctoPSQLExtras.query(:extensions, YourApp.Repo)
```
You should see the similar line in the output:

```bash
+---------------------------------------------------------------------------------------------------------------------------------+
|                                               Available and installed extensions                                                |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
| name               | default_version | installed_version | comment                                                              |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
| plpgsql            | 1.0             | 1.0               | PL/pgSQL procedural language                                         |
| amcheck            | 1.2             |                   | functions for verifying relation integrity                           |
| autoinc            | 1.0             |                   | functions for autoincrementing fields                                |
| bloom              | 1.0             |                   | bloom access method - signature file based index                     |
| sslinfo            | 1.2             |                   | information about SSL certificates                                   |
| tablefunc          | 1.0             |                   | functions that manipulate whole tables, including crosstab           |
| xml2               | 1.1             |                   | XPath querying and XSLT                                              |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
```

## Usage

You can run queries using a simple API:

```elixir
EctoPSQLExtras.cache_hit(YourApp.Repo)
```

```bash
+----------------+------------------------+
|        Index and table hit rate         |
+----------------+------------------------+
| name           | ratio                  |
+----------------+------------------------+
| index hit rate | 0.97796610169491525424 |
| table hit rate | 0.96724294813466787989 |
+----------------+------------------------+
```

By default the ASCII table is displayed. Alternatively you can return the raw query results:

```elixir
EctoPSQLExtras.index_cache_hit(YourApp.Repo, format: :raw)

%Postgrex.Result{
  columns: ["name", "buffer_hits", "block_reads", "total_read", "ratio"],
  command: :select,
  connection_id: 413,
  messages: [],
  num_rows: 1,
  rows: [["schema_migrations", 0, 1, 1, "0"]]
}

```

You can also run queries by passing their name to the `query` method:

```elixir
EctoPSQLExtras.query(:cache_hit, YourApp.Repo)
```

```bash
+----------------+------------------------+
|        Index and table hit rate         |
+----------------+------------------------+
| name           | ratio                  |
+----------------+------------------------+
| index hit rate | 0.97796610169491525424 |
| table hit rate | 0.96724294813466787989 |
+----------------+------------------------+
```

Some methods accept an optional `args` param allowing you to customize queries:

```elixir
EctoPSQLExtras.long_running_queries(YourApp.Repo, args: [threshold: "200 milliseconds"])
```

```bash
+----------------------------------------------------------------+
|  All queries longer than the threshold by descending duration  |
+-----------------------+---------------------+------------------+
| pid                   | duration            | query            |
+-----------------------+---------------------+------------------+
| No results            |                     |                  |
+-----------------------+---------------------+------------------+
```

## Diagnose report

The simplest way to start using `ecto_psql_extras` is to execute a `diagnose` method. It runs a set of checks and prints out a report highlighting areas that may require additional investigation:

```ruby
EctoPSQLExtras.diagnose(YourApp.Repo)
```

```bash
+----------------------------------------------------------------------------------------------------------+
|                                 Display a PostgreSQL healthcheck report                                  |
+-------+-------------------+------------------------------------------------------------------------------+
| ok    | check_name        | message                                                                      |
+-------+-------------------+------------------------------------------------------------------------------+
| false | table_cache_hit   | Table cache hit ratio is not yet reported.                                   |
| false | index_cache_hit   | Index cache hit ratio is too low: 0.0                                        |
| true  | unused_indexes    | No unused indexes detected.                                                  |
| true  | null_indexes      | No null indexes detected.                                                    |
| true  | bloat             | No bloated tables or indexes detected.                                       |
| true  | duplicate_indexes | No duplicate indexes detected.                                               |
| false | outliers          | Cannot check outliers because 'pg_stat_statements' extension is not enabled. |
| false | ssl_used          | Cannot check connection status because 'ssl_info' extension is not enabled.  |
+-------+-------------------+------------------------------------------------------------------------------+
```

Keep reading to learn about methods that `diagnose` uses under the hood.

## Available methods

### `cache_hit`

```

EctoPSQLExtras.cache_hit(YourApp.Repo)

+----------------+------------------------+
|        Index and table hit rate         |
+----------------+------------------------+
| name           | ratio                  |
+----------------+------------------------+
| index hit rate | 0.97796610169491525424 |
| table hit rate | 0.96724294813466787989 |
+----------------+------------------------+
(2 rows)
```

This command provides information on the efficiency of the buffer cache, for both index reads (`index hit rate`) as well as table reads (`table hit rate`). A low buffer cache hit ratio can be a sign that the Postgres instance is too small for the workload.

[More info](https://pawelurbanek.com/postgresql-fix-performance#cache-hit)

### `index_cache_hit`

```

EctoPSQLExtras.index_cache_hit(YourApp.Repo)

+-----------------------------------------------------------------------------+
|             Calculates your cache hit rate for reading indexes              |
+--------+-------------------+-------------+-------------+------------+-------+
| schema | name              | buffer_hits | block_reads | total_read | ratio |
+--------+-------------------+-------------+-------------+------------+-------+
| public | schema_migrations | 0           | 1           | 1          | 0.0   |
+--------+-------------------+-------------+-------------+------------+-------+
```

The same as `cache_hit` with each table's indexes cache hit info displayed separately.

[More info](https://pawelurbanek.com/postgresql-fix-performance#cache-hit)

### `table_cache_hit`

```

EctoPSQLExtras.table_cache_hit(YourApp.Repo)

+-----------------------------------------------------------------------------+
|              Calculates your cache hit rate for reading tables              |
+--------+-------------------+-------------+-------------+------------+-------+
| schema | name              | buffer_hits | block_reads | total_read | ratio |
+--------+-------------------+-------------+-------------+------------+-------+
| public | schema_migrations | 0           | 0           | 0          |       |
+--------+-------------------+-------------+-------------+------------+-------+
```

The same as `cache_hit` with each table's cache hit info displayed separately.

[More info](https://pawelurbanek.com/postgresql-fix-performance#cache-hit)

### `db_settings`

```

EctoPSQLExtras.db_settings(YourApp.Repo)

+------------------------------------------------------------------------------------------------------------------------------------------+
|                                           Queries that have the highest frequency of execution                                           |
+------------------------------+---------+------+------------------------------------------------------------------------------------------+
| name                         | setting | unit | short_desc                                                                               |
+------------------------------+---------+------+------------------------------------------------------------------------------------------+
| checkpoint_completion_target | 0.5     |      | Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval. |
| default_statistics_target    | 100     |      | Sets the default statistics target.                                                      |
| effective_cache_size         | 524288  | 8kB  | Sets the planner's assumption about the total size of the data caches.                   |
| effective_io_concurrency     | 1       |      | Number of simultaneous requests that can be handled efficiently by the disk subsystem.   |
| maintenance_work_mem         | 65536   | kB   | Sets the maximum memory to be used for maintenance operations.                           |
| max_connections              | 100     |      | Sets the maximum number of concurrent connections.                                       |
| max_wal_size                 | 1024    | MB   | Sets the WAL size that triggers a checkpoint.                                            |
| min_wal_size                 | 80      | MB   | Sets the minimum size to shrink the WAL to.                                              |
| random_page_cost             | 4       |      | Sets the planner's estimate of the cost of a nonsequentially fetched disk page.          |
| shared_buffers               | 16384   | 8kB  | Sets the number of shared memory buffers used by the server.                             |
| wal_buffers                  | 512     | 8kB  | Sets the number of disk-page buffers in shared memory for WAL.                           |
| work_mem                     | 4096    | kB   | Sets the maximum memory to be used for query workspaces.                                 |
+------------------------------+---------+------+------------------------------------------------------------------------------------------+
```

This method displays values for selected PostgreSQL settings. You can compare them with settings recommended by [PGTune](https://pgtune.leopard.in.ua/#/) and tweak values to improve performance.

[More info](https://pawelurbanek.com/postgresql-fix-performance#cache-hit)

### `index_usage`

```

EctoPSQLExtras.index_usage(YourApp.Repo)

+--------------------------------------------------------------------------+
|          Index hit rate (effective databases are at 99% and up)          |
+--------+-------------------+-----------------------------+---------------+
| schema | name              | percent_of_times_index_used | rows_in_table |
+--------+-------------------+-----------------------------+---------------+
| public | schema_migrations |                             | 0             |
+--------+-------------------+-----------------------------+---------------+
```

This command provides information on the efficiency of indexes, represented as what percentage of total scans were index scans. A low percentage can indicate under indexing, or wrong data being indexed.

### `locks`

```

EctoPSQLExtras.locks(YourApp.Repo)

+-----------------------------------------------------------------------------+
|                     Queries with active exclusive locks                     |
+------------+---------+---------------+---------+---------------+------+-----+
| pid        | relname | transactionid | granted | query_snippet | mode | age |
+------------+---------+---------------+---------+---------------+------+-----+
| No results |         |               |         |               |      |     |
+------------+---------+---------------+---------+---------------+------+-----+
```

This command displays queries that have taken out an exclusive lock on a relation. Exclusive locks typically prevent other operations on that relation from taking place, and can be a cause of "hung" queries that are waiting for a lock to be granted.

[More info](https://pawelurbanek.com/postgresql-fix-performance#deadlocks)

### `all_locks`

```elixir

EctoPSQLExtras.all_locks(YourApp.Repo)

+-----------------------------------------------------------------------------+
|                          Queries with active locks                          |
+------------+---------+---------------+---------+---------------+------+-----+
| pid        | relname | transactionid | granted | query_snippet | mode | age |
+------------+---------+---------------+---------+---------------+------+-----+
| No results |         |               |         |               |      |     |
+------------+---------+---------------+---------+---------------+------+-----+
```

This command displays all the current locks, regardless of their type.

### `outliers`

```

EctoPSQLExtras.outliers(YourApp.Repo, args: [limit: 20])

                   query                 |    exec_time     | prop_exec_time |   ncalls    | sync_io_time
-----------------------------------------+------------------+----------------+-------------+--------------
 SELECT * FROM archivable_usage_events.. | 154:39:26.431466 | 72.2%          | 34,211,877  | 00:00:00
 COPY public.archivable_usage_events (.. | 50:38:33.198418  | 23.6%          | 13          | 13:34:21.00108
 COPY public.usage_events (id, reporte.. | 02:32:16.335233  | 1.2%           | 13          | 00:34:19.784318
 INSERT INTO usage_events (id, retaine.. | 01:42:59.436532  | 0.8%           | 12,328,187  | 00:00:00
 SELECT * FROM usage_events WHERE (alp.. | 01:18:10.754354  | 0.6%           | 102,114,301 | 00:00:00
 UPDATE usage_events SET reporter_id =.. | 00:52:35.683254  | 0.4%           | 23,786,348  | 00:00:00
 INSERT INTO usage_events (id, retaine.. | 00:49:24.952561  | 0.4%           | 21,988,201  | 00:00:00
(truncated results for brevity)
```

This command displays statements, obtained from `pg_stat_statements`, ordered by the amount of time to execute in aggregate. This includes the statement itself, the total execution time for that statement, the proportion of total execution time for all statements that statement has taken up, the number of times that statement has been called, and the amount of time that statement spent on synchronous I/O (reading/writing from the file system).

Typically, an efficient query will have an appropriate ratio of calls to total execution time, with as little time spent on I/O as possible. Queries that have a high total execution time but low call count should be investigated to improve their performance. Queries that have a high proportion of execution time being spent on synchronous I/O should also be investigated.

[More info](https://pawelurbanek.com/postgresql-fix-performance#missing-indexes)

### `calls`

```

EctoPSQLExtras.calls(YourApp.Repo, args: [limit: 20])

                   query                 |    exec_time     | prop_exec_time |   ncalls    | sync_io_time
-----------------------------------------+------------------+----------------+-------------+--------------
 SELECT * FROM usage_events WHERE (alp.. | 01:18:11.073333  | 0.6%           | 102,120,780 | 00:00:00
 BEGIN                                   | 00:00:51.285988  | 0.0%           | 47,288,662  | 00:00:00
 COMMIT                                  | 00:00:52.31724   | 0.0%           | 47,288,615  | 00:00:00
 SELECT * FROM  archivable_usage_event.. | 154:39:26.431466 | 72.2%          | 34,211,877  | 00:00:00
 UPDATE usage_events SET reporter_id =.. | 00:52:35.986167  | 0.4%           | 23,788,388  | 00:00:00
 INSERT INTO usage_events (id, retaine.. | 00:49:25.260245  | 0.4%           | 21,990,326  | 00:00:00
 INSERT INTO usage_events (id, retaine.. | 01:42:59.436532  | 0.8%           | 12,328,187  | 00:00:00
(truncated results for brevity)
```

This command is much like `pg:outliers`, but ordered by the number of times a statement has been called.

[More info](https://pawelurbanek.com/postgresql-fix-performance#missing-indexes)

### `blocking`

```

EctoPSQLExtras.blocking(YourApp.Repo)

+------------------------------------------------------------------------------------------------------------+
|                       Queries holding locks other queries are waiting to be released                       |
+-------------+--------------------+-------------------+--------------+-------------------+------------------+
| blocked_pid | blocking_statement | blocking_duration | blocking_pid | blocked_statement | blocked_duration |
+-------------+--------------------+-------------------+--------------+-------------------+------------------+
| No results  |                    |                   |              |                   |                  |
+-------------+--------------------+-------------------+--------------+-------------------+------------------+
```

This command displays statements that are currently holding locks that other statements are waiting to be released. This can be used in conjunction with `pg:locks` to determine which statements need to be terminated in order to resolve lock contention.

[More info](https://pawelurbanek.com/postgresql-fix-performance#deadlocks)

### `total_index_size`

```

EctoPSQLExtras.total_index_size(YourApp.Repo)

+---------------------------------+
| Total size of all indexes in MB |
+---------------------------------+
| size                            |
+---------------------------------+
| 8.0 KB                          |
+---------------------------------+
```

This command displays the total size of all indexes on the database, in MB. It is calculated by taking the number of pages (reported in `relpages`) and multiplying it by the page size (8192 bytes).

### `index_size`

```

EctoPSQLExtras.index_size(YourApp.Repo)

+------------------------------------------+
| The size of indexes, descending by size  |
+--------+------------------------+--------+
| schema | name                   | size   |
+--------+------------------------+--------+
| public | schema_migrations_pkey | 8.0 KB |
+--------+------------------------+--------+
```

This command displays the size of each each index in the database, in MB. It is calculated by taking the number of pages (reported in `relpages`) and multiplying it by the page size (8192 bytes).

### `table_size`

```

EctoPSQLExtras.table_size(YourApp.Repo)

+--------------------------------------------------------------+
|  Size of the tables (excluding indexes), descending by size  |
+----------------+---------------------------+-----------------+
| schema         | name                      | size            |
+----------------+---------------------------+-----------------+
| public         | schema_migrations         | 0 bytes         |
+----------------+---------------------------+-----------------+
```

This command displays the size of each table and materialized view in the database, in MB. It is calculated by using the system administration function `pg_table_size()`, which includes the size of the main data fork, free space map, visibility map and TOAST data.

### `table_indexes_size`

```

EctoPSQLExtras.table_indexes_size(YourApp.Repo)

+-----------------------------------------------------------------+
| Total size of all the indexes on each table, descending by size |
+----------------+---------------------------+--------------------+
| schema         | table                     | index_size         |
+----------------+---------------------------+--------------------+
| public         | schema_migrations         | 8.0 KB             |
+----------------+---------------------------+--------------------+
```

This command displays the total size of indexes for each table and materialized view, in MB. It is calculated by using the system administration function `pg_indexes_size()`.

### `total_table_size`

```

EctoPSQLExtras.total_table_size(YourApp.Repo)

+-------------------------------------------------------------+
| Size of the tables (including indexes), descending by size  |
+----------------+---------------------------+----------------+
| schema         | name                      | size           |
+----------------+---------------------------+----------------+
| public         | schema_migrations         | 8.0 KB         |
+----------------+---------------------------+----------------+
```

This command displays the total size of each table and materialized view in the database, in MB. It is calculated by using the system administration function `pg_total_relation_size()`, which includes table size, total index size and TOAST data.

### `unused_indexes`

```

EctoPSQLExtras.unused_indexes(YourApp.Repo, args: [min_scans: 20])

+-------------------------------------------------------+
|           Unused and almost unused indexes            |
+------------+-------+-------+------------+-------------+
| schema     | table | index | index_size | index_scans |
+------------+-------+-------+------------+-------------+
| No results |       |       |            |             |
+------------+-------+-------+------------+-------------+
```

This command displays indexes that have < 50 scans recorded against them, and are greater than 5 pages in size, ordered by size relative to the number of index scans. This command is generally useful for eliminating indexes that are unused, which can impact write performance, as well as read performance should they occupy space in memory.

[More info](https://pawelurbanek.com/postgresql-fix-performance#unused-indexes)

### `duplicate_indexes`

```

EctoPSQLExtras.duplicate_indexes(YourApp.Repo)

+-----------------------------------------------------------------------------------------------+
|  Multiple indexes that have the same set of columns, same opclass, expression and predicate.  |
+-----------------------+-----------------+-----------------+-----------------+-----------------+
| size                  | idx1            | idx2            | idx3            | idx4            |
+-----------------------+-----------------+-----------------+-----------------+-----------------+
| No results            |                 |                 |                 |                 |
+-----------------------+-----------------+-----------------+-----------------+-----------------+
```

This command displays multiple indexes that have the same set of columns, same opclass, expression and predicate - which make them equivalent. Usually it's safe to drop one of them.

### `null_indexes`

```

EctoPSQLExtras.null_indexes(YourApp.Repo, args: [min_relation_size_mb: 10])

+-----------------------------------------------------------------------------------------+
|                      Find indexes with a high ratio of NULL values                      |
+------------+-------+------------+--------+----------------+-----------+-----------------+
| oid        | index | index_size | unique | indexed_column | null_frac | expected_saving |
+------------+-------+------------+--------+----------------+-----------+-----------------+
| No results |       |            |        |                |           |                 |
+------------+-------+------------+--------+----------------+-----------+-----------------+
```

This commands displays indexes that contain `NULL` values. A high ratio of `NULL` values means that using a partial index excluding them will be beneficial in case they are not used for searching.

[More info](https://pawelurbanek.com/postgresql-fix-performance#null-indexes)

### `seq_scans`

```

EctoPSQLExtras.seq_scans(YourApp.Repo)

+---------------------------------------------------------+
| Count of sequential scans by table descending by order  |
+---------------+--------------------------+--------------+
| schema        | name                     | count        |
+---------------+--------------------------+--------------+
| public        | schema_migrations        | 2            |
+---------------+--------------------------+--------------+
```

This command displays the number of sequential scans recorded against all tables, descending by count of sequential scans. Tables that have very high numbers of sequential scans may be under-indexed, and it may be worth investigating queries that read from these tables.

[More info](https://pawelurbanek.com/postgresql-fix-performance#missing-indexes)

### `long_running_queries`

```

EctoPSQLExtras.long_running_queries(YourApp.Repo, args: [threshold: "200 milliseconds"])


+----------------------------------------------------------------+
|  All queries longer than the threshold by descending duration  |
+-----------------------+---------------------+------------------+
| pid                   | duration            | query            |
+-----------------------+---------------------+------------------+
| No results            |                     |                  |
+-----------------------+---------------------+------------------+
```

This command displays currently running queries, that have been running for longer than 5 minutes, descending by duration. Very long running queries can be a source of multiple issues, such as preventing DDL statements completing or vacuum being unable to update `relfrozenxid`.

### `records_rank`

```

EctoPSQLExtras.records_rank(YourApp.Repo)

+----------------------------------------------------------------------------------+
|  All tables and the number of rows in each ordered by number of rows descending  |
+--------------------+-------------------------------+-----------------------------+
| schema             | name                          | estimated_count             |
+--------------------+-------------------------------+-----------------------------+
| public             | schema_migrations             | 0                           |
+--------------------+-------------------------------+-----------------------------+
```

This command displays an estimated count of rows per table, descending by estimated count. The estimated count is derived from `n_live_tup`, which is updated by vacuum operations. Due to the way `n_live_tup` is populated, sparse vs. dense pages can result in estimations that are significantly out from the real count of rows.

### `bloat`

```

EctoPSQLExtras.bloat(YourApp.Repo)

+-----------------------------------------------------------------------------------------------------+
|                   Table and index bloat in your database ordered by most wasteful                   |
+-------+------------+--------------------------------------------------------------+-------+---------+
| type  | schemaname | object_name                                                  | bloat | waste   |
+-------+------------+--------------------------------------------------------------+-------+---------+
| index | pg_catalog | pg_depend::pg_depend_reference_index                         | 1.2   | 64.0 KB |
| table | pg_catalog | pg_depend                                                    | 1.1   | 24.0 KB |
| index | pg_catalog | pg_ts_config_map::pg_ts_config_map_index                     | 2.0   | 16.0 KB |
| index | pg_catalog | pg_amproc::pg_amproc_oid_index                               | 2.0   | 16.0 KB |
| index | pg_catalog | pg_amproc::pg_amproc_fam_proc_index                          | 2.0   | 16.0 KB |
| table | pg_catalog | pg_class                                                     | 1.2   | 16.0 KB |
| index | pg_catalog | pg_shdepend::pg_shdepend_depender_index                      | 2.0   | 8.0 KB  |
| index | pg_catalog | pg_rewrite::pg_rewrite_rel_rulename_index                    | 0.2   | 0 bytes |
| index | pg_catalog | pg_attribute::pg_attribute_relid_attnum_index                | 0.2   | 0 bytes |
+-------+------------+--------------------------------------------------------------+-------+---------+
```

This command displays an estimation of table "bloat" – space allocated to a relation that is full of dead tuples, that has yet to be reclaimed. Tables that have a high bloat ratio, typically 10 or greater, should be investigated to see if vacuuming is aggressive enough, and can be a sign of high table churn.

[More info](https://pawelurbanek.com/postgresql-fix-performance#bloat)

### `vacuum_stats`

```

EctoPSQLExtras.vacuum_stats(YourApp.Repo)

+-----------------------------------------------------------------------------------------------------------------------------------------+
|                                  Dead rows and whether an automatic vacuum is expected to be triggered                                  |
+--------+-------------------+-------------+-----------------+----------------+----------------+----------------------+-------------------+
| schema | table             | last_vacuum | last_autovacuum | rowcount       | dead_rowcount  | autovacuum_threshold | expect_autovacuum |
+--------+-------------------+-------------+-----------------+----------------+----------------+----------------------+-------------------+
| public | schema_migrations |             |                 |              0 |              0 |             50       |                   |
+--------+-------------------+-------------+-----------------+----------------+----------------+----------------------+-------------------+
```

This command displays statistics related to vacuum operations for each table, including an estimation of dead rows, last autovacuum and the current autovacuum threshold. This command can be useful when determining if current vacuum thresholds require adjustments, and to determine when the table was last vacuumed.

### `kill_all`

```elixir
EctoPSQLExtras.kill_all(YourApp.Repo)

+------------------------------------------+
| Kill all the active database connections |
+------------------------------------------+
| killed                                   |
+------------------------------------------+
| true                                     |
| true                                     |
| true                                     |
| true                                     |
| true                                     |
| true                                     |
| true                                     |
| true                                     |
| true                                     |
+------------------------------------------+
```

This commands kills all the currently active connections to the database. It can be useful as a last resort when your database is stuck in a deadlock.

### `extensions`

```elixir
EctoPSQLExtras.extensions(YourApp.Repo)

+---------------------------------------------------------------------------------------------------------------------------------+
|                                               Available and installed extensions                                                |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
| name               | default_version | installed_version | comment                                                              |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
| plpgsql            | 1.0             | 1.0               | PL/pgSQL procedural language                                         |
| amcheck            | 1.2             |                   | functions for verifying relation integrity                           |
| autoinc            | 1.0             |                   | functions for autoincrementing fields                                |
| bloom              | 1.0             |                   | bloom access method - signature file based index                     |
| sslinfo            | 1.2             |                   | information about SSL certificates                                   |
| tablefunc          | 1.0             |                   | functions that manipulate whole tables, including crosstab           |
| xml2               | 1.1             |                   | XPath querying and XSLT                                              |
+--------------------+-----------------+-------------------+----------------------------------------------------------------------+
```

This command lists all the currently installed and available PostgreSQL extensions.

### `mandelbrot`

```elixir
EctoPSQLExtras.mandelbrot(YourApp.Repo)

+--------------------------------------------------------------------------------------------------------+
|                                           The mandelbrot set                                           |
+--------------------------------------------------------------------------------------------------------+
| art                                                                                                    |
+--------------------------------------------------------------------------------------------------------+
|              ....................................................................................      |
|             .......................................................................................    |
|            .........................................................................................   |
|           ...........................................................................................  |
|         ....................................................,,,,,,,,,................................. |
|        ................................................,,,,,,,,,,,,,,,,,,............................. |
|       ..............................................,,,,,,,,,,,,,,,,,,,,,,,,.......................... |
|      ............................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................ |
|      ..........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...................... |
|     .........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.................... |
|    ........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,................... |
|   .......................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,................. |
|  .......................................,,,,,,,,,,,,,,,,,,,,,,,,--,,,,,,,,,,,,,,,,,,,,................ |
| ......................................,,,,,,,,,,,,,,,,,,,,,,,,,,-+--,,,,,,,,,,,,,,,,,,,............... |
| ....................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----,,,,,,,,,,,,,,,,,,,.............. |
| ...................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,--- -----,,,,,,,,,,,,,,,,,............. |
| .................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---++--++,,,,,,,,,,,,,,,,,,............ |
| ................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----%++---,,,,,,,,,,,,,,,,,............ |
| ..............................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----+%----,,,,,,,,,,,,,,,,,,........... |
| .............................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----- %%+----,,,,,,,,,,,,,,,,,,.......... |
| ...........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---%-+%   ----,,,,,,,,,,,,,,,,,,,......... |
| ..........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---+ +##  %+%---,,,,,,,,,,,,,,,,,,......... |
| ........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----#      # +---,,,,,,,,,,,,,,,,,,........ |
| .......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-------%       %-----,,,,,,,,,,,,,,,,,........ |
| .....................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---------+         ------,,,,,,,,,,,,,,,,,....... |
| ....................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----------+@       +-----------,,,,,,,,,,,,....... |
| ..................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----@-------++       ++-----------,,,,,,,,,,,,...... |
| .................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,--+@% ---+ +@%%@     %%+@+@%------+-,,,,,,,,,,,...... |
| ................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----  # ++%               % @-----++--,,,,,,,,,,,..... |
| ..............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----+    %                  %%++ %+%@-,,,,,,,,,,,..... |
| .............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----+#                       #%    ++-,,,,,,,,,,,,.... |
| ............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,------+                             @---,,,,,,,,,,,,.... |
| ..........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-------++%                             ---,,,,,,,,,,,,.... |
| .........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,--------+ +                             %+---,,,,,,,,,,,,,... |
| ........,,,,,,,,,,,,,,,,,,,,,--------------------@                                +----,,,,,,,,,,,,... |
| .......,,,,,,,,,,,,,,,,,,,,,,- +-----------------+                                 ----,,,,,,,,,,,,... |
| .......,,,,,,,,,,,,,,,,,,,,,--++------+---------+%                                 +++--,,,,,,,,,,,,.. |
| ......,,,,,,,,,,,,,,,,,,,,,,--%+-----++---------                                     #+-,,,,,,,,,,,,.. |
| .....,,,,,,,,,,,,,,,,,,,,,,----#%++--+@ -+-----+%                                     --,,,,,,,,,,,,.. |
| .....,,,,,,,,,,,,,,,,,,,,,,-----+## ++@ + +----%                                    +--,,,,,,,,,,,,,.. |
| ....,,,,,,,,,,,,,,,,,,,,,,------+@  @     @@++++#                                   +--,,,,,,,,,,,,,.. |
| ....,,,,,,,,,,,,,,,,,,,,,-------%           #++%                                      -,,,,,,,,,,,,,.. |
| ...,,,,,,,,,,,,,,,,,,,,,------++%#           %%@                                     %-,,,,,,,,,,,,,,. |
| ...,,,,,,,,,,,,,,,,,,,--------+               %                                     +--,,,,,,,,,,,,,,. |
| ...,,,,,,,,,,,,,,,,,,-----+--++@              #                                      --,,,,,,,,,,,,,,. |
| ..,,,,,,,,,,,,,,,,,-------%+++%                                                    @--,,,,,,,,,,,,,,,. |
| ..,,,,,,,,,,,-------------+ @#@                                                    ---,,,,,,,,,,,,,,,. |
| ..,,,,,,,,,---@--------@-+%                                                       +---,,,,,,,,,,,,,,,. |
| ..,,,,,------- +-++++-+%%%                                                       +----,,,,,,,,,,,,,,,. |
| ..,,,,,,------%--------++%                                                       +----,,,,,,,,,,,,,,,. |
| ..,,,,,,,,,,--+----------++#                                                       ---,,,,,,,,,,,,,,,. |
| ..,,,,,,,,,,,,------------+@@@%                                                    +--,,,,,,,,,,,,,,,. |
| ..,,,,,,,,,,,,,,,,,------- +++%                                                    %--,,,,,,,,,,,,,,,. |
| ...,,,,,,,,,,,,,,,,,,---------+@              @                                      --,,,,,,,,,,,,,,. |
| ...,,,,,,,,,,,,,,,,,,,,------- #              %@                                    +--,,,,,,,,,,,,,,. |
| ...,,,,,,,,,,,,,,,,,,,,,-------++@           %+                                      %-,,,,,,,,,,,,,,. |
| ....,,,,,,,,,,,,,,,,,,,,,-------            %++%                                     %-,,,,,,,,,,,,,.. |
| ....,,,,,,,,,,,,,,,,,,,,,,------+#  %#   #@ ++++                                    +--,,,,,,,,,,,,,.. |
| .....,,,,,,,,,,,,,,,,,,,,,,-----+ %%++% +@+----+                                    +--,,,,,,,,,,,,,.. |
| .....,,,,,,,,,,,,,,,,,,,,,,,---%+++--+#+--------%                                    #--,,,,,,,,,,,,.. |
| ......,,,,,,,,,,,,,,,,,,,,,,--++-----%%---------                                    @#--,,,,,,,,,,,,.. |
| .......,,,,,,,,,,,,,,,,,,,,,---------------------+@                                +-++,,,,,,,,,,,,... |
| ........,,,,,,,,,,,,,,,,,,,,,--------------------+                                 ----,,,,,,,,,,,,... |
| .........,,,,,,,,,,,,,,,,,,,,----,,,-------------                                #+----,,,,,,,,,,,,... |
| ..........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-------+ +                              +---,,,,,,,,,,,,,... |
| ...........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,--------+%#                           #---,,,,,,,,,,,,.... |
| ............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,------+#                        @   @---,,,,,,,,,,,,.... |
| .............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----+#                        +    @--,,,,,,,,,,,,.... |
| ..............,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---+%   %+@                 %+-+ +++%-,,,,,,,,,,,..... |
| ................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----% %@++              # %  -----++-,,,,,,,,,,,,..... |
| .................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-- ++ ---+ + +%@     %++++++------%-,,,,,,,,,,,...... |
| ...................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---- -------++       +------------,,,,,,,,,,,,...... |
| ....................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----------+%       +--------,,,,,,,,,,,,,,,....... |
| ......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,--------+#        -----,,,,,,,,,,,,,,,,,,....... |
| .......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-------+       #----,,,,,,,,,,,,,,,,,,........ |
| .........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,----+%      %#---,,,,,,,,,,,,,,,,,,,........ |
| ..........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---+%+%@  %+%%--,,,,,,,,,,,,,,,,,,......... |
| ............................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---+-+%  %----,,,,,,,,,,,,,,,,,,.......... |
| .............................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----+%@+---,,,,,,,,,,,,,,,,,,,.......... |
| ...............................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----+%----,,,,,,,,,,,,,,,,,,........... |
| ................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,-----%+ +--,,,,,,,,,,,,,,,,,............ |
| ..................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,---++----,,,,,,,,,,,,,,,,,............. |
| ...................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,---@-----,,,,,,,,,,,,,,,,,............. |
| .....................................,,,,,,,,,,,,,,,,,,,,,,,,,,,-----,,,,,,,,,,,,,,,,,,,.............. |
|  .....................................,,,,,,,,,,,,,,,,,,,,,,,,,,--%,,,,,,,,,,,,,,,,,,,,............... |
|  .......................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,................. |
|   ........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.................. |
|    ........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,................... |
|     .........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.................... |
|      ..........................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,...................... |
|       ............................................,,,,,,,,,,,,,,,,,,,,,,,,,,,,........................ |
|        .............................................,,,,,,,,,,,,,,,,,,,,,,,,.......................... |
|         ................................................,,,,,,,,,,,,,,,,,............................. |
|          .....................................................,,,,.................................... |
|           ...........................................................................................  |
|            .........................................................................................   |
|             ......................................................................................     |
|              ....................................................................................      |
|                .................................................................................       |
|                 ..............................................................................         |
|                   ...........................................................................          |
|                    ........................................................................            |
+--------------------------------------------------------------------------------------------------------+
```

This command outputs the Mandelbrot set, calculated through SQL.

### `connections`

```

EctoPSQLExtras.connections(YourApp.Repo)
+----------------------------------------------+
|  Shows all the active database connections   |
+----------+----------------+------------------+
| username | client_address | application_name |
+----------+----------------+------------------+
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | your_app         |
| postgres | 172.20.0.1/32  | psql             |
+----------+----------------+------------------+
```

This command returns the list of all active connections to the database.

To have `application_name` populate in connections output, you need to configure your Phoenix applications' Repo by adding the `parameters` and set `application_name`:

```elixir
config :your_app, YourApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "your_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  parameters: [
    {:application_name, "your_app"}
  ]
```

## Query sources

- [https://github.com/heroku/heroku-pg-extras](https://github.com/heroku/heroku-pg-extras)
- [https://hakibenita.com/postgresql-unused-index-size](https://hakibenita.com/postgresql-unused-index-size)
- [https://sites.google.com/site/itmyshare/database-tips-and-examples/postgres/useful-sqls-to-check-contents-of-postgresql-shared_buffer](https://sites.google.com/site/itmyshare/database-tips-and-examples/postgres/useful-sqls-to-check-contents-of-postgresql-shared_buffer)
- [https://wiki.postgresql.org/wiki/Index_Maintenance](https://wiki.postgresql.org/wiki/Index_Maintenance)

## Development

```bash
cp docker-compose.yml.sample docker-compose.yml
docker compose up -d
PG_VERSION=11 mix test --include distribution \
  && PG_VERSION=12 mix test --include distribution \
  && PG_VERSION=13 mix test --include distribution
```

By default tests will use the following database connection URL compatible with the default `docker-compose.yml`:

`ecto://postgres:postgres@localhost:5432/ecto_psql_extras`

Optionally, you can override the following variables:

`POSTGRES_USER`
`POSTGRES_USER`
`POSTGRES_HOST`
`POSTGRES_DB`

or provide the full `DATABASE_URL` connection URL.
