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
    Sweetconfig.Utils.load_configs
    opts = [strategy: :one_for_one, name: Sweetconfig.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp lookup_config(config, []), do: config
  defp lookup_config(config, path) do
    get_in(config, path)
  end

  def get(path, defaults) do
    case get(path) do
      nil -> defaults
      values -> values
    end
  end
  def get([root | path]) do
    case :ets.lookup(:sweetconfig, root) do
      [{^root, config}] -> lookup_config(config, path)
      [] -> nil
    end
  end
  def get(path) do
    case :ets.lookup(:sweetconfig, path) do
      [] -> nil
      [{^path, config}] -> config
    end
  end
end

defmodule Sweetconfig.Utils do
  @app Mix.Project.config[:app]
  defp get_config_app do
    :application.get_all_env(:sweetconfig)[:app] || @app
  end
  def load_configs do
    path = :code.priv_dir(get_config_app) |> :erlang.list_to_binary
    case File.ls(path) do
      {:ok, files} -> 
        Enum.map(files, fn file -> path <> "/" <> file end) 
          |> process_files 
          |> push_to_ets 
      {:error, _} -> {:error, :no_configs}
    end
  end

  defp pre_process(int) when is_integer(int), do: int
  defp pre_process(atom) when is_atom(atom), do: atom
  defp pre_process(bin) when is_binary(bin), do: bin
  defp pre_process(list) when is_list(list) do
    for el <- list, into: [] do
      pre_process(el)
    end
  end
  defp pre_process(%{type: type, value: value}) when is_binary(value) do
    case type do
      :list -> :erlang.binary_to_list(value)
      :binary -> value
    end
  end
  defp pre_process(%{type: type, value: value}) when is_atom(value) do
    case type do
      :list -> :erlang.atom_to_list(value)
      :binary -> :erlang.atom_to_binary(value, :utf8)
    end
  end
  defp pre_process(map) when is_map(map) do
    for {k, v} <- map, into: %{} do
      {k, pre_process(v)}
    end
  end
  defp pre_process({k,v}) do 
    pre_process({k, pre_process(v)})
  end

  defp push_to_ets([]), do: []
  defp push_to_ets([configs]) do
    for {key, value} <- configs do
      :ets.insert(:sweetconfig, {key, pre_process(value)})
    end
    configs
  end
  defp push_to_ets(configs) when is_list(configs) do
    case Enum.all?(configs, &is_map/1) do
      true -> [Enum.reduce(configs, %{}, &Map.merge/2)] |> push_to_ets
      false -> raise "Strange configuration structure: #{inspect configs}"
    end
  end

  defp load_config(file) do
    case :yaml.load_file(file, [:implicit_atoms]) do
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