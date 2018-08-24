note
	description: "[
		Maps where key-value pairs can be updated, added and removed.
		Keys are unique with respect to object equality.
		]"
	author: "Nadia Polikarpova"
	model: map, lock
	manual_inv: true
	false_guards: true

deferred class
	V_TABLE [K, V]

inherit
	V_MAP [K, V]

feature -- Search

	item alias "[]" (k: K): V assign force
			-- Value associated with `k'.
		deferred
		end

feature -- Iteration

	new_cursor: V_TABLE_ITERATOR [K, V]
			-- New iterator pointing to a position in the map, from which it can traverse all elements by going `forth'.
		deferred
		end

feature -- Replacement

	put (v: V; k: K)
			-- Associate `v' with key `k'.
		note
			modify_model: map, Current_
		local
			it: V_TABLE_ITERATOR [K, V]
		do
			it := at_key (k)
			it.put (v)
		end

feature -- Extension

	extend (v: V; k: K)
			-- Extend table with key-value pair <`k', `v'>.
		note
			modify_model: map, Current_
		deferred
		end

	force (v: V; k: K)
			-- Make sure that `k' is associated with `v'.
			-- Add `k' if not already present.
		note
			modify_model: map, Current_
		local
			it: V_TABLE_ITERATOR [K, V]
		do
			it := at_key (k)
			if it.after then
				extend (v, k)
			else
				it.put (v)
			end
		end

feature -- Removal

	remove (k: K)
			-- Remove key `k' and its associated value.
		note
			modify_model: map, Current_
		deferred
		end

	wipe_out
			-- Remove all elements.
		note
			modify_model: map, Current_
		deferred
		end

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
