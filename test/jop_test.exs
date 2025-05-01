defmodule JopTest do
  use ExUnit.Case
  @jop_log "test_jop_log"

  #  doctest Jop

  setup do
    on_exit(fn -> clean_jop_files(@jop_log) end)
  end

  test "ref from uninitialized" do
    jop = Jop.ref(@jop_log)
    refute Jop.initialized?(jop)
  end

  test "ref from initialized" do
    joplog = Jop.init(@jop_log)
    assert try do: Jop.ref(@jop_log), catch: (any -> false), else: (_ -> true)
    assert is_struct(joplog, Jop)
  end

  test "double init" do
    joplog = Jop.init(@jop_log)
    ^joplog = Jop.init(@jop_log)
    assert is_struct(joplog, Jop)
    assert Enum.empty?(joplog)
    assert joplog == Jop.flush(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "clear" do
    joplog = Jop.init(@jop_log)
    Jop.log(joplog, "key_1", :any_term_112)
    Jop.clear(joplog)
    assert Enum.empty?(joplog)
    assert joplog == Jop.flush(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "flush" do
    joplog = Jop.init(@jop_log)
    Jop.log(joplog, "key_1", :any_term_112)
    Jop.flush(joplog)
    refute Jop.initialized?(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "flush nostop" do
    joplog = Jop.init(@jop_log)
    Jop.log(joplog, "key_1", :any_term_112)
    Jop.flush(joplog, :nostop)
    assert joplog == Jop.log(joplog, "mykey2", {:vv, 113})
    assert Enum.count(joplog) == 1
    assert joplog == Jop.flush(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "log_and_dump" do
    joplog = Jop.init(@jop_log)
    assert is_struct(joplog, Jop)

    assert joplog == Jop.log(joplog, "mykey1", {:vv, 112})
    :timer.sleep(12)
    assert joplog == Jop.init(@jop_log)

    assert joplog == Jop.log(joplog, "mykey2", {:vv, 113})

    :timer.sleep(12)
    assert joplog = Jop.log(joplog, "mykey1", {:vv, 112})

    :timer.sleep(12)
    assert joplog == Jop.log(joplog, "mykey2", {:vv, 113})

    assert Enum.count(joplog) == 3
    assert joplog == Jop.flush(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "initialized?" do
    joplog = Jop.init(@jop_log)
    assert Jop.initialized?(joplog)
    assert joplog == Jop.flush(joplog)
    assert all_logs_are_present?(@jop_log)
  end

  test "enumerable" do
    joplog = Jop.init(@jop_log)
    assert is_struct(joplog, Jop)
    assert joplog == Jop.log(joplog, "mykey", "myvalue")
    assert joplog == Jop.log(joplog, "mykey", "myvalue777")
    assert Enum.count(joplog) == 2
    assert Enum.member?(joplog, "mykey")
    assert 10 == Enum.reduce(joplog, 0, fn {_k, val}, acc -> max(byte_size(val), acc) end)
  end

  defp all_logs_are_present?(id),
    do: 2 == length(Path.wildcard("jop_#{id}*.gz"))

  def clean_jop_files(id) do
    for file <- Path.wildcard("jop_#{id}*.gz"),
        do: File.rm!(file)
  end
end
