class
	FLAT_LINKABLE [G]

create {FLAT_LINKED_LIST, FLAT_LINKED_SET, FLAT_LINKED_STACK}
	put

feature -- Access

	item: G
			-- Content of cell.
			-- (from CELL)

	right: like Current
			-- Right neighbor		

feature {FLAT_LINKABLE, FLAT_LINKED_LIST, FLAT_LINKED_SET, FLAT_LINKED_STACK} -- Element change

	put (v: like item)
			-- Make `v' the cell's item.
			-- Was declared in CELL as synonym of replace.
			-- (from CELL)
		do
			item := v
		ensure -- from CELL
			item_inserted: item = v
		end

feature -- Element change

	replace (v: like item)
			-- Make `v' the cell's item.
			-- Was declared in CELL as synonym of put.
			-- (from CELL)
		do
			item := v
		ensure -- from CELL
			item_inserted: item = v
		end

feature {FLAT_LINKABLE, FLAT_LINKED_LIST, FLAT_LINKED_SET, FLAT_LINKED_STACK} -- Implementation

	forget_right
			-- Remove right link.
		do
			right := Void
		ensure
			not_chained: right = Void
		end

	put_right (other: like Current)
			-- Put `other' to the right of current cell.
		do
			right := other
		ensure
			chained: right = other
		end

end -- class LINKABLE

