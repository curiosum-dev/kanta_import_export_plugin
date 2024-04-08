defmodule Kanta.ImportExport.MapperPlug do
  @moduledoc """
  Puts mapper into the conn's assigns to use in controllers
  """

  import Plug.Conn, only: [assign: 3]

  @behaviour Plug

  def init(opts \\ []), do: opts

  def call(conn, mapper: mapper) do
    assign(conn, :mapper, mapper)
  end
end
