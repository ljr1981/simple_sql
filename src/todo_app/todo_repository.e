note
	description: "Repository for TODO_ITEM entities using SIMPLE_SQL_REPOSITORY"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_REPOSITORY

inherit
	SIMPLE_SQL_REPOSITORY [TODO_ITEM]

create
	make

feature -- Constants

	table_name: STRING_8 = "todos"
			-- <Precursor>

	primary_key_column: STRING_8 = "id"
			-- <Precursor>

feature -- Schema

	create_table
			-- Create the todos table if it doesn't exist.
		do
			database.execute ("[
				CREATE TABLE IF NOT EXISTS todos (
					id INTEGER PRIMARY KEY AUTOINCREMENT,
					title TEXT NOT NULL,
					description TEXT,
					priority INTEGER NOT NULL DEFAULT 3,
					is_completed INTEGER NOT NULL DEFAULT 0,
					due_date TEXT,
					created_at TEXT NOT NULL DEFAULT (datetime('now')),
					updated_at TEXT NOT NULL DEFAULT (datetime('now'))
				)
			]")
		ensure
			table_exists: database.schema.table_exists (table_name)
		end

	drop_table
			-- Drop the todos table if it exists.
		do
			database.execute ("DROP TABLE IF EXISTS todos")
		ensure
			table_gone: not database.schema.table_exists (table_name)
		end

feature -- Query: Custom

	find_incomplete: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos ordered by priority.
		do
			Result := find_where_ordered ("is_completed = 0", "priority ASC, due_date ASC")
		ensure
			result_attached: Result /= Void
			all_incomplete: across Result as ic all not ic.is_completed end
		end

	find_completed: ARRAYED_LIST [TODO_ITEM]
			-- Find all completed todos.
		do
			Result := find_where ("is_completed = 1")
		ensure
			result_attached: Result /= Void
			all_completed: across Result as ic all ic.is_completed end
		end

	find_by_priority (a_priority: INTEGER): ARRAYED_LIST [TODO_ITEM]
			-- Find all todos with given priority.
		require
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			Result := find_where ("priority = " + a_priority.out)
		ensure
			result_attached: Result /= Void
			all_have_priority: across Result as ic all ic.priority = a_priority end
		end

	find_overdue: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos past their due date.
		do
			Result := find_where ("is_completed = 0 AND due_date < date('now') AND due_date IS NOT NULL")
		ensure
			result_attached: Result /= Void
		end

	find_due_today: ARRAYED_LIST [TODO_ITEM]
			-- Find all incomplete todos due today.
		do
			Result := find_where ("is_completed = 0 AND due_date = date('now')")
		ensure
			result_attached: Result /= Void
		end

feature -- Command: Custom

	mark_completed (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as completed.
		require
			valid_id: a_id > 0
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
		do
			create l_columns.make (2)
			l_columns.put (1, "is_completed")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

	mark_incomplete (a_id: INTEGER_64): BOOLEAN
			-- Mark a todo as incomplete.
		require
			valid_id: a_id > 0
		local
			l_columns: HASH_TABLE [detachable ANY, STRING_8]
		do
			create l_columns.make (2)
			l_columns.put (0, "is_completed")
			l_columns.put ("datetime('now')", "updated_at")
			Result := update_where (l_columns, "id = " + a_id.out) = 1
		end

	delete_completed: INTEGER
			-- Delete all completed todos.
		do
			Result := delete_where ("is_completed = 1")
		ensure
			non_negative: Result >= 0
		end

feature -- Statistics

	incomplete_count: INTEGER
			-- Number of incomplete todos.
		do
			Result := count_where ("is_completed = 0")
		ensure
			non_negative: Result >= 0
		end

	completed_count: INTEGER
			-- Number of completed todos.
		do
			Result := count_where ("is_completed = 1")
		ensure
			non_negative: Result >= 0
		end

	overdue_count: INTEGER
			-- Number of overdue incomplete todos.
		do
			Result := count_where ("is_completed = 0 AND due_date < date('now') AND due_date IS NOT NULL")
		ensure
			non_negative: Result >= 0
		end

feature {NONE} -- Implementation

	row_to_entity (a_row: SIMPLE_SQL_ROW): TODO_ITEM
			-- <Precursor>
		local
			l_id: INTEGER_64
			l_title: STRING_8
			l_description: detachable STRING_8
			l_priority: INTEGER
			l_is_completed: BOOLEAN
			l_due_date: detachable STRING_8
			l_created_at, l_updated_at: STRING_8
		do
			l_id := a_row.integer_64_value ("id")
			l_title := a_row.string_value ("title").to_string_8

			if not a_row.is_null ("description") then
				l_description := a_row.string_value ("description").to_string_8
			end

			l_priority := a_row.integer_value ("priority")
			l_is_completed := a_row.integer_value ("is_completed") = 1

			if not a_row.is_null ("due_date") then
				l_due_date := a_row.string_value ("due_date").to_string_8
			end

			l_created_at := a_row.string_value ("created_at").to_string_8
			l_updated_at := a_row.string_value ("updated_at").to_string_8

			create Result.make (l_id, l_title, l_description, l_priority, l_is_completed,
				l_due_date, l_created_at, l_updated_at)
		end

	entity_to_columns (a_entity: TODO_ITEM): HASH_TABLE [detachable ANY, STRING_8]
			-- <Precursor>
		do
			create Result.make (6)
			Result.put (a_entity.title, "title")
			Result.put (a_entity.description, "description")
			Result.put (a_entity.priority, "priority")
			if a_entity.is_completed then
				Result.put (1, "is_completed")
			else
				Result.put (0, "is_completed")
			end
			Result.put (a_entity.due_date, "due_date")
			-- Note: created_at and updated_at are handled by database defaults
		end

	entity_id (a_entity: TODO_ITEM): INTEGER_64
			-- <Precursor>
		do
			Result := a_entity.id
		end

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
