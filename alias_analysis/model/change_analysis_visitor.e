note
	description: "Summary description for {CHANGE_ANALYSIS_VISITOR}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CHANGE_ANALYSIS_VISITOR

inherit
	ALIAS_ANALYSIS_VISITOR
		redefine
			make,
			process_assign_as,
			alias_graph,
			process_eiffel_list,
			process_create_creation_as
		end

create
	make

feature -- Initialisation (redefinition)

	make (a_routine: PROCEDURE_I; a_statement_observer: like statement_observer)
		do
			Precursor (a_routine, a_statement_observer)
		end

feature -- Redefinition

	alias_graph : CHANGE_GRAPH

	process_assign_as (a_node: ASSIGN_AS)
		do
			--a_node.target.access_name_32
			if
				attached get_alias_info (Void, a_node.target) as l_target and then
				l_target.is_variable and then
				attached get_alias_info (Void, a_node.source) as l_source
			then
				l_target.alias_object := l_source.alias_object
				alias_graph.add_field (l_target.variable_name)

				--if not attached alias_graph.void_type_field (l_target.variable_name) and then attached l_target.alias_object as o  then
				if attached l_target.alias_object as o  then
					--alias_graph.update_type_field (l_target.variable_name, o.type)
					alias_graph.update_type_field (l_target.variable_name, alias_graph.stack_top.current_object.type)
				end
			else
				Io.put_string ("Not yet supported (1): " + code(a_node) + "%N")
			end
		end

	process_eiffel_list (a_node: EIFFEL_LIST [AST_EIFFEL])
		local
			l_cursor: INTEGER
			n : INTEGER
			tmp : STRING
		do
			from
				l_cursor := a_node.index
				a_node.start
			until
				a_node.after
			loop
				if attached a_node.item as l_item then
					if statement_observer /= Void then
						statement_observer.call (l_item, alias_graph)
					end
					--n := alias_graph.change_field.count
					tmp := alias_graph.to_string
					l_item.process (Current)
						-- to check if there is a new change field. If so, add the aliases of it to the alias_graph.change_field
					print ("==before==%N")
					print (tmp)
					print ("%N==after==%N")
					print (alias_graph.to_string)
					print ("%N====%N")
				else
					check False end
				end
				a_node.forth
			end
			a_node.go_i_th (l_cursor)
		end

	process_create_creation_as (a_node: CREATE_CREATION_AS)
		do
			if
				attached get_alias_info (Void, a_node.target) as l_target and then
				l_target.is_variable
			then
				l_target.alias_object := create {ALIAS_OBJECT}.make (l_target.type)
				alias_graph.add_field (l_target.variable_name)

				if attached l_target.alias_object as o  then
					alias_graph.update_type_field (l_target.variable_name, alias_graph.stack_top.current_object.type)
				end
			else
				Io.put_string ("Not yet supported (3): " + code(a_node) + "%N")
			end
		end

note
	copyright: "Copyright (c) 1984-2016, Eiffel Software"
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
