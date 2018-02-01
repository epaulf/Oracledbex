defmodule Oracle.Protocol do
  @moduledoc """
  Implementation of `DBConnection` behaviour for `Mssqlex.ODBC`.
  Handles translation of concepts to what ODBC expects and holds
  state for a connection.
  This module is not called directly, but rather through
  other `Mssqlex` modules or `DBConnection` functions.
  """
  use DBConnection

  alias Oracle.ODBC
  alias Oracle.Result

  defstruct [pid: nil, mssql: :idle, conn_opts: []]

  @typedoc """
  Process state.
  Includes:
  * `:pid`: the pid of the ODBC process
  * `:mssql`: the transaction state. Can be `:idle` (not in a transaction),
  `:transaction` (in a transaction) or `:auto_commit` (connection in
  autocommit mode)
  * `:conn_opts`: the options used to set up the connection.
  """
  @type state :: %__MODULE__{pid: pid(),
    mssql: :idle | :transaction | :auto_commit,
  conn_opts: Keyword.t}

  @type query :: Oracle.Query.t
  @type result :: Result.t
  @type params :: [{:odbc.odbc_data_type(), :odbc.value()}]
  @type cursor :: any
   @doc false
  @spec connect(opts :: Keyword.t) :: {:ok, pid()} | {:error, Exception.t}
  def connect(opts) do
    conn_opts = opts
    |> Keyword.put_new(:auto_commit, :off)
    |> Keyword.put_new(:timeout, 20000)
    |> Keyword.put_new(:extended_errors, :on)
    |> Keyword.put_new(:tuple_row, :off)
    |> Keyword.put_new(:binary_strings, :on)
    |> Keyword.put_new(:scrollable_cursors, :off)
    #conn_str = 'DSN=ORACLEPAUL;UID=test;PWD=test'
    conn_str = String.slice(Enum.reduce(opts, "", fn {key, value}, acc ->
      acc <> "#{key}=#{value};" end), 0..-2)
    case ODBC.start_link('#{conn_str}',conn_opts) do
      {:ok, pid} -> {:ok, %__MODULE__{
        pid: pid,
        conn_opts: conn_opts,
        mssql: if(conn_opts[:auto_commit] == :on,
        do: :auto_commit,
        else: :idle)
        }}
        response -> response
    end
  end

  @doc false
  @spec disconnect(err :: Exception.t, state) :: :ok
  def disconnect(_err, %{pid: pid} = state) do
    case ODBC.disconnect(pid) do
      :ok -> :ok
      {:error, reason} -> {:error, reason, state}
    end
  end

  @doc false
  @spec reconnect(new_opts :: Keyword.t, state) :: {:ok, state}
  def reconnect(new_opts, state) do
    with :ok <- disconnect("Reconnecting", state),
      do: connect(new_opts)
  end

  @doc false
  @spec checkout(state) :: {:ok, state}
                         | {:disconnect, Exception.t, state}
  def checkout(state) do
    {:ok, state}
  end

   @doc false
  @spec checkin(state) :: {:ok, state}
                        | {:disconnect, Exception.t, state}
  def checkin(state) do
    {:ok, state}
  end

   @doc false
  @spec handle_begin(opts :: Keyword.t, state) ::
    {:ok, result, state}
  | {:error | :disconnect, Exception.t, state}
  def handle_begin(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:begin, opts, state)
      :savepoint -> handle_savepoint(:begin, opts, state)
    end
  end

   @doc false
  @spec handle_commit(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_commit(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:commit, opts, state)
      :savepoint -> handle_savepoint(:commit, opts, state)
    end
  end

   @doc false
  @spec handle_rollback(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_rollback(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:rollback, opts, state)
      :savepoint -> handle_savepoint(:rollback, opts, state)
    end
  end

  defp handle_transaction(:begin, _opts, state) do
    case state.mssql do
      :idle -> {:ok, %Result{num_rows: 0}, %{state | mssql: :transaction}}
      :transaction -> {:error,
      %Oracle.Error{message: "Already in transaction"},
      state}
      :auto_commit -> {:error,
      %Oracle.Error{message: "Transactions not allowed in autocommit mode"},
      state}
    end
  end
  defp handle_transaction(:commit, _opts, state) do
    case ODBC.commit(state.pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:error, reason, state}
    end
  end
  defp handle_transaction(:rollback, _opts, state) do
    case ODBC.rollback(state.pid) do
      :ok -> {:ok, %Result{}, %{state | mssql: :idle}}
      {:error, reason} -> {:disconnect, reason, state}
    end
  end

  defp handle_savepoint(:begin, opts, state) do
    if state.mssql == :autocommit do
      {:error,
       %Oracle.Error{message: "savepoint not allowed in autocommit mode"},
       state}
    else
      handle_execute(
        %Oracle.Query{name: "", statement: "COMMIT"},
        [], opts, state)
    end
  end
  defp handle_savepoint(:commit, _opts, state) do
    {:ok, %Result{}, state}
  end
  defp handle_savepoint(:rollback, opts, state) do
    handle_execute(
      %Oracle.Query{name: "", statement: "ROLLBACK"},
      [], opts, state)
  end

  @doc false
  @spec handle_prepare(query, opts :: Keyword.t, state) ::
    {:ok, query, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @doc false
  @spec handle_execute(query, params, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_execute(query, params, opts, state) do
    {status, message, new_state} = do_query(query, params, opts, state)

    case new_state.mssql do
      :idle ->
        with {:ok, _, post_commit_state} <- handle_commit(opts, new_state)
        do
          {status, message, post_commit_state}
        end
      :transaction -> {status, message, new_state}
      :auto_commit ->
        with {:ok, post_connect_state} <- switch_auto_commit(:off, new_state)
        do
          {status, message, post_connect_state}
        end
    end
  end

  defp do_query(query, params, opts, state) do
  #  IO.puts query.statement
  #  IO.inspect state
    case ODBC.query(state.pid, query.statement, params, opts) do
      {:error,
        %Oracle.Error{odbc_code: :not_allowed_in_transaction} = reason} ->
        if state.mssql == :auto_commit do
          {:error, reason, state}
        else
          with {:ok, new_state} <- switch_auto_commit(:on, state),
            do: handle_execute(query, params, opts, new_state)
        end
      {:error,
        %Oracle.Error{odbc_code: :connection_exception} = reason} ->
        {:disconnect, reason, state}
      {:error, reason} ->
        {:error, reason, state}
      {:selected, columns, rows} ->
        {:ok, %Result{columns: Enum.map(columns, &(to_string(&1))), rows: rows, num_rows: Enum.count(rows)}, state}
      {:updated, num_rows} ->
        {:ok, %Result{num_rows: num_rows}, state}
    end
  end

  defp switch_auto_commit(new_value, state) do
    reconnect(Keyword.put(state.conn_opts, :auto_commit, new_value), state)
  end

  @doc false
  @spec handle_close(query, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_close(_query, _opts, state) do
    {:ok, %Result{}, state}
  end

  def ping(state) do
    query = %Oracle.Query{name: "ping", statement: "SELECT SYSDATE FROM DUAL"}
    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, new_state}
      {:error, reason, new_state} -> {:disconnect, reason, new_state}
      other -> other
    end
  end

end
