note
	description: "[
		Helper ghost objects that prevent container items from unwanted modifications.
		]"
	author: "Nadia Polikarpova"
	status: ghost
	model: locked, equivalence
	manual_inv: true
	false_guards: true
	explicit: "all"

class
	V_LOCK [G]

feature -- Access	

	locked: MML_SET [G]
			-- All locked items (might be shared between multiple `observers').
		attribute
		end

	equivalence: MML_RELATION [G, G]
			-- Cache of object equality relation on items from `locked'.
		attribute
		end

feature -- Basic operations

	lock (item: G)
			-- Add `item' and its subjects to `locked'.
		note
			modify: Current_
		do
			add_equivalences (item)
			locked := locked & item
		end

	unlock (item: G)
			-- Remove `item' that is not in use and its subjects from `locked'.
		note
			modify: Current_
		do
			locked := locked / item
		end

	add_client (c: V_LOCKER [G])
			-- Add `c' to `observers'.
		do
		end

feature -- Specification

	in_use_still_locked (new_locked: like locked; o: ANY): BOOLEAN
			-- All items that are in use by any of the `observers' are still in `new_locked'. (Update guard).
		do
			Result := attached {V_LOCKER [G]} o as l and then
				across locked - new_locked as x all not l.locked [x.item] end
		end

	no_new_pairs (new_eq: like equivalence; o: ANY): BOOLEAN
			-- `new_eq' does not introduce any new pairs compared to `equivalence' on the elements of `locked'. (Update guard).
		do
			Result := across locked as x all across locked as y all
				not equivalence [x.item, y.item] implies not new_eq [x.item, y.item] end end
		end

	set_has (s: MML_SET [G]; v: G): BOOLEAN
			-- Does `s' contain an element equal to `v' under object equality?
		do
			--Result := across s as x some v.is_model_equal (x.item) end
			Result := True
		end

	set_item (s: MML_SET [G]; v: G): G
			-- Element of `s' that is equal to `v' under object equality.
		local
			s1: MML_SET [G]
		do
			from
				s1 := s
				Result := s1.any_item
			until
				--Result.is_model_equal (v)
				True
			loop
				s1 := s1 / Result
				Result := s1.any_item
			end
		end

feature {NONE} -- Implementation

	add_equivalences (x: G)
			-- Add equivalences between `locked' and a new item `x' to `equivalence'.
		note
			modify_field: equivalence, Current_
		local
			s: like locked
			y: G
		do
			equivalence := equivalence.extended (x, x)
			from
				s := locked
			until
				s.is_empty
			loop
				y := s.any_item
				--if x.is_model_equal (y) then
				if True then
					equivalence := equivalence.extended (x, y)
					equivalence := equivalence.extended (y, x)
				else
					equivalence := equivalence.removed (x, y)
					equivalence := equivalence.removed (y, x)
				end
				s := s / y
			end
		end

invariant
	locked_non_void: locked.non_void
	--equivalence_definition: across locked as x all across locked as y all equivalence [x.item, y.item] = (x.item.is_model_equal (y.item)) end end

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
