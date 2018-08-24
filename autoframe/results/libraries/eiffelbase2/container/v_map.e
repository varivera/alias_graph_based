note
	description: "[
		Containers where values are associated with keys. 
		Keys are unique with respect to object equality.
		Immutable interface.
		]"
	author: "Nadia Polikarpova"
	model: map, lock
	manual_inv: true
	false_guards: true

deferred class
	V_MAP [K, V]

inherit
	V_CONTAINER [V]
		redefine
			is_empty
		end

	V_LOCKER [K]

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		deferred
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is container empty?
		do
			Result := count = 0
		end

feature -- Search

	has_key (k: K): BOOLEAN
			-- Is key `k' contained?
			-- (Uses object equality.)
		deferred
		end

	key (k: K): K
			-- Element of `map.domain' equivalent to `v' according to object equality.
		deferred
		end

	item alias "[]" (k: K): V
			-- Value associated with `k'.
		deferred
		end

feature -- Iteration

	new_cursor: V_MAP_ITERATOR [K, V]
			-- New iterator pointing to a position in the map, from which it can traverse all elements by going `forth'.
		deferred
		end

	at_key (k: K): like new_cursor
			-- New iterator pointing to a position with key `k'.
			-- If key does not exist, iterator is off.
		deferred
		end

feature -- Specification

	map: MML_MAP [K, V]
			-- Map of keys to values.
		note
			status: ghost
			replaces: bag, locked
		attribute
		end

	domain_has (k: K): BOOLEAN
			-- Does `map.domain' contain an element equal to `k' under object equality?
		note
			reads_field: map, lock, Current_
			--reads: map.domain, k
		do
			Result := lock.set_has (map.domain, k)
		end

	domain_item (k: K): K
			-- Element of `map.domain' that is equal to `k' under object equality.
		note
			reads_field: map, lock, Current_
			--reads: map.domain, k
		do
			Result := lock.set_item (map.domain, k)
		end

	bag_from (m: like map): like bag
			-- Bag of values in `m'.
		do
			Result := m.to_bag
		end

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional, nonvariant
		do
			Result := map ~ other.map
		end

invariant
	locked_definition: locked ~ map.domain
	bag_definition: bag ~ bag_from (map)

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
