defmodule EctoPSQLExtras.Extensions do
  def title do
    "Available and installed extensions"
  end

  def query do
"""
/* Available and installed extensions */

SELECT * FROM pg_available_extensions ORDER BY installed_version;
"""
  end
end
