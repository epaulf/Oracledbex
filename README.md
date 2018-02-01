# Oracledbex
[![GitHub stars](https://img.shields.io/github/stars/epaulf/Oracledbex.svg?style=plastic)](https://github.com/epaulf/Oracledbex/stargazers)
[![Twitter](https://img.shields.io/twitter/url/https/github.com/epaulf/Oracledbex/.svg?style=social&style=plastic)](https://twitter.com/intent/tweet?text=Wow:&url=https%3A%2F%2Fgithub.com%2Fepaulf%2FOracledbex%2F)
[![GitHub license](https://img.shields.io/github/license/epaulf/Oracledbex.svg)](https://github.com/epaulf/Oracledbex/blob/master/LICENSE)


**Adapter to Oracle Database. Using `DBConnection` and `ODBC`.**

> **Based on the project :** [Mssqlex](https://github.com/findmypast-oss/mssqlex)

> **Documentation in development**

> **Test in development**

## Getting Started

Oracledbex requires the Erlang ODBC application to be installed.

### ***To install what is necessary for the odbc connection, refer to the following manual:*** [ODBC.md]()  

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `oracledbex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:oracledbex, "~> 0.1.0"}
  ]
end
```

## Quickfast introduction

- **Conection**
```elixir
iex(1)> {:ok, pid} = Oracledbex.start_link([{"DSN","ORACLEODBC"}])
{:ok, #PID<0.174.0>}
```
### Examples
- **Select**
```elixir
iex(4)> {:ok,_,data} = Oracledbex.query(pid,"SELECT SYSDATE FROM DUAL",[])
{:ok,
 %Oracle.Query{columns: nil, name: "", statement: "SELECT SYSDATE FROM DUAL"},
 %Oracle.Result{columns: ["SYSDATE"], num_rows: 1,
  rows: [[{{2018, 1, 31}, {23, 18, 59, 0}}]]}}

{:ok,_,data} = Oracledbex.query(pid,"SELECT * FROM HR.EMPLOYEES",[])
{:ok,
 %Oracle.Query{columns: nil, name: "", statement: "SELECT * FROM HR.EMPLOYEES"},
 %Oracle.Result{columns: ["EMPLOYEE_ID", "FIRST_NAME", "LAST_NAME", "EMAIL",
   "PHONE_NUMBER", "HIRE_DATE", "JOB_ID", "SALARY", "COMMISSION_PCT",
   "MANAGER_ID", "DEPARTMENT_ID"], num_rows: 107,
  rows: [[100, "Steven", "King", "SKING", "515.123.4567",
    {{2003, 6, 17}, {0, 0, 0, 0}}, "AD_PRES", #Decimal<2.4E+4>, nil, nil, 90],
   [101, "Neena", "Kochhar", "NKOCHHAR", "515.123.4568",
    {{2005, 9, 21}, {0, 0, 0, 0}}, "AD_VP", #Decimal<1.7E+4>, nil, 100, 90],

iex(4)> {:ok,_,data} = Oracledbex.query(pid,"SELECT * FROM HR.EMPLOYEES WHERE EMPLOYEE_ID = ? AND FIRST_NAME = ?",[115,"Alexander"])
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "SELECT * FROM HR.EMPLOYEES WHERE EMPLOYEE_ID = ? AND FIRST_NAME = ?"},
 %Oracle.Result{columns: ["EMPLOYEE_ID", "FIRST_NAME", "LAST_NAME", "EMAIL",
   "PHONE_NUMBER", "HIRE_DATE", "JOB_ID", "SALARY", "COMMISSION_PCT",
   "MANAGER_ID", "DEPARTMENT_ID"], num_rows: 1,
  rows: [[115, "Alexander", "Khoo", "AKHOO", "515.127.4562",
    {{2003, 5, 18}, {0, 0, 0, 0}}, "PU_CLERK", #Decimal<3.1E+3>, nil, 114,
    30]]}}
```

- **Update**
```elixir
iex(5)> {:ok,_,data} = Oracledbex.query(pid,"UPDATE HR.EMPLOYEES SET SALARY = ? WHERE EMPLOYEE_ID = ?",[20000,115])
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "UPDATE HR.EMPLOYEES SET SALARY = ? WHERE EMPLOYEE_ID = ?"},
 %Oracle.Result{columns: nil, num_rows: 1, rows: nil}}
```
- **Delete**
```elixir
iex(7)> {:ok,_,data} = Oracledbex.query(pid,"DELETE  FROM HR.EMPLOYEES WHERE EMPLOYEE_ID = ?",[115])
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "DELETE  FROM HR.EMPLOYEES WHERE EMPLOYEE_ID = ?"},
 %Oracle.Result{columns: nil, num_rows: 1, rows: nil}}
```
- **Insert**
```elixir
iex(3)> {:ok,_,data} = Oracledbex.query(pid,"INSERT INTO HR.EMPLOYEES (EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,JOB_ID,SALARY,MANAGER_ID,DEPARTMENT_ID,HIRE_DATE) VALUES (?,?,?,?,?,?,?,?,?,TO_DATE(?,'DD/MM/RR'))",[4000,"ERIC","Flores","ericpaulfloresegmail.com","44444.44","PU_CLERK",300000,114,30,"31/01/18"])
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "INSERT INTO HR.EMPLOYEES (EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,JOB_ID,SALARY,MANAGER_ID,DEPARTMENT_ID,HIRE_DATE) VALUES (?,?,?,?,?,?,?,?,?,TO_DATE(?,'DD/MM/RR'))"},
 %Oracle.Result{columns: nil, num_rows: 1, rows: nil}}
```
## Pool connection
### Example
- **Conection**
```elixir
iex(1)> {:ok,pool} = DBConnection.start_link(Oracle.Protocol,[{"DSN","ORACLEODBC"},{:pool_size,5},{:pool,DBConnection.Poolboy}])
{:ok, #PID<0.175.0>}
```
- **Examples of querys whith pool connection**
```elixir
{:ok,_,data} = Oracledbex.query(pool,"SELECT SYSDATE FROM DUAL",[],pool: DBConnection.Poolboy)
{:ok,
 %Oracle.Query{columns: nil, name: "", statement: "SELECT SYSDATE FROM DUAL"},
 %Oracle.Result{columns: ["SYSDATE"], num_rows: 1,
  rows: [[{{2018, 2, 1}, {0, 55, 57, 0}}]]}}
```
```elixir
iex(4)> {:ok,_,data} = Oracledbex.query(pool,"SELECT FIRST_NAME  FROM HR.EMPLOYEES",[],pool: DBConnection.Poolboy)
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "SELECT FIRST_NAME FROM HR.EMPLOYEES"},
 %Oracle.Result{columns: ["FIRST_NAME"], num_rows: 107,
  rows: [["Ellen"], ["Sundar"], ["Mozhe"], ["David"], ["Hermann"], ["Shelli"],
   ["Amit"], ["Elizabeth"], ["Sarah"], ["David"], ["Laura"], ["Harrison"],
   ["Alexis"], ["Anthony"], ["Gerald"], ["Nanette"], ["John"], ["Kelly"],
   ["Karen"], ["Curtis"], ["Lex"], ["Julia"], ["Jennifer"], ["Louise"],
   ["Bruce"], ["Alberto"], ["Britney"], ["Daniel"], ["Pat"], ["Kevin"],
   ["Jean"], ["ERIC"], ["Tayler"], ["Adam"], ["Timothy"], ["Ki"], ["Girard"],
   ["William"], ["Douglas"], ["Kimberely"], ["Nancy"], ["Danielle"], ["Peter"],
   ["Michael"], ["Shelley"], [...], ...]}}
```
```elixir
iex(5)> {:ok,_,data} = Oracledbex.query(pool,"SELECT *  FROM HR.COUNTRIES WHERE  REGION_ID = ?",[1],pool: DBConnection.Poolboy)
{:ok,
 %Oracle.Query{columns: nil, name: "",
  statement: "SELECT *  FROM HR.COUNTRIES WHERE  REGION_ID = ?"},
 %Oracle.Result{columns: ["COUNTRY_ID", "COUNTRY_NAME", "REGION_ID"],
  num_rows: 8,
  rows: [["BE", "Belgium", #Decimal<1.0>], ["CH", "Switzerland", #Decimal<1.0>],
   ["DE", "Germany", #Decimal<1.0>], ["DK", "Denmark", #Decimal<1.0>],
   ["FR", "France", #Decimal<1.0>], ["IT", "Italy", #Decimal<1.0>],
   ["NL", "Netherlands", #Decimal<1.0>],
   ["UK", "United Kingdom", #Decimal<1.0>]]}}
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/oracledbex](https://hexdocs.pm/oracledbex).

