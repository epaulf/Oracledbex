defmodule Oracledbex do
  require Logger
  @moduledoc """
  Interface for interacting with Oracle Database via an ODBC driver for Elixir.

  It implements `DBConnection` behaviour, using `:odbc` to connect to the
  system's ODBC driver. Requires Oracle Database ODBC driver, see
  [ODBCREADME](readme.html) for installation instructions.
  """

  alias Oracle.Query
  alias Oracle.Type

  @doc """
  Connect to a Oracle Database using ODBC.

  `opts` expects a keyword list with zero or more of:

    * `:dsn` - name of driver the adapter will use
    * `:username` - Username
    * `:password` - User password

  `Oracledbex` uses the `DBConnection` framework and supports all `DBConnection`
  options like `:idle`, `:after_connect` etc.
  See `DBConnection.start_link/2` for more information.

  ## Examples

      {:ok, pid} = Oracledbex.start_link([{"DSN","ORACLEODBC"}])
      {:ok, #PID<0.268.0>}

  """
  @spec start_link(Keyword.t) :: {:ok, pid}
  def start_link(opts) do
    DBConnection.start_link(Oracle.Protocol, opts)
  end

  @doc """
  Executes a query against an Oracle Database with ODBC.

  `conn` expects a `Oracledbex` process identifier.

  `statement` expects a SQL query string.

  `params` expects a list of values in one of the following formats:

    * Strings with only valid ASCII characters, which will be sent to the
      database as strings.
    * `Decimal` structs, which will be encoded as strings so they can be
      sent to the database with arbitrary precision.
    * Integers, which will be sent as-is if under 10 digits or encoded
      as strings for larger numbers.

  `opts` expects a keyword list with zero or more of:

    * `:mode` - set to `:savepoint` to use a savepoint to rollback to before the
    query on error, otherwise set to `:transaction` (default: `:transaction`);

  Result values will be encoded according to the following conversions:

    * char and varchar: strings.
    * nchar and nvarchar: strings unless `:preserve_encoding` is set to `true`
      in which case they will be returned as UTF16 Little Endian binaries.
    * int, smallint, tinyint, decimal and numeric when precision < 10 and
      scale = 0 (i.e. effectively integers): integers.
    * float, real, double precision, decimal and numeric when precision between
      10 and 15 and/or scale between 1 and 15: `Decimal` structs.
    * bigint, money, decimal and numeric when precision > 15: strings.
    * date: `{year, month, day}`
    * uniqueidentifier, time, binary, varbinary, rowversion: not currently
      supported due to adapter limitations. Select statements for columns
      of these types must convert them to supported types (e.g. varchar).
  """
  @spec query(pid(), binary(), [Type.param()], Keyword.t) ::
    {:ok, iodata(), Oracle.Result.t}
  def query(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute(
      conn, %Query{name: "", statement: statement}, params, opts)
  end

  @doc """
  Executes a query against an Oracle Database with ODBC.

  Raises an error on failure. See `query/4` for details.
  """
  @spec query!(pid(), binary(), [Type.param()], Keyword.t) ::
    {iodata(), Oracle.Result.t}
  def query!(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute!(
      conn, %Query{name: "", statement: statement}, params, opts)
  end
end
