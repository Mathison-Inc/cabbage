Logger.configure_backend(:console, colors: [enabled: false])
ExUnit.start(trace: "--trace" in System.argv())

# Beam files compiled on demand
path = Path.expand("../tmp/beams", __DIR__)
File.rm_rf!(path)
File.mkdir_p!(path)
Code.prepend_path(path)

defmodule PickleTestHelper do
  import ExUnit.CaptureIO

  def run(filters \\ [], cases \\ [])

  def run(filters, module) do
    {add_module, load_module, result_fix} = versioned_callbacks()

    Enum.each(module, add_module)
    load_module.()

    opts =
      ExUnit.configuration()
      |> Keyword.merge(filters)
      |> Keyword.merge(colors: [enabled: false])

    output = capture_io(fn -> Process.put(:capture_result, ExUnit.Runner.run(opts, nil)) end)
    {result_fix.(Process.get(:capture_result)), output}
  end

  versioned_cbs =
    System.version()
    |> Version.compare("1.6.6")
    |> case do
      :lt ->
        quote do: {&ExUnit.Server.add_sync_case/1, &ExUnit.Server.cases_loaded/0, &fix_13_elixir_test_result/1}

      :eq ->
        quote do: {&ExUnit.Server.add_async_module/1, &ExUnit.Server.modules_loaded/0, &fix_13_elixir_test_result/1}

      _ ->
        quote do: {&ExUnit.Server.add_sync_module/1, &ExUnit.Server.modules_loaded/0, &fix_17_elixir_test_result/1}
    end

  defp versioned_callbacks() do
    unquote(versioned_cbs)
  end

  defp fix_17_elixir_test_result(result), do: result

  unless Version.compare(System.version(), "1.6.6") == :gt do
    defp fix_13_elixir_test_result(result) do
      Map.merge(result, %{excluded: Map.get(result, :skipped, 0), skipped: 0})
    end
  end
end
