Code.require_file "support/test_repo.exs", __DIR__

ExUnit.configure(exclude: :distribution)
ExUnit.start()
