note
	description: "[
		WMS Stock - Current inventory level at a location.

		CRITICAL: This entity has a VERSION column for optimistic locking.
		Any update must check version to prevent lost updates from concurrent access.

		FRICTION POINT: SIMPLE_SQL currently has no built-in optimistic locking support.
		Every stock update requires manual:
		1. Read current version
		2. UPDATE ... WHERE id = ? AND version = ?
		3. Check rows affected (0 = conflict, retry needed)

		DESIRED API:
		db.update_optimistic (table, id, version, <<changes>>)
		  -- Returns: {ok, new_version} or {conflict, current_version}
	]"

class
	WMS_STOCK

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_product_id, a_location_id: INTEGER_64;
			a_quantity, a_reserved: INTEGER; a_version: INTEGER_64;
			a_updated_at: READABLE_STRING_8)
		do
			id := a_id
			product_id := a_product_id
			location_id := a_location_id
			quantity := a_quantity
			reserved_quantity := a_reserved
			version := a_version
			updated_at := a_updated_at.to_string_8
		end

	make_new (a_product_id, a_location_id: INTEGER_64; a_quantity: INTEGER)
		require
			valid_product: a_product_id > 0
			valid_location: a_location_id > 0
			non_negative_qty: a_quantity >= 0
		do
			product_id := a_product_id
			location_id := a_location_id
			quantity := a_quantity
			reserved_quantity := 0
			version := 1
			updated_at := ""
		ensure
			is_new: is_new
			initial_version: version = 1
			no_reserved: reserved_quantity = 0
		end

feature -- Access

	id: INTEGER_64

	product_id: INTEGER_64

	location_id: INTEGER_64

	quantity: INTEGER
			-- Total quantity on hand.

	reserved_quantity: INTEGER
			-- Quantity reserved for pending orders.

	version: INTEGER_64
			-- Optimistic lock version (incremented on each update).

	updated_at: STRING_8

feature -- Derived

	available_quantity: INTEGER
			-- Quantity available for new reservations.
		do
			Result := quantity - reserved_quantity
		ensure
			definition: Result = quantity - reserved_quantity
		end

feature -- Status

	is_new: BOOLEAN
		do
			Result := id = 0
		end

	can_reserve (a_qty: INTEGER): BOOLEAN
			-- Is there enough available stock to reserve `a_qty`?
		do
			Result := available_quantity >= a_qty
		end

	can_pick (a_qty: INTEGER): BOOLEAN
			-- Is there enough quantity to pick (from reserved)?
		do
			Result := quantity >= a_qty and reserved_quantity >= a_qty
		end

feature -- Modification

	set_id (a_id: INTEGER_64)
		require
			was_new: is_new
		do
			id := a_id
		end

	increment_version
			-- Bump version for optimistic locking.
		do
			version := version + 1
		end

	adjust_quantity (a_delta: INTEGER)
			-- Add or remove stock (positive = add, negative = remove).
		require
			no_negative_result: quantity + a_delta >= 0
		do
			quantity := quantity + a_delta
		ensure
			adjusted: quantity = old quantity + a_delta
		end

	reserve (a_qty: INTEGER)
			-- Reserve stock for an order.
		require
			positive: a_qty > 0
			sufficient: can_reserve (a_qty)
		do
			reserved_quantity := reserved_quantity + a_qty
		ensure
			reserved: reserved_quantity = old reserved_quantity + a_qty
		end

	release_reservation (a_qty: INTEGER)
			-- Release reserved stock (order cancelled).
		require
			positive: a_qty > 0
			has_reserved: reserved_quantity >= a_qty
		do
			reserved_quantity := reserved_quantity - a_qty
		ensure
			released: reserved_quantity = old reserved_quantity - a_qty
		end

	pick (a_qty: INTEGER)
			-- Pick reserved stock (fulfill order).
		require
			positive: a_qty > 0
			can_pick: can_pick (a_qty)
		do
			quantity := quantity - a_qty
			reserved_quantity := reserved_quantity - a_qty
		ensure
			picked: quantity = old quantity - a_qty
			unreserved: reserved_quantity = old reserved_quantity - a_qty
		end

invariant
	non_negative_quantity: quantity >= 0
	non_negative_reserved: reserved_quantity >= 0
	reserved_not_exceed: reserved_quantity <= quantity
	positive_version: version > 0

end
