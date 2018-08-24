note
	description: "[
		Indexable containers with arbitrary bounds, whose elements are stored in a continuous memory area.
		Random access is constant time, but resizing requires memory reallocation and copying elements, and takes linear time.
		The logical size of array is the same as the physical size of the underlying memory area.
		]"
	author: "Nadia Polikarpova"
	model: sequence, lower_

frozen class
	V_ARRAY [G]

inherit
	V_MUTABLE_SEQUENCE [G]
		redefine
			lower,
			upper,
			item,
			put,
			fill,
			clear
		end

create
	make,
	make_filled,
	copy_

feature {NONE} -- Initialization

	make (l, u: INTEGER)
			-- Create array with indexes in [`l', `u']; set all values to default.
		note
			status: creator
		do
			if l <= u then
				lower := l
				upper := u
			else
				lower := 1
				upper := 0
			end
			create area.make_filled (({G}).default, upper - lower + 1)
		end

	make_filled (l, u: INTEGER; v: G)
			-- Create array with indexes in [`l', `u']; set all values to `v'.
		note
			status: creator
		do
			if l <= u then
				lower := l
				upper := u
			else
				lower := 1
				upper := 0
			end
			create area.make_filled (v, u - l + 1)
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize by copying all the items of `other'.
			-- Reallocate memory unless count stays the same.
		note
			modify_model: sequence, lower_, Current_
		do
			if other /= Current then
				if area = Void or other.count /= upper - lower + 1 then
					create area.make_filled (({G}).default, other.count)
				end
				area.copy_data (other.area, 0, 0, other.count)
				lower := other.lower
				upper := other.upper
			end
		end

feature -- Access

	item alias "[]" (i: INTEGER): G assign put
			-- Value associated with `i'.
		do
			Result := area [i - lower]
		end

	subarray (l, u: INTEGER): V_ARRAY [G]
			-- Array consisting of elements of Current in index range [`l', `u'].
		note
			status: impure
		do
			create Result.make (l, u)
			Result.copy_range (Current, l, u, Result.lower)
		end

feature -- Measurement

	lower: INTEGER
			-- Lower bound of index interval.

	upper: INTEGER
			-- Upper bound of index interval.

	count: INTEGER
			-- Number of elements.
		do
			Result := upper - lower + 1
		end

feature -- Iteration

	at (i: INTEGER): V_ARRAY_ITERATOR [G]
			-- New iterator pointing at position `i'.
		note
			status: impure
			explicit: wrapping
		do
			create Result.make (Current, i - lower + 1)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
			-- (Use reference comparison.)
		do
			if other = Current then
				Result := True
			elseif lower = other.lower and upper = other.upper then
				Result := area.same_items (other.area, 0, 0, count)
			end
		end

feature -- Replacement

	put (v: G; i: INTEGER)
			-- Put `v' at position `i'.
		do
			area.put (v, i - lower)
		end

	fill (v: G; l, u: INTEGER)
			-- Put `v' at positions [`l', `u'].
		do
			area.fill_with (v, l - lower, u - lower)
		end

	clear (l, u: INTEGER)
			-- Put default value at positions [`l', `u'].		
		do
			area.fill_with_default (l - lower, u - lower)
		end

	copy_range_within (fst, lst, index: INTEGER)
			-- Copy items within the same array, from the interval [`fst', `lst'] to position `index'.
		note
			modify_model: sequence, Current_
		do
			if lst >= fst then
				area.move_data (fst - lower_, index - lower_, lst - fst + 1)
			end
		end

feature -- Resizing

	resize (l, u: INTEGER)
			-- Set index interval to [`l', `u']; keep values at old indexes; set to default at new indexes.
			-- Reallocate memory unless count stays the same.
		note
			modify_model: sequence, lower_, Current_
		local
			new_count, x, y: INTEGER
		do
			new_count := u - l + 1
			if new_count = 0 then
				wipe_out
			else
				if new_count > area.count then
					area := area.aliased_resized_area_with_default (({G}).default, new_count)
				end

				x := lower.max (l)
				y := upper.min (u)
				if x > y then
					-- No intersection
					area.fill_with_default (0, area.count - 1)
				else
					-- Intersection
					area.move_data (x - lower, x - l, y - x + 1)
					area.fill_with_default (0, x - l - 1)
					area.fill_with_default (y - l + 1, area.count - 1)
				end
				if new_count < area.count then
					area := area.resized_area (new_count)
				end
				lower := l
				upper := u
			end
		end

	include (i: INTEGER)
			-- Resize in a minimal way to include index `i'; keep values at old indexes; set to default at new indexes.
			-- Reallocate memory unless count stays the same.
		note
			modify_model: sequence, lower_, Current_
		do
			if is_empty then
				resize (i, i)
			elseif i < lower then
				resize (i, upper)
			elseif i > upper then
				resize (lower, i)
			end
		end

	force (v: G; i: INTEGER)
			-- Put `v' at position `i'; if position is not defined, include it.
			-- Reallocate memory unless count stays the same.
		note
			modify_model: sequence, lower_, Current_
		do
			include (i)
			put (v, i)
		end

	wipe_out
			-- Remove all elements.
		note
			modify_model: sequence, lower_, Current_
		do
			create area.make_empty (0)
			lower := 1
			upper := 0
		end

feature {V_CONTAINER, V_ITERATOR} -- Implementation

	area: V_SPECIAL [G]
			-- Memory area where elements are stored.

feature -- Specification

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional
		do
			Result := sequence ~ other.sequence and lower_ = other.lower_
		end

invariant
	area_exists: area /= Void
	lower_definition: lower_ = lower
	upper_definition: upper = lower_ + sequence.count - 1
	sequence_implementation: sequence ~ area.sequence

note
	explicit: observers
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
