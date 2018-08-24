note
	description: "[
		Container where all elements are unique with respect to object equality. 
		Elements can be added and removed.
		]"
	author: "Nadia Polikarpova"
	model: set, lock
	manual_inv: true
	false_guards: true

deferred class
	V_SET [G]

inherit
	V_CONTAINER [G]
		rename
			has as has_exactly
		redefine
			count,
			is_empty,
			occurrences
		end

	V_LOCKER [G]
		rename
			locked as set
		redefine
			set
		end

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

	has (v: G): BOOLEAN
			-- Is `v' contained?
			-- (Uses object equality.)
		deferred
		end

	item (v: G): G
			-- Element of `set' equivalent to `v' according to object equality.
		deferred
		end

	occurrences (v: G): INTEGER
			-- How many times is `v' contained?
			-- (Uses reference equality.)
		do
			if has_exactly (v) then
				Result := 1
			end
		end

feature -- Iteration

	new_cursor: V_SET_ITERATOR [G]
			-- New iterator pointing to a position in the set, from which it can traverse all elements by going `forth'.
		deferred
		end

	at (v: G): V_SET_ITERATOR [G]
			-- New iterator over `Current' pointing at element `v' if it exists and `after' otherwise.
		deferred
		end

feature -- Comparison

	is_subset_of (other: V_SET [G]): BOOLEAN
			-- Does `other' have all elements of `Current'?
			-- (Uses object equality.)
		local
			it: V_SET_ITERATOR [G]
		do
			Result := True
			if other /= Current then
				from
					it := new_cursor
				until
					it.after or not Result
				loop
					Result := other.has (it.item)
					it.forth
				variant
					it.sequence.count - it.index_
				end

			end
		end

	is_superset_of (other: V_SET [G]): BOOLEAN
			-- Does `Current' have all elements of `other'?
			-- (Uses object equality..)
		do
			Result := other.is_subset_of (Current)
		end

	disjoint (other: V_SET [G]): BOOLEAN
			-- Do no elements of `other' occur in `Current'?
			-- (Uses object equality.)
		local
			it: V_SET_ITERATOR [G]
		do
			if other.is_empty then
				Result := True
			elseif other /= Current then
				from
					it := new_cursor
					Result := True
				until
					it.after or not Result
				loop
					Result := not other.has (it.item)
					it.forth
				variant
					it.sequence.count - it.index_
				end
			end
		end

feature -- Extension

	extend (v: G)
			-- Add `v' to the set.
		note
			modify_model: set, Current_
		deferred
		end

	join (other: V_SET [G])
			-- Add all elements from `other'.
		note
			modify_model: set, Current_
		local
			it: V_SET_ITERATOR [G]
		do
			if other /= Current then
				from
					it := other.new_cursor
				until
					it.after
				loop
					extend (it.item)
					it.forth
				variant
					it.sequence.count - it.index_
				end
			end
		end

feature -- Removal

	remove (v: G)
			-- Remove `v' from the set, if contained.
			-- Otherwise do nothing.		
		note
			modify_model: set, Current_
		local
			it: V_SET_ITERATOR [G]
		do
			it := at (v)
			if not it.after then
				it.remove
			end
		end

	meet (other: V_SET [G])
			-- Keep only elements that are also in `other'.
		note
			modify_model: set, Current_
		local
			it: V_SET_ITERATOR [G]
		do
			if other /= Current then
				from
					it := new_cursor
				until
					it.after
				loop
					if not other.has (it.item) then
						it.remove
					else
						it.forth
					end
				variant
					it.sequence.count - it.index_
				end
			end
		end

	subtract (other: V_SET [G])
			-- Remove elements that are in `other'.
		note
			modify_model: set, Current_
		local
			it: V_SET_ITERATOR [G]
		do
			if other /= Current then
				from
					it := other.new_cursor
				until
					it.after
				loop
					remove (it.item)
					it.forth
				variant
					it.sequence.count - it.index_
				end
			else
				wipe_out
			end
		end

	symmetric_subtract (other: V_SET [G])
			-- Keep elements that are only in `Current' or only in `other'.
		note
			modify_model: set, Current_
		local
			it: V_SET_ITERATOR [G]
			seq: MML_SEQUENCE [G]
		do
			if other /= Current then
				from
					it := other.new_cursor
					seq := it.sequence
				until
					it.after
				loop
					if has (it.item) then
						remove (it.item)
					else
						extend (it.item)
					end
					it.forth
				variant
					seq.count - it.index_
				end
			else
				wipe_out
			end
		end

	wipe_out
			-- Remove all elements.
		note
			modify_model: set, Current_
		deferred
		end

feature -- Specification

	set: MML_SET [G]
			-- Set of elements.
		note
			status: ghost
			replaces: bag
		attribute
		end

	set_has (v: G): BOOLEAN
			-- Does `set' contain an element equal to `v' under object equality?
		do
			Result := lock.set_has (set, v)
		end

	set_item (v: G): G
			-- Element of `set' that is equal to `v' under object equality.
		do
			Result := lock.set_item (set, v)
		end

	bag_from (s: like set): like bag
			-- A bag that contains all elements of `s' exactly once.
		local
			x: G
			s1: like set
		do
			from
				s1 := s
			until
				s1.is_empty
			loop
				x := s1.any_item
				Result := Result & x
				s1 := s1 / x
			end
		end

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional, nonvariant
		do
			Result := set ~ other.set
		end

invariant
	bag_definition: bag = bag_from (set)

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
