note
	description: "Cells that can be linked to two neighbour cells."
	author: "Nadia Polikarpova"
	model: item, left, right

frozen class
	V_DOUBLY_LINKABLE [G]

inherit
	V_CELL [G]

create
	put

feature -- Access

	right: V_DOUBLY_LINKABLE [G]
			-- Next cell.

	left: V_DOUBLY_LINKABLE [G]
			-- Previous cell.

feature -- Replacement

	connect_right (cell: V_DOUBLY_LINKABLE [G])
			-- Connect current list segment to the segment beginning with `cell'.
		note
			modify_model: right, Current_
			modify_model: left, cell
		do
			put_right (cell)
			cell.put_left (Current)
		end

	insert_right (front, back: V_DOUBLY_LINKABLE [G])
			-- Insert a list segment `front'-`back' to the right of current cell.
		note
			modify_model: right, Current_
			modify_model: right, back
			modify_model: left, right
			modify_model: left, front
		do
			back.put_right (right)
			right.put_left (back)
			put_right (front)
			front.put_left (Current)
		end

	remove_right
			-- Remove the cell to the right of current cell.
		note
			modify_model: right, Current_
			--modify_model: left, right.right
			modify: right
		do
			put_right (right.right)
			right.put_left (Current)
		end

feature {V_DOUBLY_LINKABLE, V_DOUBLY_LINKED_LIST} -- Replacement

	put_right (cell: V_DOUBLY_LINKABLE [G])
			-- Replace `right' with `cell'.
		note
			modify_field: right, Current_
		do
			right := cell
		end

	put_left (cell: V_DOUBLY_LINKABLE [G])
			-- Replace `left' with `cell'.
		note
			modify_field: left, Current_
		do
			left := cell
		end

feature -- Specification

	not_left (new_left: V_DOUBLY_LINKABLE [G]; o: ANY): BOOLEAN
			-- Is `o' different from `left'?
		note
			status: functional, ghost
		do
			Result := o /= left
		end

	not_right (new_right: V_DOUBLY_LINKABLE [G]; o: ANY): BOOLEAN
			-- Is `o' different from `right'?
		note
			status: functional, ghost
		do
			Result := o /= right
		end

invariant
	left_consistent: left /= Void implies left.right = Current
	right_consistent: right /= Void implies right.left = Current

note
	explicit: subjects, observers
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
