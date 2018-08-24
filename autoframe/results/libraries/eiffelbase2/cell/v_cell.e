note
	description: "Cells containing an item."
	author: "Nadia Polikarpova"
	model: item

class
	V_CELL [G]

create
	put

feature -- Access

	item: G
			-- Content of the cell.

feature -- Replacement

	put (v: G)
			-- Replace `item' with `v'.
		note
			modify_model: item, Current_
		do
			item := v
		end

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
