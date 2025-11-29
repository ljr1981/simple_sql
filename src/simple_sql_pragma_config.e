note
	description: "[
		SQLite PRAGMA configuration for performance tuning and database settings.

		Provides named creation procedures for common configurations:
			- make_default: Standard SQLite defaults
			- make_wal: WAL mode with sensible defaults
			- make_performance: Optimized for speed (some durability tradeoff)
			- make_safe: Maximum durability, slower writes

		Usage:
			create db.make ("mydb.sqlite")
			create config.make_wal
			config.apply (db)
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SQL_PRAGMA_CONFIG

create
	make_default,
	make_wal,
	make_performance,
	make_safe,
	make_custom

feature {NONE} -- Initialization

	make_default
			-- Standard SQLite defaults (DELETE journal, FULL synchronous)
		do
			journal_mode := Journal_delete
			synchronous := Synchronous_full
			cache_size := -2000  -- 2MB cache (negative = KB)
			busy_timeout := 5000  -- 5 seconds
			foreign_keys := True
			mmap_size := 0  -- Disabled by default
		ensure
			journal_delete: journal_mode = Journal_delete
			synchronous_full: synchronous = Synchronous_full
		end

	make_wal
			-- WAL mode with sensible defaults for concurrent read/write
			-- Good balance of performance and durability
		do
			journal_mode := Journal_wal
			synchronous := Synchronous_normal
			cache_size := -64000  -- 64MB cache
			busy_timeout := 30000  -- 30 seconds (WAL handles concurrency better)
			foreign_keys := True
			mmap_size := 268435456  -- 256MB memory-mapped I/O
		ensure
			journal_wal: journal_mode = Journal_wal
			synchronous_normal: synchronous = Synchronous_normal
		end

	make_performance
			-- Maximum performance configuration
			-- WARNING: Reduced durability - may lose recent commits on crash
		do
			journal_mode := Journal_wal
			synchronous := Synchronous_off
			cache_size := -128000  -- 128MB cache
			busy_timeout := 60000  -- 60 seconds
			foreign_keys := True
			mmap_size := 536870912  -- 512MB memory-mapped I/O
		ensure
			journal_wal: journal_mode = Journal_wal
			synchronous_off: synchronous = Synchronous_off
		end

	make_safe
			-- Maximum durability configuration
			-- Slower writes but guarantees data integrity
		do
			journal_mode := Journal_wal
			synchronous := Synchronous_extra
			cache_size := -16000  -- 16MB cache
			busy_timeout := 10000  -- 10 seconds
			foreign_keys := True
			mmap_size := 0  -- Disabled for safety
		ensure
			journal_wal: journal_mode = Journal_wal
			synchronous_extra: synchronous = Synchronous_extra
		end

	make_custom
			-- Create with all defaults, caller sets individual values
		do
			make_default
		end

feature -- Access

	journal_mode: INTEGER
			-- Journal mode (DELETE, WAL, MEMORY, etc.)

	synchronous: INTEGER
			-- Synchronous mode (OFF, NORMAL, FULL, EXTRA)

	cache_size: INTEGER
			-- Cache size (positive = pages, negative = KB)

	busy_timeout: INTEGER
			-- Timeout in milliseconds when database is locked

	foreign_keys: BOOLEAN
			-- Enable foreign key constraints?

	mmap_size: INTEGER_64
			-- Memory-mapped I/O size in bytes (0 = disabled)

