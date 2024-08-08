defmodule Battle.Utils.ConstMacro do
  @moduledoc false

  defmacro const(const_name, const_value) do
    quote do
      def unquote(const_name)(), do: unquote(const_value)
    end
  end

  defmacro defenum(name, do: block) do
    quote generated: true, location: :keep do
      defmodule unquote(name) do
        Module.register_attribute(__MODULE__, :possible_options, accumulate: true)
        unquote(block)

        def options() do
          @possible_options |> Enum.reverse()
          # [
          #   {CenterArea.InCountry, "in_country", [domain: "ejoy.com"]},
          #   {CenterArea.Oversea, "oversea", [domain: "qookkagames.com"]}
          # ]
        end

        def values() do
          @possible_options |> Enum.map(fn {_, value, _} -> value end) |> Enum.reverse()
          # ["in_country", "oversea"]
        end

        def enums() do
          @possible_options |> Enum.map(fn {sym, _, _} -> sym end) |> Enum.reverse()
          # [CenterArea.InCountry, CenterArea.Oversea]
        end
      end
    end
  end

  defmacro defvalue(name, value, opts \\ []) do
    quote generated: true, location: :keep  do
      @possible_options {__MODULE__.unquote(name), unquote(value), unquote(opts)}

      defmodule unquote(name) do
        def value() do
          unquote(value)
        end
        def opts() do
          unquote(opts)
        end
      end
    end
  end
end
