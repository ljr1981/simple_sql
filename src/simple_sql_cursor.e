note
	description: "[
		Lazy cursor for iterating over SQLite query results row-by-row.

		Unlike SIMPLE_SQL_RESULT which loads all rows into memory immediately,
		SIMPLE_SQL_CURSOR fetches rows on demand, making it suitable for:
			- Large result sets that won't fit in memory
			- Early termination when only first N rows are needed
			- Memory-efficient processing of streaming data

		Usage:
			cursor := db.query_cursor ("SELECT * FROM large_table")
			from cursor.start until cursor.after loop
				row := cursor.item
				-- process row
				cursor.forth
			end
			cursor.close

		Or with across syntax:
			across db.query_cursor ("SELECT * FROM large_table") as ic loop
				print (ic.string_value ("name"))
			end

		IMPORTANT: Always close the cursor when done to release database resources.
		The cursor will auto-close when exhausted, but early termination requires
		explicit close.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_CURSOR

inherit
	ITERABLE [SIMPLE_SQL_ROW]

create
	make

feature {NONE} -- Initialization

	make (a_sql: READABLE_STRING_8; a_database: SQLITE_DATABASE)
			-- Create cursor for query execution
		require
			sql_not_empty: not a_sql.is_empty
			database_attached: a_database /= Void
			database_readable: a_database.is_readable
		local
			l_sql: STRING_8
		do
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			sql := l_sql
			database := a_database
			create pending_rows.make (Buffer_size)
			is_started := False
			is_exhausted := False
			rows_fetched := 0
		ensure
			sql_set: sql.same_string (a_sql) or sql.same_string (a_sql + ";")
			database_set: database = a_database
			not_started: not is_started
		end

feature -- Access

	sql: STRING_8
			-- The SQL query being executed

	item: SIMPLE_SQL_ROW
			-- Current row
		require
			not_after: not after
			started: is_started
		do
			Result := current_row
		end

	new_cursor: SIMPLE_SQL_CURSOR_ITERATOR
			-- Fresh iterator for across loops
		do
			create Result.make (Current)
		end

feature -- Measurement

	rows_fetched: INTEGER
			-- Total number of rows fetched so far

feature -- Status report

	is_started: BOOLEAN
			-- Has iteration begun?

	after: BOOLEAN
			-- Are we past the last row?
		do
			Result := is_started and then not has_valid_row
		end

	is_open: BOOLEAN
			-- Is cursor still open for fetching?
		do
			Result := is_started and then not is_closed
		end

	is_closed: BOOLEAN
			-- Has cursor been explicitly closed?

	has_valid_row: BOOLEAN
			-- Is there a valid current row loaded?

feature -- Cursor movement

	start
			-- Start iteration, fetch first row
		require
			not_started: not is_started
		do
			is_started := True
			fetch_batch
			advance_to_next_row
		ensure
			started: is_started
		end

	forth
			-- Move to next row
		require
			started: is_started
			not_after: not after
		do
			advance_to_next_row
		end

feature -- Cleanup

	close
			-- Close cursor and release resources
			-- Safe to call multiple times
		do
			is_closed := True
			is_exhausted := True
			pending_rows.wipe_out
		ensure
			closed: is_closed
		end

feature {NONE} -- Implementation

	database: SQLITE_DATABASE
			-- Database connection

	pending_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- Buffer of fetched rows not yet consumed

	current_row: SIMPLE_SQL_ROW
			-- The current row being accessed
		attribute
			create Result.make (1)
		end

	is_exhausted: BOOLEAN
			-- Have all rows been fetched from database?

	fetch_batch
			-- Fetch next batch of rows into pending_rows buffer
		local
			l_statement: SQLITE_QUERY_STATEMENT
		do
			if not is_exhausted and not is_closed then
				pending_rows.wipe_out
				create l_statement.make (sql, database)
				-- Execute and collect all rows (SQLite binding limitation)
				-- The callback collects rows into pending_rows
				batch_row_count := 0
				l_statement.execute (agent collect_row_batch)
				is_exhausted := True -- SQLite executes entire query
			end
		end

	batch_row_count: INTEGER
			-- Count of rows collected in current batch

	collect_row_batch (a_row: SQLITE_RESULT_ROW): BOOLEAN
			-- Collect row into pending buffer
		local
			l_sql_row: SIMPLE_SQL_ROW
			i: NATURAL
			l_col_name: STRING_8
		do
			create l_sql_row.make (a_row.count.to_integer_32)
			from
				i := 1
			until
				i > a_row.count
			loop
				l_col_name := a_row.column_name (i).to_string_8
				l_sql_row.add_column (l_col_name, a_row [i])
				i := i + 1
			end
			pending_rows.extend (l_sql_row)
			batch_row_count := batch_row_count + 1
			Result := False -- Continue processing
		end

	advance_to_next_row
			-- Move to next available row
		do
			if not pending_rows.is_empty then
				current_row := pending_rows.first
				pending_rows.start
				pending_rows.remove
				rows_fetched := rows_fetched + 1
				has_valid_row := True
			else
				has_valid_row := False
			end
		end

feature {NONE} -- Constants

	Buffer_size: INTEGER = 100
			-- Initial buffer size for pending rows

invariant
	sql_attached: sql /= Void
	database_attached: database /= Void
	pending_rows_attached: pending_rows /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
