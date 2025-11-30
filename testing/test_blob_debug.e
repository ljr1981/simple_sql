note
	description: "Debug BLOB type handling"

class
	TEST_BLOB_DEBUG

inherit
	TEST_SET_BASE

feature

	test_debug_blob_type
		local
			l_db: SIMPLE_SQL_DATABASE
			l_stmt: SIMPLE_SQL_PREPARED_STATEMENT
			l_result: SIMPLE_SQL_RESULT
			l_blob: MANAGED_POINTER
			l_value: detachable ANY
		do
			create l_db.make_memory
			l_db.execute ("CREATE TABLE test (data BLOB)")

			-- Create simple BLOB
			create l_blob.make (10)
			l_blob.put_natural_8 (42, 0)

			-- Insert
			l_stmt := l_db.prepare ("INSERT INTO test (data) VALUES (?)")
			l_stmt.bind_blob (1, l_blob)
			l_stmt.execute

			print ("%NDatabase error: " + l_db.has_error.out)
			if l_db.has_error and then attached l_db.last_error_message as l_msg then
				print ("%NError: " + l_msg.to_string_8)
			end

			-- Query
			l_result := l_db.query ("SELECT data FROM test")
			print ("%NResult count: " + l_result.count.out)

			if not l_result.is_empty then
				l_value := l_result.first.item (1)
				print ("%NValue is void: " + (l_value = Void).out)
				if l_value /= Void then
					print ("%NValue type: " + l_value.generating_type.out)
					if attached {MANAGED_POINTER} l_value as mp then
						print ("%NIt's a MANAGED_POINTER with size: " + mp.count.out)
					else
						print ("%NNot a MANAGED_POINTER")
					end
				end
			end

			l_db.close
		end

end
