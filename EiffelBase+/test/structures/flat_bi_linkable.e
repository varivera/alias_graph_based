class
	FLAT_BI_LINKABLE [G]

create {FLAT_TWO_WAY_LIST, FLAT_TWO_WAY_SORTED_SET}
	put

feature -- Access

	item: G
			-- Content of cell.
			-- (from CELL)

	left: like Current
			-- Left neighbor

	right: like Current
			-- Right neighbor
			-- (from LINKABLE)

feature {FLAT_BI_LINKABLE, FLAT_TWO_WAY_LIST, FLAT_TWO_WAY_SORTED_SET} -- Element change

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

feature {FLAT_BI_LINKABLE, FLAT_TWO_WAY_LIST, FLAT_TWO_WAY_SORTED_SET} -- Implementation

	forget_left
			-- Remove links with left neighbor.
		local
			l: like left
		do
			l := left
			if l /= Void then
				l.simple_forget_right
				left := Void
			end
		ensure
			left_not_chained: left = Void or else (attached {like left} old left as p implies p.right = Void)
		end

	forget_right
			-- Remove links with right neighbor.
		require -- from  LINKABLE
			True
		local
			l_right: like right
		do
			l_right := right
			if l_right /= Void then
				l_right.simple_forget_left
				right := Void
			end
		ensure -- from LINKABLE
			not_chained: right = Void
			right_not_chained: (attached {like right} old right as r) implies r.left = Void
		end

	put_left (other: like Current)
			-- Put `other' to the left of current cell.
		local
			l: like left
		do
			l := left
			if l /= Void then
				l.simple_forget_right
			end
			left := other
			if other /= Void then
				other.simple_put_right (Current)
			end
		ensure
			chained: left = other
		end

	put_right (other: like Current)
			-- Put `other' to the right of current cell.
		local
			l_right: like right
			l_other: like other
		do
			l_right := right
			if l_right /= Void then
				l_right.simple_forget_left
			end
			right := other
			l_other := other
			if l_other /= Void then
				l_other.simple_put_left (Current)
			end
		ensure -- from LINKABLE
			chained: right = other
		end

feature {FLAT_BI_LINKABLE, FLAT_TWO_WAY_LIST, FLAT_TWO_WAY_SORTED_SET} -- Implementation

	simple_forget_left
			-- Remove left link (do nothing to left neighbor).
		do
			left := Void
		ensure
			not_chained: left = Void
		end

	simple_forget_right
			-- Remove right link (do nothing to right neighbor).
		do
			right := Void
		end

	simple_put_left (other: like Current)
			-- Set left to `other' is
		local
			l: like left
		do
			l := left
			if l /= Void then
				l.simple_forget_right
			end
			left := other
		end

	simple_put_right (other: like Current)
			-- Set right to `other'
		local
			l_right: like right
		do
			l_right := right
			if l_right /= Void then
				l_right.simple_forget_left
			end
			right := other
		end

invariant
	right_symmetry: attached right as r implies (r.left = Current)
	left_symmetry: attached left as l implies (l.right = Current)

end -- class BI_LINKABLE

