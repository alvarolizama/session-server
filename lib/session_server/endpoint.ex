defmodule SessionServer.Endpoint do
  @moduledoc """
    Endpoint for auth requests
  """

  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  get "/auth" do
    token = get_token_from_headers(conn)
    case SessionServer.Manager.check_session(token) do
      {:ok, response} ->
        send_resp(conn, 200, Jason.encode!(response))
      {:error, message} ->
        response = %{"error" => true, "message" => message}
        send_resp(conn, 401, Jason.encode!(response))
    end
  end

  defp get_token_from_headers(conn) do
    get_req_header(conn, "token") |> Enum.at(0)
  end

  match _ do
    send_resp(conn, 404, "404")
  end
end
