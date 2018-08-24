note
	description: "[
			Hash sets with hash function provided by HASHABLE and object equality.
			Implementation uses hash tables.
			Search, extension and removal are amortized constant time.
		]"
	author: "Nadia Polikarpova"
	model: set, lock
	manual_inv: true
	false_guards: true

frozen class
	V_HASH_SET [G -> V_HASHABLE]

inherit
	V_SET [G]
		redefine
			lock
		end

create
	make

feature {NONE} -- Initialization

	make (l: V_HASH_LOCK [G])
			-- Create an empty set with lock `l'.
		note
			modify: Current_
		do
			create table.make (l)
			l.add_client (Current)
		end

feature -- Initialization

	copy_ (other: V_HASH_SET [G])
			-- Initialize by copying all the items of `other'.
		note
			modify_model: set, Current_
		do
			if other /= Current then
				table.copy_ (other.table)
			end
		end

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		do
			Result := table.count
		end

feature -- Search

	has (v: G): BOOLEAN
			-- Is `v' contained?
			-- (Uses object equality.)
		do
			Result := table.has_key (v)
		end

	item (v: G): G
			-- Element of `set' equivalent to `v' according to object equality.
		do
			Result := table.key (v)
		end

feature -- Iteration

	new_cursor: V_HASH_SET_ITERATOR [G]
			-- New iterator pointing to a position in the set, from which it can traverse all elements by going `forth'.
		do
			create Result.make (Current)
			Result.start
		end

	at (v: G): V_HASH_SET_ITERATOR [G]
			-- New iterator over `Current' pointing at element `v' if it exists and `after' otherwise.
		do
			create Result.make (Current)
			Result.search (v)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is the abstract state of Current equal to that of `other'?
		do
			Result := table.is_equal_ (other.table)
		end

feature -- Extension

	extend (v: G)
			-- Add `v' to the set.
		do
			table.force (Void, v)
		end

feature -- Removal

	wipe_out
			-- Remove all elements.
		do
			table.wipe_out
		end

feature -- Implementation

	table: V_HASH_TABLE [G, ANY]
			-- Hash table that stores set elements as keys.

feature -- Specification

	lock: V_HASH_LOCK [G]
			-- Helper object for keeping items consistent.
		note
			status: ghost
		attribute
		end

invariant
	table_exists: table /= Void
	set_implementation: set = table.map.domain
	table_values_definition: across set as x all table.map [x.item] = Void end
	same_lock: lock = table.lock

note
	copyright: "Copyright (c) 1984-2014, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
