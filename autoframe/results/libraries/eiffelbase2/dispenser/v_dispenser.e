note
	description: "Containers that can be extended with values and make only one element accessible at a time."
	author: "Nadia Polikarpova"
	model: sequence
	manual_inv: true
	false_guards: true

deferred class
	V_DISPENSER [G]

inherit
	V_CONTAINER [G]
		redefine
			count
		end

feature -- Access

	item: G
			-- The accessible element.
		deferred
		end

feature -- Measurement

	count: INTEGER
			-- Number of elements.
		deferred
		end

feature -- Iteration

	new_cursor: V_ITERATOR [G]
			-- New iterator pointing to the accessible element.
			-- (Traversal in the order of accessibility.)
		deferred
		end

feature -- Extension

	extend (v: G)
			-- Add `v' to the dispenser.
		note
			modify_model: sequence, Current_
		deferred
		end

feature -- Removal

	remove
			-- Remove the accessible element.
		note
			modify_model: sequence, Current_
		deferred
		end

	wipe_out
			-- Remove all elements.
		note
			modify_model: sequence, Current_
		deferred
		end

feature -- Specification

	sequence: MML_SEQUENCE [G]
			-- Sequence of elements in the order of access.
		note
			status: ghost
			replaces: bag
		attribute
		end

invariant
	bag_definition: bag ~ sequence.to_bag

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
