defmodule Oracledbex.LoginTest do
  use ExUnit.Case, async: false

  alias Oracle.Result

  test "Given valid details, connects to database" do
    assert {:ok, pid} = Oracledbex.start_link([{"DSN","ORACLEODBC"}])
    assert {:ok, _, %Result{columns: ["DUMMY"], num_rows: 1, rows: [["X"]]}} =
      Oracledbex.query(pid, "SELECT * FROM DUAL", [])
  end

  test "Given invalid details, errors" do
    Process.flag(:trap_exit, true)
    assert {:ok, pid} = Oracledbex.start_link([{"DSN","DUMMY_ODBC"}])
    # IM002 [unixODBC][Driver Manager]Data source name not found, and no default driver specified Connection to database failed.
    assert_receive {:EXIT, ^pid,
                    %Oracle.Error{odbc_code: "IM002"}}
  end
end