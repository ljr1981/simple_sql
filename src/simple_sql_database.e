note
	description: "[
		High-level SQLite database API for simple, safe database operations.
		Simplifies the sqlite3 library for common use cases with automatic resource management.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_DATABASE

inherit
	DISPOSABLE

create
	make,
	make_memory,
	make_read_only

feature {NONE} -- Initialization

	make (a_file_name: READABLE_STRING_GENERAL)
			-- Create/open database file in read-write mode
		require
			file_name_not_empty: not a_file_name.is_empty
		do
			create internal_db.make_create_read_write (a_file_name)
			file_name := a_file_name.to_string_32
		ensure
			is_open: is_open
			file_name_set: file_name ~ a_file_name.to_string_32
		end

	make_memory
			-- Create in-memory database
		do
			create internal_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			internal_db.open_create_read_write
			create file_name.make_from_string (":memory:")
		ensure
			is_open: is_open
			in_memory: file_name ~ ":memory:"
		end

	make_read_only (a_file_name: READABLE_STRING_GENERAL)
			-- Open existing database file in read-only mode
		require
			file_name_not_empty: not a_file_name.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_file_name)).exists
		do
			create internal_db.make_open_read (a_file_name)
			file_name := a_file_name.to_string_32
		ensure
			is_open: is_open
			file_name_set: file_name ~ a_file_name.to_string_32
		end

feature -- Access

	file_name: STRING_32
			-- Database file name or ":memory:"

	last_error: detachable STRING_32
			-- Error message from last failed operation

	changes_count: INTEGER
			-- Number of rows modified by last operation
		require
			is_open: is_open
		do
			Result := internal_db.changes_count.to_integer_32
		end

	is_in_transaction: BOOLEAN
			-- Is database currently in a transaction?
		require
			is_open: is_open
		do
			Result := internal_db.is_in_transaction
		end

feature -- Status report

	is_open: BOOLEAN
			-- Is database connection open?
		do
			Result := not internal_db.is_closed
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := last_error /= Void
		ensure
			error_attached: Result implies last_error /= Void
		end

feature -- Basic operations

	execute (a_sql: READABLE_STRING_8)
			-- Execute SQL statement (INSERT, UPDATE, DELETE, CREATE, etc)
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_statement: SQLITE_MODIFY_STATEMENT
			l_sql: STRING_8
		do
			last_error := Void
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create l_statement.make (l_sql, internal_db)
			l_statement.execute
			if internal_db.has_error then
				if attached internal_db.last_exception as al_exception then
					if attached al_exception.description as al_desc then
						last_error := al_desc.to_string_32
					end
				end
			end
		rescue
			if attached internal_db.last_exception as al_exception then
				if attached al_exception.description as al_desc then
					last_error := al_desc.to_string_32
				end
			end
		end

	query (a_sql: READABLE_STRING_8): SIMPLE_SQL_RESULT
			-- Execute query and return results
		require
			is_open: is_open
			sql_not_empty: not a_sql.is_empty
		local
			l_sql: STRING_8
		do
			last_error := Void
			create l_sql.make_from_string (a_sql)
			if not l_sql.ends_with (";") then
				l_sql.append_character (';')
			end
			create Result.make (l_sql, internal_db)
			if internal_db.has_error then
				if attached internal_db.last_exception as al_exception then
					if attached al_exception.description as al_desc then
						last_error := al_desc.to_string_32
					end
				end
			end
		rescue
			if attached internal_db.last_exception as al_exception then
				if attached al_exception.description as al_desc then
					last_error := al_desc.to_string_32
				end
			end
			create Result.make_empty
		end

	begin_transaction
			-- Begin transaction (deferred mode)
		require
			is_open: is_open
		do
			last_error := Void
			internal_db.begin_transaction (True)
		end

	commit
			-- Commit current transaction
		require
			is_open: is_open
			is_in_transaction: internal_db.is_in_transaction
		do
			last_error := Void
			internal_db.commit
		end

	rollback
			-- Rollback current transaction
		require
			is_open: is_open
			is_in_transaction: internal_db.is_in_transaction
		do
			last_error := Void
			internal_db.rollback
		end

	close
			-- Close database connection
		do
			if not internal_db.is_closed then
				internal_db.close
			end
		ensure
			is_closed: not is_open
		end

feature -- Implementation

	internal_db: SQLITE_DATABASE
			-- Underlying sqlite3 database connection

	dispose
			-- <Precursor>
		do
			if not internal_db.is_closed then
				internal_db.close
			end
		end

invariant
	internal_db_attached: internal_db /= Void
	file_name_attached: file_name /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
