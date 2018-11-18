Code.require_file("test_helper.exs", __DIR__)

defmodule Cabbage.FeatureImportTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "Features can import steps from other features" do
    test "can import empty steps" do
      defmodule FeatureImportableTest do
        use Cabbage.Feature
      end

      defmodule FeatureImporterTest do
        use Cabbage.Feature, file: "simplest.feature"
        import_steps(FeatureImportableTest)

        defthen ~r/^I provide Then$/, _vars, _state do
        end
      end

      ExUnit.Server.modules_loaded()
      capture_io(fn -> assert ExUnit.run() == %{failures: 0, skipped: 0, total: 1, excluded: 0} end)
    end

    test "can import all steps" do
      defmodule FeatureImportableTest2 do
        use Cabbage.Feature

        defthen ~r/^I provide Then$/, _vars, _state do
        end
      end

      defmodule FeatureImporterTest2 do
        use Cabbage.Feature, file: "simplest.feature"
        import_steps(FeatureImportableTest2)
      end

      ExUnit.Server.modules_loaded()
      capture_io(fn -> assert ExUnit.run() == %{failures: 0, skipped: 0, total: 1, excluded: 0} end)
    end

    test "can work together with imported steps" do
      defmodule FeatureImportableTest3 do
        use Cabbage.Feature

        defgiven ~r/^I provide Given$/, _vars, %{state: state} do
          {:ok, %{state: state + 1}}
        end

        defgiven ~r/^I provide And$/, _vars, %{state: state} do
          {:ok, %{state: state + 1}}
        end
      end

      defmodule FeatureImporterTest3 do
        use Cabbage.Feature, file: "simple.feature"
        import_steps(FeatureImportableTest3)

        setup do
          {:ok, %{state: 0}}
        end

        defwhen ~r/^I provide When$/, _vars, %{state: state} do
          {:ok, %{state: state + 1}}
        end

        defthen ~r/^I provide Then$/, _vars, %{state: state} do
          assert state == 3
        end
      end

      ExUnit.Server.modules_loaded()
      capture_io(fn -> assert ExUnit.run() == %{failures: 0, skipped: 0, total: 1, excluded: 0} end)
    end
  end

  describe "Features can import tags from other features" do
    test "can import empty tags" do
      defmodule FeatureImportableTest4 do
        use Cabbage.Feature
      end

      defmodule FeatureImporterTest4 do
        use Cabbage.Feature, file: "simplest.feature"
        import_tags(FeatureImportableTest4)

        defthen ~r/^I provide Then$/, _vars, _state do
        end
      end

      ExUnit.Server.modules_loaded()
      capture_io(fn -> assert ExUnit.run() == %{failures: 0, skipped: 0, total: 1, excluded: 0} end)
    end

    @doc """
    tag callback isn't called
    """
    test "can import provided tags" do
      defmodule FeatureImportableTest5 do
        use Cabbage.Feature

        tag @module_tag do
          {:ok, %{module_state: "state"}}
        end

        tag @another_module_tag do
          4
        end
      end

      defmodule FeatureImporterTest5 do
        use Cabbage.Feature, file: "simplest.feature"
        @moduletag :module_tag
        @moduletag :another_module_tag

        import_tags(FeatureImportableTest5)

        defthen ~r/^I provide Then$/, _vars, state do
          assert state.module_state == "state"
        end
      end

      # %{failures: 0, skipped: 0, total: 1, excluded: 0}
      ExUnit.Server.modules_loaded()
      capture_io(fn -> assert ExUnit.run() end) |> IO.inspect()
    end
  end

  describe "Features can import whole features" do
    # TODO: Implement
  end
end
