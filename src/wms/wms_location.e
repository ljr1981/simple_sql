note
	description: "WMS Location - Bin/shelf location within a warehouse"

class
	WMS_LOCATION

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_warehouse_id: INTEGER_64; a_code, a_aisle, a_rack, a_shelf, a_bin: READABLE_STRING_8;
			a_is_active: BOOLEAN)
		do
			id := a_id
			warehouse_id := a_warehouse_id
			code := a_code.to_string_8
			aisle := a_aisle.to_string_8
			rack := a_rack.to_string_8
			shelf := a_shelf.to_string_8
			bin := a_bin.to_string_8
			is_active := a_is_active
		end

	make_new (a_warehouse_id: INTEGER_64; a_aisle, a_rack, a_shelf, a_bin: READABLE_STRING_8)
		require
			valid_warehouse: a_warehouse_id > 0
		do
			warehouse_id := a_warehouse_id
			aisle := a_aisle.to_string_8
			rack := a_rack.to_string_8
			shelf := a_shelf.to_string_8
			bin := a_bin.to_string_8
			code := a_aisle.to_string_8 + "-" + a_rack.to_string_8 + "-" + a_shelf.to_string_8 + "-" + a_bin.to_string_8
			is_active := True
		ensure
			is_new: is_new
			active_by_default: is_active
		end

feature -- Access

	id: INTEGER_64

	warehouse_id: INTEGER_64

	code: STRING_8
			-- Full location code (e.g., "A-01-03-B")

	aisle: STRING_8

	rack: STRING_8

	shelf: STRING_8

	bin: STRING_8

	is_active: BOOLEAN

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

	deactivate
		do
			is_active := False
		end

	activate
		do
			is_active := True
		end

invariant
	code_not_empty: not code.is_empty
	valid_warehouse: warehouse_id >= 0

end
