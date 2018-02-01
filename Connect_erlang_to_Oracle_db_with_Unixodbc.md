# Connect erlang to Oracle db with Unixodbc

 1. **Download driver ODBC  for oracle database**
 - for linux 64 bits [instantclient-odbc-linux.x64-12.2.0.1.0-2.zip ](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html)
 - for mac os 64 bits [instantclient-odbc-macos.x64-12.2.0.1.0-2.zip](http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html)
 	 ```bash
 	 $ cp instantclient-odbc-"your os version".zip /usr/local
 	 $ cd /usr/local
 	 $ unzip instantclient-odbc-"your os version".zip
 	 $ cd /usr/local/instantclient_12_2
 	 #Add lib directories to the environment
 	 $ export ORACLE_HOME=/usr/local/instantclient_12_2
 	 $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME
	 ```
 2. **Install unixODBC**
	 1. for linux and mac os download: [unixODBC-2.3.5.tar.gz](http://www.unixodbc.org/unixODBC-2.3.5.tar.gz)
	 2. build unixODBC:
	 ```bash 
	 $ export CFLAGS=-m64
	 $ mkdir /usr/local/unixODBC
	 $ cp unixODBC-2.3.5.tar.gz /usr/local/unixODBC
	 $ cd /usr/local/unixODBC
	 $ tar vzxf unixODBC-2.3.5.tar.gz
	 $ ./configure --prefix=/usr/local/unixODBC
	 $ make
	 $ sudo make install
	 ```
	 3. Add bin and lib subdirectories to the environment
	 ```bash 
	 $ export PATH=$PATH:/usr/local/unixodbc/bin
	 $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/unixodbc/lib
	```
3. **Edit unixODBC config files**
	 1. odbcinst.ini
 	 ```bash
 	 $ sudo vi /usr/local/unixODBC/etc/odbcinst.ini
 	 [ORACLE]
	Description     = Oracle ODBC driver for Oracle 11g
	Driver          = /usr/local/instantclient_12_2/libsqora.dylib.12.2
	Setup           =
	FileUsage       =
	CPTimeout       =
	CPReuse         =
	Driver Logging  =
	 ```
	 > **NOTE :**
	 Driver  = write the path where the odbc library is located
	 **in this example is the mac library**
	 
	 2.odbc.ini
	  ```bash
    $ sudo vi /usr/local/unixODBC/etc/odbc.ini
    [ORACLEODBC]
	Driver = ORACLE
	DSN = ORACLEODBC
	SERVER = 127.0.0.1
	PORT = 1521	
	DATABASE = xe
	UserID = your user
	Password = your password
	ServerName =//127.0.0.1:1521/xe
 	 ```
3. **Test in terminal**
```bash
isql -v ORACLEODBC
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> select * from dual;
+------+
| DUMMY|
+------+
| X    |
+------+
SQLRowCount returns -1
1 rows fetched
SQL>
 ```
> **FAIL  test  ?** 
> go to reference [3] 
 4.  **Test  in erlang**
 ```bash
$ erl
Erlang/OTP 20 [erts-9.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

Eshell V9.1  (abort with ^G)
1> odbc:start().
ok
2> {ok, Pid} = odbc:connect("DSN=ORACLEODBC", [{scrollable_cursors, off}]).
{ok,<0.114.0>}
3> odbc:sql_query(Pid, "select (1) from dual").
{selected,["(1)"],[{1.0}]}
 ```
> **Try connect to oracle from Erlang shell [1]**
NOTE: If Erlang OTP was built from source code, and lib/erlang/lib/odbc-* can not be found in OTP install directory, you'll have to install libodbc first, then redo configure and make install.

## References

[1][https://elixirforum.com/t/iex-odbc-build-on-solaris-11-3/8925](https://elixirforum.com/t/iex-odbc-build-on-solaris-11-3/8925)

[2][http://zmstone.blogspot.mx/2014/07/erlang-unixodbc-to-oracle.html](http://zmstone.blogspot.mx/2014/07/erlang-unixodbc-to-oracle.html)

[3][https://gerardnico.com/wiki/db/oracle/odbc_linux](https://gerardnico.com/wiki/db/oracle/odbc_linux)
