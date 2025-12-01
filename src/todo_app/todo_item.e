note
	description: "A todo item entity for the todo_app consumer example"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TODO_ITEM

inherit
	ANY
		redefine
			out
		end

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_title: READABLE_STRING_8; a_description: detachable READABLE_STRING_8;
			a_priority: INTEGER; a_is_completed: BOOLEAN; a_due_date: detachable READABLE_STRING_8;
			a_created_at: READABLE_STRING_8; a_updated_at: READABLE_STRING_8)
			-- Initialize from database row.
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
			created_at_not_empty: not a_created_at.is_empty
			updated_at_not_empty: not a_updated_at.is_empty
		do
			id := a_id
			title := a_title.twin
			if attached a_description as desc then
				description := desc.twin
			end
			priority := a_priority
			is_completed := a_is_completed
			if attached a_due_date as dd then
				due_date := dd.twin
			end
			created_at := a_created_at.twin
			updated_at := a_updated_at.twin
		ensure
			id_set: id = a_id
			title_set: title.same_string (a_title)
			priority_set: priority = a_priority
			is_completed_set: is_completed = a_is_completed
		end

	make_new (a_title: READABLE_STRING_8; a_priority: INTEGER)
			-- Create a new todo item (not yet saved to database).
		require
			title_not_empty: not a_title.is_empty
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			id := 0
			title := a_title.twin
			priority := a_priority
			is_completed := False
			created_at := ""
			updated_at := ""
		ensure
			id_zero: id = 0
			title_set: title.same_string (a_title)
			priority_set: priority = a_priority
			not_completed: not is_completed
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	title: STRING_8
			-- Task title (required).

	description: detachable STRING_8
			-- Optional detailed description.

	priority: INTEGER
			-- Priority level (1=highest, 5=lowest).

	is_completed: BOOLEAN
			-- Has the task been completed?

	due_date: detachable STRING_8
			-- Optional due date (ISO 8601 format: YYYY-MM-DD).

	created_at: STRING_8
			-- Timestamp when created (ISO 8601).

	updated_at: STRING_8
			-- Timestamp when last updated (ISO 8601).

feature -- Status

	is_new: BOOLEAN
			-- Has this item not yet been saved to database?
		do
			Result := id = 0
		end

	is_overdue: BOOLEAN
			-- Is the item past its due date and not completed?
			-- Note: Simple string comparison works for ISO 8601 dates.
		do
			if attached due_date as dd and then not is_completed then
				-- Would need current date comparison in real app
				Result := False -- Placeholder
			end
		end

feature -- Modification

	set_title (a_title: READABLE_STRING_8)
			-- Update the title.
		require
			title_not_empty: not a_title.is_empty
		do
			title := a_title.twin
		ensure
			title_set: title.same_string (a_title)
		end

	set_description (a_description: detachable READABLE_STRING_8)
			-- Update the description.
		do
			if attached a_description as desc then
				description := desc.twin
			else
				description := Void
			end
		ensure
			description_set: attached a_description as d implies attached description as dd and then dd.same_string (d)
			description_void: a_description = Void implies description = Void
		end

	set_priority (a_priority: INTEGER)
			-- Update the priority.
		require
			valid_priority: a_priority >= 1 and a_priority <= 5
		do
			priority := a_priority
		ensure
			priority_set: priority = a_priority
		end

	set_due_date (a_due_date: detachable READABLE_STRING_8)
			-- Update the due date.
		do
			if attached a_due_date as dd then
				due_date := dd.twin
			else
				due_date := Void
			end
		end

	mark_completed
			-- Mark the item as completed.
		do
			is_completed := True
		ensure
			completed: is_completed
		end

	mark_incomplete
			-- Mark the item as not completed.
		do
			is_completed := False
		ensure
			not_completed: not is_completed
		end

	set_id (a_id: INTEGER_64)
			-- Set the ID (called after insert).
		require
			was_new: id = 0
			valid_id: a_id > 0
		do
			id := a_id
		ensure
			id_set: id = a_id
		end

	set_timestamps (a_created: READABLE_STRING_8; a_updated: READABLE_STRING_8)
			-- Set timestamps (called after insert/update).
		require
			created_not_empty: not a_created.is_empty
			updated_not_empty: not a_updated.is_empty
		do
			created_at := a_created.to_string_8
			updated_at := a_updated.to_string_8
		ensure
			created_set: created_at.same_string (a_created)
			updated_set: updated_at.same_string (a_updated)
		end

feature -- Output

	out: STRING_8
			-- String representation.
		do
			create Result.make (100)
			Result.append ("[")
			if is_completed then
				Result.append ("X")
			else
				Result.append (" ")
			end
			Result.append ("] ")
			Result.append ("(P")
			Result.append_integer (priority)
			Result.append (") ")
			Result.append (title)
			if attached due_date as dd then
				Result.append (" [Due: ")
				Result.append (dd)
				Result.append ("]")
			end
		end

invariant
	title_not_empty: not title.is_empty
	valid_priority: priority >= 1 and priority <= 5
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
