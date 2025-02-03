# Test module
defmodule EctoPSQLExtras.DetectFkColumnTest do
  use ExUnit.Case

  alias EctoPSQLExtras.DetectFkColumn

  test "detects foreign key column" do
    assert DetectFkColumn.call("user_id", ["users", "orders"]) == true
    assert DetectFkColumn.call("order_id", ["users", "orders"]) == true
    assert DetectFkColumn.call("product_id", ["users", "orders"]) == false
    assert DetectFkColumn.call("quiz_id", ["quizzes", "orders"]) == true
  end

  test "handles irregular plurals" do
    assert DetectFkColumn.call("person_id", ["people"]) == true
    assert DetectFkColumn.call("child_id", ["children"]) == true
    assert DetectFkColumn.call("octopus_id", ["octopi"]) == true
  end

  test "handles uncountable words" do
    assert DetectFkColumn.call("equipment_id", ["equipment"]) == true
  end
end