feature -- Element change

	set_journal_mode (a_mode: INTEGER)
			-- Set journal mode
		require
			valid_mode: a_mode >= Journal_delete and a_mode <= Journal_off
		do
			journal_mode := a_mode
		ensure
			mode_set: journal_mode = a_mode
		end

	set_synchronous (a_level: INTEGER)
			-- Set synchronous level
		require
			valid_level: a_level >= Synchronous_off and a_level <= Synchronous_extra
		do
			synchronous := a_level
		ensure
			level_set: synchronous = a_level
		end

	set_cache_size (a_size: INTEGER)
			-- Set cache size (positive = pages, negative = KB)
		do
			cache_size := a_size
		ensure
			size_set: cache_size = a_size
		end

	set_busy_timeout (a_timeout: INTEGER)
			-- Set busy timeout in milliseconds
		require
			non_negative: a_timeout >= 0
		do
			busy_timeout := a_timeout
		ensure
			timeout_set: busy_timeout = a_timeout
		end

	set_foreign_keys (a_enabled: BOOLEAN)
			-- Enable or disable foreign key constraints
		do
			foreign_keys := a_enabled
		ensure
			enabled_set: foreign_keys = a_enabled
		end

	set_mmap_size (a_size: INTEGER_64)
			-- Set memory-mapped I/O size (0 = disabled)
		require
			non_negative: a_size >= 0
		do
			mmap_size := a_size
		ensure
			size_set: mmap_size = a_size
		end

feature -- Operations

	apply (a_database: SIMPLE_SQL_DATABASE)
			-- Apply this configuration to the database
		require
			database_attached: a_database /= Void
			database_open: a_database.is_open
		do
			-- Journal mode (returns current mode, so use query)
			a_database.execute ("PRAGMA journal_mode = " + journal_mode_string)

			-- Synchronous
			a_database.execute ("PRAGMA synchronous = " + synchronous.out)

			-- Cache size
			a_database.execute ("PRAGMA cache_size = " + cache_size.out)

			-- Busy timeout
			a_database.execute ("PRAGMA busy_timeout = " + busy_timeout.out)

			-- Foreign keys
			if foreign_keys then
				a_database.execute ("PRAGMA foreign_keys = ON")
			else
				a_database.execute ("PRAGMA foreign_keys = OFF")
			end

			-- Memory-mapped I/O
			a_database.execute ("PRAGMA mmap_size = " + mmap_size.out)
		end

feature -- Query

	journal_mode_string: STRING_8
			-- Journal mode as string for PRAGMA
		do
			inspect journal_mode
			when Journal_delete then Result := "DELETE"
			when Journal_truncate then Result := "TRUNCATE"
			when Journal_persist then Result := "PERSIST"
			when Journal_memory then Result := "MEMORY"
			when Journal_wal then Result := "WAL"
			when Journal_off then Result := "OFF"
			else
				Result := "DELETE"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	synchronous_string: STRING_8
			-- Synchronous mode as string
		do
			inspect synchronous
			when Synchronous_off then Result := "OFF"
			when Synchronous_normal then Result := "NORMAL"
			when Synchronous_full then Result := "FULL"
			when Synchronous_extra then Result := "EXTRA"
			else
				Result := "FULL"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Constants: Journal Modes

	Journal_delete: INTEGER = 0
			-- Default mode - journal file deleted after each transaction

	Journal_truncate: INTEGER = 1
			-- Journal file truncated instead of deleted

	Journal_persist: INTEGER = 2
			-- Journal file header zeroed instead of deleted

	Journal_memory: INTEGER = 3
			-- Journal stored in memory only (volatile!)

	Journal_wal: INTEGER = 4
			-- Write-Ahead Logging mode

	Journal_off: INTEGER = 5
			-- No journal (dangerous - no rollback possible)

feature -- Constants: Synchronous Levels

	Synchronous_off: INTEGER = 0
			-- No syncs (fastest, least safe)

	Synchronous_normal: INTEGER = 1
			-- Sync at critical moments (good balance)

	Synchronous_full: INTEGER = 2
			-- Sync after each write (safe, slower)

	Synchronous_extra: INTEGER = 3
			-- Extra syncs for additional safety

invariant
	valid_journal_mode: journal_mode >= Journal_delete and journal_mode <= Journal_off
	valid_synchronous: synchronous >= Synchronous_off and synchronous <= Synchronous_extra
	non_negative_timeout: busy_timeout >= 0
	non_negative_mmap: mmap_size >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"
	source: "[
		SIMPLE_SQL - High-level SQLite API for Eiffel
		PRAGMA reference: https://www.sqlite.org/pragma.html
	]"

end
