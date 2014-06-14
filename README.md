Sweetconfig
===========

Place configuration YAML files in `priv/` directory of your root application. Add following section to your `config.exs` file:


```elixir
config :sweetconfig,
	app: :name_of_your_application
```


Include `:sweetconfig` into your app deps list.


Now you can read configuration from any point at your app like this:


```elixir
	Sweetconfig.get :somekey
	Sweetconfig.get [:somekey, :somesubkey]
	Sweetconfig.get :whatever, :default_value
```


TBD: notification service on configuration changes.

