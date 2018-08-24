note
	description: "Iterators over sets, allowing efficient search."
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

deferred class
	V_SET_ITERATOR [G]

inherit
	V_ITERATOR [G]
		redefine
			target
		end

feature -- Access

	target: V_SET [G]
			-- Set to iterate over.

feature -- Cursor movement

	search (v: G)
			-- Move to an element equivalent to `v'.
			-- If `v' does not appear, go after.
			-- (Use object equality.)
		note
			modify_model: index_, Current_
		deferred
		end

feature -- Removal

	remove
			-- Remove element at current position. Move to the next position.
		note
			modify_model: sequence, box, Current_
			modify_model: set, target
		deferred
		end

feature -- Specification

	is_model_equal (other: like Current): BOOLEAN
			-- Is iterator traversing the same container in the same order and is at the same position at `other'?		
		note
			status: ghost, functional, nonvariant
		do
			Result := target = other.target and sequence = other.sequence and index_ = other.index_
		end

invariant
	target_set_constraint: target.set ~ sequence.range

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
