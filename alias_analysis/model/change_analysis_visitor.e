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
			statement_call--,
--			process_assign_as,
--			alias_graph,
--			process_eiffel_list,
--			process_create_creation_as
		end

create
	make

feature {NONE} -- Initialisation
	make (a_routine: PROCEDURE_I; a_statement_observer: like statement_observer)
		do
			create change_graph.make (a_routine)
			Precursor (a_routine, a_statement_observer)
		end

feature -- Redefinition
	statement_call (l: AST_EIFFEL)
			-- from {ALIAS_ANALYSIS_VISITOR}
		do
			statement_observer.call (l, alias_graph, change_graph)
		end

feature {ANY}
	change_graph: CHANGE_GRAPH
			-- stores all the information of Change Analysis


;note
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
