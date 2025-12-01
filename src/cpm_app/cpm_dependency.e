note
	description: "A dependency relationship between two CPM activities (predecessor -> successor)"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CPM_DEPENDENCY

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_predecessor_id, a_successor_id: INTEGER_64;
			a_dependency_type: READABLE_STRING_8; a_lag: INTEGER)
			-- Initialize from database row.
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			valid_type: is_valid_dependency_type (a_dependency_type)
		do
			id := a_id
			predecessor_id := a_predecessor_id
			successor_id := a_successor_id
			dependency_type := a_dependency_type.to_string_8
			lag := a_lag
		ensure
			id_set: id = a_id
			predecessor_id_set: predecessor_id = a_predecessor_id
			successor_id_set: successor_id = a_successor_id
			dependency_type_set: dependency_type.same_string (a_dependency_type)
			lag_set: lag = a_lag
		end

	make_new (a_predecessor_id, a_successor_id: INTEGER_64)
			-- Create a new Finish-to-Start dependency with zero lag.
		require
			valid_predecessor: a_predecessor_id > 0
			valid_successor: a_successor_id > 0
			different_activities: a_predecessor_id /= a_successor_id
		do
			id := 0
			predecessor_id := a_predecessor_id
			successor_id := a_successor_id
			dependency_type := "FS"
			lag := 0
		ensure
			id_zero: id = 0
			predecessor_id_set: predecessor_id = a_predecessor_id
			successor_id_set: successor_id = a_successor_id
			finish_to_start: dependency_type.same_string ("FS")
			zero_lag: lag = 0
		end

feature -- Access

	id: INTEGER_64
			-- Unique identifier (0 if not yet saved).

	predecessor_id: INTEGER_64
			-- ID of the predecessor activity.

	successor_id: INTEGER_64
			-- ID of the successor activity.

	dependency_type: STRING_8
			-- Type of dependency:
			-- "FS" = Finish-to-Start (most common)
			-- "SS" = Start-to-Start
			-- "FF" = Finish-to-Finish
			-- "SF" = Start-to-Finish (rare)

	lag: INTEGER
			-- Lag time in days (can be negative for lead time).

feature -- Status

	is_new: BOOLEAN
			-- Has this item not yet been saved to database?
		do
			Result := id = 0
		end

	is_finish_to_start: BOOLEAN
			-- Is this a Finish-to-Start dependency?
		do
			Result := dependency_type.same_string ("FS")
		end

	is_start_to_start: BOOLEAN
			-- Is this a Start-to-Start dependency?
		do
			Result := dependency_type.same_string ("SS")
		end

	is_finish_to_finish: BOOLEAN
			-- Is this a Finish-to-Finish dependency?
		do
			Result := dependency_type.same_string ("FF")
		end

	is_start_to_finish: BOOLEAN
			-- Is this a Start-to-Finish dependency?
		do
			Result := dependency_type.same_string ("SF")
		end

feature -- Modification

	set_dependency_type (a_type: READABLE_STRING_8)
			-- Set dependency type.
		require
			valid_type: is_valid_dependency_type (a_type)
		do
			dependency_type := a_type.to_string_8
		ensure
			type_set: dependency_type.same_string (a_type)
		end

	set_lag (a_lag: INTEGER)
			-- Set lag time.
		do
			lag := a_lag
		ensure
			lag_set: lag = a_lag
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

feature -- Validation

	is_valid_dependency_type (a_type: READABLE_STRING_8): BOOLEAN
			-- Is `a_type` a valid dependency type?
		do
			Result := a_type.same_string ("FS") or else
				a_type.same_string ("SS") or else
				a_type.same_string ("FF") or else
				a_type.same_string ("SF")
		end

invariant
	valid_predecessor: predecessor_id > 0
	valid_successor: successor_id > 0
	different_activities: predecessor_id /= successor_id
	valid_dependency_type: is_valid_dependency_type (dependency_type)
	id_non_negative: id >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
