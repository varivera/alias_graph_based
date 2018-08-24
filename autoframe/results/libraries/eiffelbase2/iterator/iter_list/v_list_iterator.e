note
	description: "Iterators over lists."
	author: "Nadia Polikarpova"
	model: target, index_
	manual_inv: true
	false_guards: true

deferred class
	V_LIST_ITERATOR [G]

inherit
	V_MUTABLE_SEQUENCE_ITERATOR [G]
		redefine
			target
		end

feature -- Access

	target: V_LIST [G]
			-- List to iterate over.

feature -- Extension

	extend_left (v: G)
			-- Insert `v' to the left of current position.
			-- Do not move cursor.
		note
			modify_model: index_, sequence, box, Current_
			modify_model: sequence, target
		deferred
		end

	extend_right (v: G)
			-- Insert `v' to the right of current position.
			-- Do not move cursor.
		note
			modify_model: sequence, Current_
			modify_model: sequence, target
		deferred
		end

	insert_left (other: V_ITERATOR [G])
			-- Append, to the left of current position, sequence of values produced by `other'.
			-- Do not move cursor.
		note
			modify_model: index_, sequence, Current_
			modify_model: sequence, target
			modify_model: index_, other
		deferred
		end

	insert_right (other: V_ITERATOR [G])
			-- Append, to the right of current position, sequence of values produced by `other'.
			-- Move cursor to the last element of inserted sequence.
		note
			modify_model: index_, sequence, Current_
			modify_model: sequence, target
			modify_model: index_, other
		deferred
		end

feature -- Removal

	remove
			-- Remove element at current position. Move cursor to the next position.
		note
			modify_model: index_, sequence, Current_
			modify_model: sequence, target
		deferred
		end

	remove_left
			-- Remove element to the left current position. Do not move cursor.
		note
			modify_model: index_, sequence, Current_
			modify_model: sequence, target
		deferred
		end

	remove_right
			-- Remove element to the right current position. Do not move cursor.
		note
			modify_model: sequence, Current_
			modify_model: sequence, target
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
