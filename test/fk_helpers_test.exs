defmodule FkHelpersTest do
  use ExUnit.Case, async: false
  alias EctoPSQLExtras.TestRepo

  setup do
    start_supervised!(TestRepo)
    Logger.configure(level: :info)

    statements = [
      "DROP TABLE IF EXISTS posts;",
      "DROP TABLE IF EXISTS users;",
      "DROP TABLE IF EXISTS topics;",
      "DROP TABLE IF EXISTS companies;",
      "CREATE TABLE users (
          id SERIAL PRIMARY KEY,
          email VARCHAR(255),
          company_id INTEGER
      );",
      "CREATE TABLE posts (
          id SERIAL PRIMARY KEY,
          user_id INTEGER NOT NULL,
          topic_id INTEGER,
          external_id INTEGER,
          title VARCHAR(255),
          CONSTRAINT fk_posts_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );",
      "CREATE TABLE topics (
          id SERIAL PRIMARY KEY,
          title VARCHAR(255)
      );",
      "CREATE TABLE companies (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255)
      );",
      "CREATE INDEX index_posts_on_user_id ON posts(user_id, topic_id);"
    ]

    Enum.each(statements, fn statement ->
      TestRepo.query!(statement)
    end)

    :ok
  end

  describe "table_schema" do
    test "returns schema info for the correct table" do
      result = EctoPSQLExtras.table_schema(TestRepo, args: [table_name: "users"], format: :raw)

      expected = [
        ["id", "integer", "NO", "nextval('users_id_seq'::regclass)", "users"],
        ["email", "character varying", "YES", nil, "users"],
        ["company_id", "integer", "YES", nil, "users"]
      ]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end
  end

  describe "table_foreign_keys" do
    test "returns foreign keys info for the correct table" do
      result =
        EctoPSQLExtras.table_foreign_keys(TestRepo, args: [table_name: "posts"], format: :raw)

      expected = [["posts", "fk_posts_user", "user_id", "users", "id"]]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end
  end

  describe "missing_fk_indexes" do
    test "returns correct result for all tables" do
      result =
        EctoPSQLExtras.missing_fk_indexes(TestRepo, format: :raw)

      expected = [
        ["posts", "topic_id"],
        ["users", "company_id"]
      ]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end

    test "returns correct result for a specific table" do
      result =
        EctoPSQLExtras.missing_fk_indexes(TestRepo, args: [table_name: :posts], format: :raw)

      expected = [
        ["posts", "topic_id"]
      ]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end
  end

  describe "missing_fk_constraints" do
    test "returns correct result for all tables" do
      result =
        EctoPSQLExtras.missing_fk_constraints(TestRepo, format: :raw)

      expected = [
        ["posts", "topic_id"],
        ["users", "company_id"]
      ]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end

    test "returns correct result for a specific table" do
      result =
        EctoPSQLExtras.missing_fk_constraints(TestRepo, args: [table_name: :posts], format: :raw)

      expected = [
        ["posts", "topic_id"]
      ]

      assert Enum.sort(result.rows) == Enum.sort(expected)
    end
  end
end
