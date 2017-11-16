note
	description: "[
		The visitor gets the modifies clauses of feature
	]"
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-20 18:49:14 +0300 (Fri, 20 Nov 2015) $"
	revision: "$Revision: 98127 $"

class
	MODIFY_CLAUSES_VISITOR

inherit

	AST_ITERATOR
		redefine
			process_feature_as,
			process_index_as,
			process_id_as
		end

	SHARED_SERVER

	TRACING

create
	make

feature {NONE}

	make (a_id_class: INTEGER; a_feature_name: STRING)
		do
			create modify_clause_list.make
			feature_name := a_feature_name
			id_class := a_id_class
		end

feature {ANY}

	modify_clause_list: TWO_WAY_LIST [STRING]
			-- stores the modify clauses for the feature

	id_class: INTEGER

	feature_name: STRING

feature {NONE}

	process_feature_as (a_node: FEATURE_AS)
		do
			safe_process (a_node.indexes)
				-- check whether this is a redefined feature
			if id_class /= -1 then
				across
					System.class_of_id (id_class).parents_classes as parent
				loop
					print (parent.item.name)
					io.new_line
					id_class := parent.item.class_id
					if parent.item.name /~ "ANY" and then attached parent.item.feature_named_32 (feature_name) as feat then
						feat.body.process (Current)
					end
				end
			end
		end

	process_index_as (a_node: INDEX_AS)
		do
			if a_node.tag.name_32 ~ "modify" then
				a_node.index_list.process (Current)
			end
		end

	process_id_as (a_node: ID_AS)
		do
			if across modify_clause_list as lst all lst.item /~ a_node.name_32 end then
				modify_clause_list.force (a_node.name_32)
			end
		end

invariant

note
	copyright: "Copyright (c) 1984-2017, Eiffel Software"
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
