defmodule Sweetconfig do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Sweetconfig.Worker, [arg1, arg2, arg3])
    ]

    :sweetconfig = :ets.new :sweetconfig, [:named_table, {:read_concurrency, true}, :public, :protected]
    opts = [strategy: :one_for_one, name: Sweetconfig.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp lookup_config(config, []), do: config
  defp lookup_config(config, path) do
    get_in(config, path)
  end

  def get([root | path]) do
    case :ets.lookup(:sweetconfig, root) do
      [{^root, config}] -> lookup_config(config, path)
      [] -> nil
    end
  end
  def get(path), do: :ets.lookup(:sweetconfig, path)
end

defmodule Sweetconfig.Utils do
  def load_configs do
    case File.ls("priv/") do
      {:ok, files} -> process_files(files) |> push_to_ets 
      {:error, _} -> {:error, :no_configs}
    end
  end

  defp push_to_ets([]), do: []
  defp push_to_ets([configs]) do
    IO.puts "#{inspect configs}"
    for {key, value} <- configs do
      IO.puts "Inserting #{inspect key} into ets"
      :ets.insert(:sweetconfig, {key, value})
    end
  end
  defp push_to_ets(configs) when is_list(configs) do
    case Enum.all?(configs, &is_map/1) do
      true -> [Enum.reduce(configs, %{}, &Map.merge/2)] |> push_to_ets
      false -> raise "Strange configuration structure: #{inspect configs}"
    end
  end

  defp load_config(file) do
    case :yaml.load_file("priv/" <> file, [:implicit_atoms]) do
      {:ok, data} -> data
      _err -> raise "Failed to parse configuration file #{file} with error #{inspect _err}"
    end
  end

  defp process_files([]), do: %{}
  defp process_files(files) do
    Enum.reduce(files, [], fn file, merged_config ->
      case file =~ ~r/\.ya?ml$/ do
        true -> load_config(file) ++ merged_config
        false -> merged_config
      end  
    end)
  end 
end