note
	description: "[
		WMS Movement - Stock transaction record (audit trail).

		Movement types:
		- RECEIVE: Stock received from supplier (no from_location)
		- SHIP: Stock shipped to customer (no to_location)
		- TRANSFER: Internal move between locations
		- ADJUST: Inventory adjustment (count variance)
		- PICK: Reserved stock picked for order
		- RETURN: Customer return

		FRICTION POINT: Recording a movement AND updating stock must be atomic.
		Currently requires manual transaction handling:
		  db.begin_transaction
		  db.execute_with_args (insert movement)
		  db.execute_with_args (update stock with version check)
		  if rows = 0 then db.rollback else db.commit end

		DESIRED API:
		db.atomic (agent do_receive_stock (product, location, qty, reference))
		  -- With automatic retry on optimistic lock failure
	]"

class
	WMS_MOVEMENT

create
	make,
	make_receive,
	make_ship,
	make_transfer,
	make_adjust,
	make_pick

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_product_id: INTEGER_64;
			a_from_location, a_to_location: INTEGER_64;
			a_quantity: INTEGER; a_type, a_reference: READABLE_STRING_8;
			a_performed_by: INTEGER_64; a_created_at: READABLE_STRING_8)
		do
			id := a_id
			product_id := a_product_id
			from_location_id := a_from_location
			to_location_id := a_to_location
			quantity := a_quantity
			movement_type := a_type.to_string_8
			movement_reference := a_reference.to_string_8
			performed_by := a_performed_by
			created_at := a_created_at.to_string_8
		end

	make_receive (a_product_id, a_to_location: INTEGER_64; a_quantity: INTEGER;
			a_reference: READABLE_STRING_8; a_user: INTEGER_64)
		require
			valid_product: a_product_id > 0
			valid_location: a_to_location > 0
			positive_qty: a_quantity > 0
		do
			id := 0
			product_id := a_product_id
			from_location_id := 0
			to_location_id := a_to_location
			quantity := a_quantity
			movement_type := Type_receive
			movement_reference := a_reference.to_string_8
			performed_by := a_user
			created_at := ""
		ensure
			is_receive: is_receive
		end

	make_ship (a_product_id, a_from_location: INTEGER_64; a_quantity: INTEGER;
			a_reference: READABLE_STRING_8; a_user: INTEGER_64)
		require
			valid_product: a_product_id > 0
			valid_location: a_from_location > 0
			positive_qty: a_quantity > 0
		do
			id := 0
			product_id := a_product_id
			from_location_id := a_from_location
			to_location_id := 0
			quantity := a_quantity
			movement_type := Type_ship
			movement_reference := a_reference.to_string_8
			performed_by := a_user
			created_at := ""
		ensure
			is_ship: is_ship
		end

	make_transfer (a_product_id, a_from_location, a_to_location: INTEGER_64;
			a_quantity: INTEGER; a_reference: READABLE_STRING_8; a_user: INTEGER_64)
		require
			valid_product: a_product_id > 0
			valid_from: a_from_location > 0
			valid_to: a_to_location > 0
			different_locations: a_from_location /= a_to_location
			positive_qty: a_quantity > 0
		do
			id := 0
			product_id := a_product_id
			from_location_id := a_from_location
			to_location_id := a_to_location
			quantity := a_quantity
			movement_type := Type_transfer
			movement_reference := a_reference.to_string_8
			performed_by := a_user
			created_at := ""
		ensure
			is_transfer: is_transfer
		end

	make_adjust (a_product_id, a_location: INTEGER_64; a_quantity: INTEGER;
			a_reference: READABLE_STRING_8; a_user: INTEGER_64)
		require
			valid_product: a_product_id > 0
			valid_location: a_location > 0
		do
			id := 0
			product_id := a_product_id
			from_location_id := 0
			to_location_id := 0
			if a_quantity >= 0 then
				to_location_id := a_location
			else
				from_location_id := a_location
			end
			quantity := a_quantity.abs
			movement_type := Type_adjust
			movement_reference := a_reference.to_string_8
			performed_by := a_user
			created_at := ""
		end

	make_pick (a_product_id, a_from_location: INTEGER_64; a_quantity: INTEGER;
			a_order_reference: READABLE_STRING_8; a_user: INTEGER_64)
		require
			valid_product: a_product_id > 0
			valid_location: a_from_location > 0
			positive_qty: a_quantity > 0
		do
			id := 0
			product_id := a_product_id
			from_location_id := a_from_location
			to_location_id := 0
			quantity := a_quantity
			movement_type := Type_pick
			movement_reference := a_order_reference.to_string_8
			performed_by := a_user
			created_at := ""
		ensure
			is_pick: is_pick
		end

feature -- Access

	id: INTEGER_64

	product_id: INTEGER_64

	from_location_id: INTEGER_64
			-- Source location (0 for receives).

	to_location_id: INTEGER_64
			-- Destination location (0 for ships/picks).

	quantity: INTEGER
			-- Always positive; direction determined by type.

	movement_type: STRING_8

	movement_reference: STRING_8
			-- PO number, order number, count ID, etc.

	performed_by: INTEGER_64

	created_at: STRING_8

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	is_receive: BOOLEAN
		do
			Result := movement_type.same_string (Type_receive)
		end

	is_ship: BOOLEAN
		do
			Result := movement_type.same_string (Type_ship)
		end

	is_transfer: BOOLEAN
		do
			Result := movement_type.same_string (Type_transfer)
		end

	is_adjust: BOOLEAN
		do
			Result := movement_type.same_string (Type_adjust)
		end

	is_pick: BOOLEAN
		do
			Result := movement_type.same_string (Type_pick)
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: is_new
		do
			id := a_id
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

feature -- Constants

	Type_receive: STRING_8 = "RECEIVE"
	Type_ship: STRING_8 = "SHIP"
	Type_transfer: STRING_8 = "TRANSFER"
	Type_adjust: STRING_8 = "ADJUST"
	Type_pick: STRING_8 = "PICK"
	Type_return: STRING_8 = "RETURN"

invariant
	positive_quantity: quantity >= 0
	valid_type: movement_type.same_string (Type_receive) or
				movement_type.same_string (Type_ship) or
				movement_type.same_string (Type_transfer) or
				movement_type.same_string (Type_adjust) or
				movement_type.same_string (Type_pick) or
				movement_type.same_string (Type_return)

end
