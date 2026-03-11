defmodule JopTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @jopname "jobtest"

  #  doctest Jop

  setup do
    on_exit(fn -> clean_jop_files(@jopname) end)
  end

  test "ref from uninitialized" do
    jop = Jop.ref(@jopname)
    refute Jop.initialized?(jop)
  end

  test "ref from initialized" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      assert try do: Jop.ref(@jopname), catch: (_any -> false), else: (_ -> true)
      assert is_struct(jop, Jop)
    end)
  end

  test "double init" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      ^jop = Jop.init(@jopname)
      assert is_struct(jop, Jop)
      assert Enum.empty?(jop)
      assert jop == Jop.flush(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "clear" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      Jop.log(jop, "key_1", :any_term_112)
      Jop.clear(jop)
      assert Enum.empty?(jop)
      assert jop == Jop.flush(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "flush" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      Jop.log(jop, "key_1", :any_term_112)
      Jop.flush(jop)
      refute Jop.initialized?(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "flush nostop" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      Jop.log(jop, "key_1", :any_term_112)
      Jop.flush(jop, :nostop)
      assert jop == Jop.log(jop, "mykey2", {:vv, 113})
      assert Enum.count(jop) == 1
      assert jop == Jop.flush(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "log_and_dump" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      assert is_struct(jop, Jop)

      assert jop == Jop.log(jop, "mykey1", {:vv, 112})
      :timer.sleep(12)
      assert jop == Jop.init(@jopname)

      assert jop == Jop.log(jop, "mykey2", {:vv, 113})

      :timer.sleep(12)
      assert jop = Jop.log(jop, "mykey1", {:vv, 112})

      :timer.sleep(12)
      assert jop == Jop.log(jop, "mykey2", {:vv, 113})

      assert Enum.count(jop) == 3
      assert jop == Jop.flush(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "start_time present" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      assert is_integer(Jop.start_time(jop))
    end)
  end

  test "initialized?" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      assert Jop.initialized?(jop)
      assert jop == Jop.flush(jop)
    end)

    assert all_logs_are_present?(@jopname)
  end

  test "enumerable" do
    capture_io(fn ->
      jop = Jop.init(@jopname)
      assert is_struct(jop, Jop)
      assert jop == Jop.log(jop, "mykey", "myvalue")
      assert jop == Jop.log(jop, "mykey", "myvalue777")
      assert Enum.count(jop) == 2
      assert Enum.member?(jop, "mykey")
      assert 10 == Enum.reduce(jop, 0, fn {_k, val}, acc -> max(byte_size(val), acc) end)
    end)
  end

  defp all_logs_are_present?(id),
    do: 2 == length(Path.wildcard("jop_#{id}*.gz"))

  def clean_jop_files(id) do
    for file <- Path.wildcard("jop_#{id}*.gz"),
        do: File.rm!(file)
  end
end
