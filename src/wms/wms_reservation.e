note
	description: "[
		WMS Reservation - Hold on stock for pending orders.

		Reservations have an expiry time - if not fulfilled, they should be
		automatically released. This prevents stock from being locked forever
		by abandoned carts/orders.

		FRICTION POINT: Time-based expiry requires:
		1. Querying for expired reservations
		2. Releasing each one (update stock, delete reservation)
		3. All within a transaction
		4. Handling concurrent access (someone might fulfill while we expire)

		DESIRED API:
		db.cleanup_expired ("reservations", "expires_at",
			agent release_reservation_callback)
		  -- Automatic batch processing with callbacks

		ALSO NEEDED:
		db.insert_expiring (table, data, expires_in: DURATION)
		  -- Auto-calculates expires_at from current time + duration
	]"

class
	WMS_RESERVATION

create
	make,
	make_new

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_product_id, a_location_id: INTEGER_64;
			a_quantity: INTEGER; a_order_ref: READABLE_STRING_8;
			a_reserved_by: INTEGER_64; a_expires_at, a_created_at: READABLE_STRING_8)
		do
			id := a_id
			product_id := a_product_id
			location_id := a_location_id
			quantity := a_quantity
			order_reference := a_order_ref.to_string_8
			reserved_by := a_reserved_by
			expires_at := a_expires_at.to_string_8
			created_at := a_created_at.to_string_8
		end

	make_new (a_product_id, a_location_id: INTEGER_64; a_quantity: INTEGER;
			a_order_ref: READABLE_STRING_8; a_user: INTEGER_64;
			a_expires_at: READABLE_STRING_8)
		require
			valid_product: a_product_id > 0
			valid_location: a_location_id > 0
			positive_qty: a_quantity > 0
			has_order: not a_order_ref.is_empty
			has_expiry: not a_expires_at.is_empty
		do
			product_id := a_product_id
			location_id := a_location_id
			quantity := a_quantity
			order_reference := a_order_ref.to_string_8
			reserved_by := a_user
			expires_at := a_expires_at.to_string_8
			created_at := ""
		ensure
			is_new: is_new
		end

feature -- Access

	id: INTEGER_64

	product_id: INTEGER_64

	location_id: INTEGER_64

	quantity: INTEGER

	order_reference: STRING_8
			-- Associated order/cart ID.

	reserved_by: INTEGER_64
			-- User who created the reservation.

	expires_at: STRING_8
			-- ISO 8601 timestamp when reservation expires.

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
		do
			id := a_id
		end

	set_created_at (a_timestamp: READABLE_STRING_8)
		do
			created_at := a_timestamp.to_string_8
		end

	extend_expiry (a_new_expires_at: READABLE_STRING_8)
			-- Extend the reservation expiry time.
		require
			not_empty: not a_new_expires_at.is_empty
		do
			expires_at := a_new_expires_at.to_string_8
		end

invariant
	positive_quantity: quantity > 0
	has_order_reference: not order_reference.is_empty
	has_expiry: not expires_at.is_empty

end
