defmodule SessionServer.Manager do
  @moduledoc """
  Manager for Session Server
  """

  require Logger

  @doc """
  Create an ETS table to store sessions
  """
  def create_table do
    :ets.new(:session_table, [:set, :protected, :named_table])
  end

  @doc """
  Create a session, the UID must be unique, could be an user id.
  This function return a token.
  """
  def create_session(uid, ttl \\ 99999, metadata \\ %{}) do
    timestamp = :os.system_time(:seconds)
    :ets.insert(:session_table, {uid, timestamp, ttl, metadata})
    Base.encode64(uid, padding: false) <> "." <> sign_uid(uid)
  end

  @doc """
  Check if a session token is valid, exist and is not expired
  """
  def check_session(token) do
    case validate_token(token) do
      {:ok, uid} ->
        validate_session(uid)
      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Delete a session by the unique id
  """
  def delete_session(uid) do
    :ets.delete(:session_table, uid)
  end

  @doc """
  Delete all sessions
  """
  def delete_all_session() do
    :ets.delete(:session_table)
    create_table()
  end

  defp validate_token(token) do
    [uid, sign] = String.split(token, ".")
    uid = Base.decode64!(uid, padding: false)

    if sign == sign_uid(uid) do
      {:ok, uid}
    else
      {:error, "This token was altered!!!!!"}
    end
  end

  defp validate_session(uid) do
    session = :ets.lookup(:session_table, uid) |> Enum.at(0)

    case session do
      invalid_session when is_nil(invalid_session) ->
        {:error, "Session not found"}
      valid_session when is_tuple(valid_session) ->
        {uid, timestamp, ttl, metadata} = valid_session

        current_timestamp = :os.system_time(:seconds)
        diff_timestamps = current_timestamp - timestamp
        if diff_timestamps < ttl do
          {:ok,
            %{
              "uid" => uid,
              "timestamp" => timestamp,
              "ttl" => ttl,
              "metadata" => metadata
            }
          }
        else
          {:error, "Session expired"}
        end
    end
  end

  defp sign_uid(uid) do
    secret = Application.get_env(:session_server, :secret, "CHANGEMEPELANA")
    :crypto.hmac(:sha256, secret, uid) |> Base.encode64(padding: false)
  end
end
