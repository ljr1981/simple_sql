note
	description: "[
		Iterator for SIMPLE_SQL_CURSOR to support across loops.

		This class provides the ITERATION_CURSOR interface required by
		Eiffel's across syntax, delegating to the parent SIMPLE_SQL_CURSOR.

		Usage:
			across db.query_cursor ("SELECT * FROM users") as ic loop
				print (ic.string_value ("name"))
			end
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_CURSOR_ITERATOR

inherit
	ITERATION_CURSOR [SIMPLE_SQL_ROW]

create
	make

feature {NONE} -- Initialization

	make (a_cursor: SIMPLE_SQL_CURSOR)
			-- Initialize iterator with cursor
		require
			cursor_attached: a_cursor /= Void
		do
			cursor := a_cursor
			if not cursor.is_started then
				cursor.start
			end
		ensure
			cursor_set: cursor = a_cursor
			cursor_started: cursor.is_started
		end

feature -- Access

	item: SIMPLE_SQL_ROW
			-- Current row
		do
			Result := cursor.item
		end

feature -- Convenience access (delegate to current row)

	string_value (a_name: STRING_8): STRING_32
			-- String value for column in current row
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.string_value (a_name)
		end

	integer_value (a_name: STRING_8): INTEGER
			-- Integer value for column in current row
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.integer_value (a_name)
		end

	integer_64_value (a_name: STRING_8): INTEGER_64
			-- Integer_64 value for column in current row
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.integer_64_value (a_name)
		end

	real_value (a_name: STRING_8): REAL_64
			-- Real value for column in current row
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.real_value (a_name)
		end

	is_null (a_name: STRING_8): BOOLEAN
			-- Is column null in current row?
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.is_null (a_name)
		end

	column_value (a_name: STRING_8): detachable ANY
			-- Raw value for column in current row
		require
			not_after: not after
			has_column: item.has_column (a_name)
		do
			Result := item.column_value (a_name)
		end

feature -- Status report

	after: BOOLEAN
			-- Is cursor past the last row?
		do
			Result := cursor.after
		end

feature -- Cursor movement

	forth
			-- Move to next row
		do
			cursor.forth
		end

feature {NONE} -- Implementation

	cursor: SIMPLE_SQL_CURSOR
			-- The underlying cursor

invariant
	cursor_attached: cursor /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
	]"

end
