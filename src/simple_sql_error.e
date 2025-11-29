note
	description: "[
		Structured error information from SQLite operations.
		Captures error code, message, SQL statement, and context.

		Usage:
			if db.has_error then
				print (db.last_error.full_description)
			end
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_ERROR

create
	make,
	make_with_sql

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Create error with code and message
		require
			message_not_void: a_message /= Void
		do
			code := a_code
			extended_code := a_code
			create message.make_from_string_general (a_message)
			create sql.make_empty
		ensure
			code_set: code = a_code
			extended_code_set: extended_code = a_code
			message_set: message.same_string_general (a_message)
			sql_empty: sql.is_empty
		end

	make_with_sql (a_code: INTEGER; a_message: READABLE_STRING_GENERAL; a_sql: READABLE_STRING_GENERAL)
			-- Create error with code, message, and originating SQL
		require
			message_not_void: a_message /= Void
			sql_not_void: a_sql /= Void
		do
			code := a_code
			extended_code := a_code
			create message.make_from_string_general (a_message)
			create sql.make_from_string_general (a_sql)
		ensure
			code_set: code = a_code
			extended_code_set: extended_code = a_code
			message_set: message.same_string_general (a_message)
			sql_set: sql.same_string_general (a_sql)
		end

feature -- Access

	code: INTEGER
			-- Primary SQLite result code (lower 8 bits of extended_code)

	extended_code: INTEGER
			-- Full extended result code from SQLite

	message: STRING_32
			-- Error message from SQLite

	sql: STRING_32
			-- SQL statement that caused the error (may be empty)

feature -- Derived Access

	code_name: STRING_8
			-- Human-readable name for the error code
		do
			Result := error_codes.name (code)
		ensure
			result_not_empty: not Result.is_empty
		end

	extended_code_name: STRING_8
			-- Human-readable name for the extended error code
		do
			Result := error_codes.name (extended_code)
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Status

	is_constraint_violation: BOOLEAN
			-- Is this a constraint violation error?
		do
			Result := code = error_codes.constraint
		end

	is_busy: BOOLEAN
			-- Is this a database busy/locked error?
		do
			Result := code = error_codes.busy or code = error_codes.locked
		end

	is_readonly: BOOLEAN
			-- Is this a readonly database error?
		do
			Result := code = error_codes.readonly
		end

	is_io_error: BOOLEAN
			-- Is this an I/O error?
		do
			Result := code = error_codes.ioerr
		end

	is_corrupt: BOOLEAN
			-- Is this a database corruption error?
		do
			Result := code = error_codes.corrupt
		end

	is_permission_error: BOOLEAN
			-- Is this a permission denied error?
		do
			Result := code = error_codes.perm or code = error_codes.auth
		end

feature -- Specific Constraint Violations

	is_unique_violation: BOOLEAN
			-- Is this a UNIQUE constraint violation?
		do
			Result := extended_code = error_codes.constraint_unique
		end

	is_primary_key_violation: BOOLEAN
			-- Is this a PRIMARY KEY constraint violation?
		do
			Result := extended_code = error_codes.constraint_primarykey
		end

	is_foreign_key_violation: BOOLEAN
			-- Is this a FOREIGN KEY constraint violation?
		do
			Result := extended_code = error_codes.constraint_foreignkey
		end

	is_not_null_violation: BOOLEAN
			-- Is this a NOT NULL constraint violation?
		do
			Result := extended_code = error_codes.constraint_notnull
		end

	is_check_violation: BOOLEAN
			-- Is this a CHECK constraint violation?
		do
			Result := extended_code = error_codes.constraint_check
		end

feature -- Output

	description: STRING_32
			-- Brief error description
		do
			create Result.make (code_name.count + message.count + 10)
			Result.append_string_general (code_name)
			Result.append_string_general (": ")
			Result.append (message)
		ensure
			result_not_empty: not Result.is_empty
		end

	full_description: STRING_32
			-- Full error description including SQL if available
		do
			create Result.make (100)
			Result.append_string_general ("Error: ")
			Result.append_string_general (code_name)
			if extended_code /= code then
				Result.append_string_general (" (")
				Result.append_string_general (extended_code_name)
				Result.append_string_general (")")
			end
			Result.append_string_general ("%NMessage: ")
			Result.append (message)
			if not sql.is_empty then
				Result.append_string_general ("%NSQL: ")
				Result.append (sql)
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	error_codes: SIMPLE_SQL_ERROR_CODE
			-- Error code constants
		once
			create Result
		end

feature -- Element Change

	set_extended_code (a_extended_code: INTEGER)
			-- Set extended code and update primary code
		do
			extended_code := a_extended_code
			code := error_codes.primary_code (a_extended_code)
		ensure
			extended_code_set: extended_code = a_extended_code
			code_derived: code = error_codes.primary_code (a_extended_code)
		end

invariant
	message_attached: message /= Void
	sql_attached: sql /= Void
	code_is_primary: code = error_codes.primary_code (extended_code)

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
