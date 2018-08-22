note
	description: "[
		Represents an edge in the Graph.
		It is the tuple (a, b, c) where
		'a' is a target
		'b' is the tag
		'c' is a list of all sources
	]"
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_EDGE


create
	make

feature -- Initialisation
	make (a_target: ALIAS_VISITABLE; a_sources: TWO_WAY_LIST [ALIAS_OBJECT]; name: STRING)
		do
			target := a_target

			create sources.make
			across
				a_sources as s
			loop
				sources.force (s.item)
			end

			tag := name
		end

feature -- Printing
	out_edge: STRING
		do
			Result := "(" + target.out2 + ", " + tag + ", <<"

			across
				sources as s
			loop
				Result := Result + s.item.out2
				if not s.is_last then
					Result := Result + ", "
				end
			end
			Result := Result + ">> "

		end
feature -- Interface
	is_equal_edge (other: like Current): BOOLEAN
		do
			Result := tag ~ other.tag and target.is_equal (other.target)
		end

	is_deep_equal_edge (other: like Current): BOOLEAN
		do
			Result := is_equal_edge (other) and sources.count = other.sources.count and
					across
						1 |..| sources.count as i
					all
						sources.at (i.item).is_equal (other.sources.at (i.item))
					end
		end

feature -- ACCESS
	target: ALIAS_VISITABLE
	sources: TWO_WAY_LIST [ALIAS_OBJECT]
	tag: STRING


invariant



note
	copyright: "Copyright (c) 1984-2018, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"

end
