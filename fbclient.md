### Work in progress ###
In the meantime, you can use the old pure-Lua alien-based [binding](https://code.google.com/p/fbclient/) which is stable and complete.


---

![http://media.lua-files.googlecode.com/hg/logos/fbclient_logo.png](http://media.lua-files.googlecode.com/hg/logos/fbclient_logo.png)

[v2.0](fbclient_status.md) | [code](http://code.google.com/p/lua-files/source/browse/fbclient.lua) | [header](http://code.google.com/p/lua-files/source/browse/fbclient_h.lua) | [test](https://code.google.com/p/lua-files/source/browse/fbclient_test.lua) | Firebird 2.5.2 | LuaJIT 2

## `local fb = require'fbclient'` ##

A complete ffi binding of the [Firebird](firebird_info.md) client library.<br>
Depends on <a href='glue.md'>glue</a> and <a href='http://www.inf.puc-rio.br/~roberto/struct/'>struct</a>.<br>
<br>
<h2>Features</h2>
<ul><li>full API coverage, including the <a href='fbclient_status.md'>latest Firebird API additions</a>
<ul><li>all data types supported with options for conversion<br>
</li><li>multi-database transactions with two-phase commit<br>
</li><li>blobs, both segmented blobs and blob streams<br>
</li><li>info API for info on databases, transactions, statements, blobs, etc.<br>
</li><li>error reporting API<br>
</li><li>service manager API for doing remote backup & restore, repair, user management, etc.<br>
</li></ul></li><li>all C calls are checked for errors and Lua errors are raised<br>
</li><li>binding to multiple client libraries in the same application/process<br>
</li><li>tested against all Firebird 2.0, 2.1 and 2.5 releases on 32bit Windows and Linux (test suite included).</li></ul>

<h2>Example</h2>

<pre><code>local fb = require 'fbclient'<br>
local conn = fb.connect('localhost:/my/db.fdb', 'SYSDBA', 'masterkey')<br>
local sql = 'select id, name from inventions where inventor = ? and name like ?'<br>
for st, id, name in conn:exec(sql, 'Farnsworth', '%booth') do<br>
   print(id, name)<br>
end<br>
conn:close()<br>
</code></pre>

<h2>API</h2>

<table><thead><th> <b>Connections</b> </th><th> </th><th> </th></thead><tbody>
<tr><td> <code>fb.connect(db, [user], [pass], [charset]) -&gt; conn</code> </td><td> connect to a database; db is a <a href='http://www.firebirdsql.org/manual/qsg2-databases.html#qsg2-databases-connstrings'>connection string</a> </td><td> <code>local conn = fb.connect('localhost:/foo.fdb', 'SYSDBA', 'masterkey', 'ASCII')</code> </td></tr>
<tr><td> <code>fb.connect(options_t) -&gt; conn</code> </td><td> connect to a database; named args version with extended options: role, client_library, <a href='http://lua-files.org/source/browse/fbclient_dpb.lua'>dpb</a> </td><td> <code>local conn = fb.connect{</code> <br> <code>db = 'localhost:/mydb.fdb',</code> <br> <code>dpb = {isc_dpb_sweep = true}</code> <br> <code>client_library = 'fbembed.dll'</code> <br> <code>}</code> </td></tr>
<tr><td> <code>conn:clone() -&gt; conn</code> </td><td> create a new connection with the exact same arguments those of a running connection. <br> connections resulted from <code>create_db</code> calls cannot be cloned. </td><td> </td></tr>
<tr><td> <code>conn:close()</code> </td><td> close a connection and any associated resources (open transactions are rolled back) </td><td> </td></tr>
<tr><td> <code>conn:exec_immediate(sql)</code> </td><td> execute a query that takes no arguments and returns no result set, in its own transaction </td><td> <code>conn:exec_immediate'drop table foo'</code> </td></tr>
<tr><td> <b>Databases</b>   </td><td> </td><td> </td></tr>
<tr><td> <code>fb.create_db(db, [user], [pass], [charset], [db_charset], [page_size]) -&gt; conn</code> </td><td> create a database and connect to it </td><td> <code>local conn = fb.create_db('localhost:/foo.fdb', 'SYSDBA', 'masterkey', 'UTF8', 'UTF8', 16384)</code> </td></tr>
<tr><td> <code>fb.create_db_sql(sql[, client_library]) -&gt; conn</code> </td><td> create a database using the <a href='http://www.ibphoenix.com/files/60sqlref.html#RSf21487'>SQL CREATE statement</a>, and connect to it </td><td> <code>local conn = fb.create_db_sql("create database 'foo.fdb' user 'SYSDBA' password 'masterkey' page_size = 8196")</code> </td></tr>
<tr><td> <code>conn:drop_db()</code> </td><td> disconnect and drop the database </td><td> </td></tr>
<tr><td> <code>conn:cancel_operation(option)</code> </td><td> cancel a running query; option = 'disable', 'enable', 'raise', 'abort' (not to be called from the main thread) </td><td> </td></tr>
<tr><td> <b>Transactions</b> </td><td> </td><td> </td></tr>
<tr><td> <code>conn:start_transaction([access], [isolation], [lock_timeout]) -&gt; tran</code> </td><td> start a transaction; <br>  - access = 'read', 'write' (default = 'write') <br>  - isolation = 'consistency', 'concurrency', 'read commited', 'read commited no record version' (default = 'concurrency') <br>  - lock_timeout = number of seconds to wait until reporting a conflicting update; nil/false means use server's default </td><td> <code>local tran = conn:start_transaction('write', 'consistency', 0)</code> </td></tr>
<tr><td> <code>conn:start_transaction(options_t) -&gt; tran</code> </td><td> start a transaction; named args version with extended options: <a href='http://lua-files.org/source/browse/fbclient_tpb.lua'>tpb</a> </td><td> <code>local tran = conn:start_trsanaction{isolation = 'read commited'}</code> </td></tr>
<tr><td> <code>fb.start_transaction({[conn] = options_t|true, ...} -&gt; tran</code> </td><td> start a multi-database transaction </td><td> <code>local tran = fb.start_transaction{[conn1] = true, [conn2] = {access = 'read'}}</code> </td></tr>
<tr><td> <code>conn:start_transaction_sql(sql) -&gt; tran</code> </td><td> start a transaction using the <a href='http://www.ibphoenix.com/files/60sqlref.html#RSf96788'>SET TRANSACTION statement</a> </td><td> <code>local tran = conn:start_transaction_sql'set transaction read'</code> </td></tr>
<tr><td> <code>tran:commit()</code> </td><td> commit and close a transaction </td><td> </td></tr>
<tr><td> <code>tran:rollback()</code> </td><td> rollback and close a transaction </td><td> </td></tr>
<tr><td> <code>tran:commit_retaining()</code> </td><td> commit a transaction and keep it open </td><td> </td></tr>
<tr><td> <code>tran:rollback_retaining()</code> </td><td> rollback a transaction and keep it open </td><td> </td></tr>
<tr><td> <code>conn:commit_all()</code> </td><td> commit all open transactions </td><td> </td></tr>
<tr><td> <code>conn:rollback_all()</code> </td><td> rollback all open transactions </td><td> </td></tr>
<tr><td> <code>tran:exec_immediate(sql[, conn])</code> </td><td> execute a query that takes no arguments and returns no result set </td><td> </td></tr>
<tr><td> <b>Prepared statements</b> </td><td> </td><td> </td></tr>
<tr><td> <code>tran:prepare(sql[, conn]) -&gt; stmt</code> </td><td> prepare a query for multiple executions and get field and param metadata </td><td> <code>local stmt = tran:prepare'select bar, baz from foo'</code> </td></tr>
<tr><td> <code>stmt:set_cursor_name(name)</code> </td><td> set cursor name for <code>UPDATE ... WHERE CURRENT OF &lt;cursor_name&gt;</code> queries </td><td> </td></tr>
<tr><td> <code>stmt:type() -&gt; s</code> </td><td> statement type ('select', 'insert', 'update', etc.) </td><td> </td></tr>
<tr><td> <code>stmt:run()</code> </td><td> execute a prepared statement </td><td> </td></tr>
<tr><td> <code>stmt:fetch() -&gt; true | false</code> </td><td> fetch the next row from the result set; returns false on eof </td><td> <code>while stmt:fetch() do</code> <br> <code>...</code> <br> <code>end</code> </td></tr>
<tr><td> <code>stmt:close()</code> </td><td> close a prepared statement </td><td> </td></tr>
<tr><td> <code>stmt:close_all_blobs()</code> </td><td> close all blob objects </td><td> </td></tr>
<tr><td> <code>stmt:close_cursor()</code> </td><td> close cursor </td><td> </td></tr>
<tr><td> <code>conn:close_all_statements()</code> </td><td> close all statements bound to a connection </td><td> </td></tr>
<tr><td> <code>tran:close_all_statements()</code> </td><td> close all statements bound to a transaction </td><td> </td></tr>
<tr><td> <b>Prepared statements I/O</b> </td><td> </td><td> </td></tr>
<tr><td> <code>stmt.fields[i] -&gt; field_t</code> </td><td> field by index </td><td> </td></tr>
<tr><td> <code>stmt.fields.&lt;name&gt; -&gt; field_t</code> </td><td> field by name </td><td> </td></tr>
<tr><td> <code>stmt.params[i] -&gt; field_t</code> </td><td> param by index </td><td> </td></tr>
<tr><td> <code>stmt.params.&lt;name&gt; -&gt; field_t</code> </td><td> param by name </td><td> </td></tr>
<tr><td> <code>field_t:get() -&gt; v</code> </td><td> get field/param value </td><td> <code>local acc_name = stmt.fields.account_name:get()</code> </td></tr>
<tr><td> <code>field_t:set(v)</code>     </td><td> set field/param value </td><td> <code>stmt.params.account_id:set(5)</code> </td></tr>
<tr><td> <b>Prepared statements I/O sugar</b> </td><td> </td><td> </td></tr>
<tr><td> <code>stmt:setparams(p1, ...) -&gt; stmt</code> </td><td> set param values </td><td> <code>stmt:setparams(5, 'foo', 'bar')</code> </td></tr>
<tr><td> <code>stmt:values() -&gt; v1, ...</code> </td><td> get field values </td><td> <code>local id, name, description = stmt:values()</code> </td></tr>
<tr><td> <code>stmt:values(f1, ...) -&gt; v1, ...</code> </td><td> get values of specific fields </td><td> <code>local name, description = stmt:values('name', 'description')</code> </td></tr>
<tr><td> <code>stmt:row() -&gt; {name1 = v1, ...}</code> </td><td> get row values </td><td> <code>local row = stmt:row()</code> <br> <code>print(row.account_id, row.account_name)</code> </td></tr>
<tr><td> <code>stmt:exec(p1, ...) -&gt; iter() -&gt; v1, ...</code> </td><td> set params, execute, and fetch values </td><td> </td></tr>
<tr><td> <code>tran:exec_on(conn, sql, p1, ...) -&gt; iter() -&gt; v1, ...</code> </td><td> set params, execute, and fetch values (for multi-database transactions) </td><td> </td></tr>
<tr><td> <code>tran:exec(sql, ...) -&gt; iter() -&gt; v1, ...</code> </td><td> make a statement, set params, execute, fetch values, close statement </td><td> </td></tr>
<tr><td> <code>conn:exec(sql, ...) -&gt; iter() -&gt; v1, ...</code> </td><td> make a transaction, make a statement, set params, execute, fetch values, close transaction </td><td> </td></tr>
<tr><td> <b>Field/param metadata</b> </td><td> </td><td> </td></tr>
<tr><td> <code>field_t.sqltype</code>  </td><td> C data type </td><td> </td></tr>
<tr><td> <code>field_t.sqlscale</code> </td><td> scale, for number types </td><td> </td></tr>
<tr><td> <code>field_t.sqllen</code>   </td><td> data type size </td><td> </td></tr>
<tr><td> <code>field_t.subtype</code>  </td><td> blob encoding </td><td> </td></tr>
<tr><td> <code>field_t.allow_null</code> </td><td> is NULL allowed on this field? </td><td> </td></tr>
<tr><td> <code>field_t.col_name</code> </td><td> underlying column name, if the field represents a table column, not an expression </td><td> </td></tr>
<tr><td> <code>field_t.table</code>    </td><td> table name </td><td> </td></tr>
<tr><td> <code>field_t.owner</code>    </td><td> table owner's name </td><td> </td></tr>
<tr><td> <code>field_t.name</code>     </td><td> column name </td><td> </td></tr>
<tr><td> <code>field_t.index</code>    </td><td> field position in the fields array </td><td> </td></tr></tbody></table>


<h2>Advanced use</h2>

<h3>Database Parameter Blocks</h3>

When connecting to a database, you can specify a Database Parameter Block (DPB), which gives you access to <a href='http://lua-files.org/source/browse/fbclient_dpb.lua'>more options</a>:<br>
<pre><code>conn = fb.connect{<br>
   db = 'localhost:/my/db.fdb', <br>
   user = 'SYSDBA',<br>
   pass = 'masterkey',<br>
   dpb = {<br>
      isc_dpb_sweep = true,<br>
   },<br>
}<br>
</code></pre>

Note that some DPB options are exclusively for creating databases, others are only for connecting to existing databases, and yet others work with both operations.<br>
<br>
<h3>Multi-database transactions</h3>

Firebird supports transactions that span over multiple databases, using the two-phase commit protocol to commit the changes. All connections involved in a multi-database transaction should run on the same OS thread. It's otherwise safe to run different connections on different threads, but never run the same connection on two threads.<br>
<br>
<h3>Commit and rollback retaining modes</h3>

The difference between commit and commit_retaining is that the first closes the transaction and destroys the transaction handle, while the later closes the transaction and starts a new one with the same parameters and the same transaction handle so you can continue executing queries against it. It also saves the cursor, so you don't have to re-fetch any data.<br>
<br>
<h3>Table reservation options</h3>

Table reservation options can be specified in the array part of the <code>tpb</code> table, one numerical index for each database table that you want to reserve. The format for reserving a table is:<br>
<br>
<blockquote><code>{table_reservation_mode_code, table_reservation_lock_code, table_name}</code></blockquote>

where the mode code is one of <code>'isc_tpb_shared', 'isc_tpb_protected', 'isc_tpb_exclusive'</code>, and the lock code is either <code>'isc_tpb_lock_read' or 'isc_tpb_lock_write'</code>.<br>
<br>
Example:<br>
<pre><code>  tpb = {<br>
    {'isc_tpb_shared','isc_tpb_lock_read','SOME_TABLE'},<br>
    {'isc_tpb_exclusive','isc_tpb_lock_write','SOME_OTHER_TABLE'},<br>
    ...<br>
  }<br>
</code></pre>

<h3>Prepared statements</h3>

Prepared statements are created with <code>tran:prepare()</code>.<br>
<br>
Parameters are created by placing the <code>?</code> sign in the places where parameter values should be in the query, and then setting the corresponding parameter values. This is a Firebird functionality, fbclient does no attempt to parse the SQL string.<br>
<br>
Parameters are initialized to <code>nil</code> and can be set either individually via <code>st.params[i]:set()</code>, or all at once with <code>st:setparams()</code>. The statement can then be executed with <code>st:run()</code>. Result rows can then be fetched one by one with <code>st:fetch()</code> and the row values can be read either individually via <code>st.columns[i|name]:get()</code>, or all at once with <code>st:values()</code> or <code>st:row()</code>. The statement can then be executed again with new parameters. Alternatively, you can use the more concise <code>st:exec()</code> which encapsulates all this workflow:<br>
<br>
<pre><code>st = tr:prepare('select id, name from inventions where inventor = ?')<br>
for _,inventor in ipairs{'Farnsworth', 'Wornstrom'} do<br>
  print('Inventions of Prof. '..inventor)<br>
  for _, id, name in st:exec(inventor) do<br>
    print(id, name)<br>
  end<br>
end<br>
</code></pre>

<h3>References between connections, transactions and statements</h3>

<table><thead><th> <code>conn.transactions -&gt; {[tran1] = true, ...}</code> </th><th> active transactions of a connection </th></thead><tbody>
<tr><td> <code>conn.statements -&gt; {[stmt1] = true, ...}</code>   </td><td> active statements of a connection   </td></tr>
<tr><td> <code>transaction.connections -&gt; {[conn1] = true, ...}</code> </td><td> connections that a transaction spans </td></tr>
<tr><td> <code>transaction.statements -&gt; {[stmt1] = true, ...}</code> </td><td> active statements of a transaction  </td></tr>
<tr><td> <code>statement.connections -&gt; conn</code>              </td><td> connection of a statement           </td></tr>
<tr><td> <code>statement.transaction -&gt; tran</code>              </td><td> transaction of a statement          </td></tr></tbody></table>

<h3>Reusing statements</h3>

If you only use Firebird 2.5+, you can reuse statements for future <code>tran:prepare()</code> calls. Just set <code>conn.statement_handle_pool_limit</code> to the maximum number of handles to be kept for reuse. Each attachment has its own pool of statement handles.<br>
<br>
<h3>Service Manager</h3>

See <a href='fbclient_service.md'>fbclient_service</a>.<br>
<br>
<h3>Caller objects</h3>

Caller objects are used to make direct calls to the client library and check for errors.<br>
<br>
<table><thead><th> <code>fb.caller([client_library]) -&gt; caller</code> </th><th> create a caller object </th></thead><tbody>
<tr><td> <code>caller.client_library -&gt; s</code>            </td><td> name of the client library used </td></tr>
<tr><td> <code>caller.C -&gt; clib</code>                      </td><td> ffi clib object        </td></tr>
<tr><td> <code>caller.pcall(func_name, arg1, ...) -&gt; true, ret | false, status_code</code> </td><td> low-level protected API call </td></tr>
<tr><td> <code>caller.call(func_name, arg1, ...) -&gt; ret</code> </td><td> low-level API call (raises errors) </td></tr>
<tr><td> <code>caller.status() -&gt; ok, status_code</code>    </td><td> status code of the last call, if it resulted in error </td></tr>
<tr><td> <code>caller.sqlcode() -&gt; n</code>                 </td><td> sql code number of the last call, if any (deprecated in favor of <code>sqlstate()</code>) </td></tr>
<tr><td> <code>caller.sqlstate() -&gt; s</code>                </td><td> SQL-2003 SQLSTATE 5-digit code, Firebird 2.5+ only </td></tr>
<tr><td> <code>caller.sqlerror(sqlcode) -&gt; s</code>         </td><td> sql error message for a specific sql code </td></tr>
<tr><td> <code>caller.errors() -&gt; errors_t</code>           </td><td> list of error messages from the last call, if any </td></tr>
<tr><td> <code>caller.ib_version() -&gt; major, minor</code>   </td><td> interbase API version  </td></tr>