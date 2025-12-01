note
	description: "WMS Warehouse - Physical warehouse/distribution center"

class
	WMS_WAREHOUSE

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_code, a_name, a_address: READABLE_STRING_8;
			a_is_active: BOOLEAN; a_created_at: READABLE_STRING_8)
		do
			id := a_id
			code := a_code.to_string_8
			name := a_name.to_string_8
			address := a_address.to_string_8
			is_active := a_is_active
			created_at := a_created_at.to_string_8
		end

	make_new (a_code, a_name: READABLE_STRING_8)
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
		do
			code := a_code.to_string_8
			name := a_name.to_string_8
			address := ""
			is_active := True
			created_at := ""
		ensure
			is_new: is_new
			active_by_default: is_active
		end

feature -- Access

	id: INTEGER_64

	code: STRING_8
			-- Short warehouse code (e.g., "WH-001", "EAST")

	name: STRING_8

	address: STRING_8

	is_active: BOOLEAN

	created_at: STRING_8

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: is_new
			valid_id: a_id > 0
		do
			id := a_id
		end

	set_address (a_address: READABLE_STRING_8)
		do
			address := a_address.to_string_8
		end

	deactivate
		do
			is_active := False
		end

	activate
		do
			is_active := True
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

invariant
	code_not_empty: not code.is_empty
	name_not_empty: not name.is_empty

end
