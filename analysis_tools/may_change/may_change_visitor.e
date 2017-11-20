note
	description: "Implements VISITOR to get May change attributes."
	author: "A. Bandura"
	date: "2017"
	revision: "$Revision$"

class
	MAY_CHANGE_VISITOR

inherit

	AST_ITERATOR
		redefine
			process_access_assert_as,
			process_access_feat_as,
			process_routine_as,
			process_if_expression_as,
			process_un_old_as,
			process_nested_as,
			process_access_inv_as,
			process_bin_free_as,
			process_index_as
		end

	SHARED_SERVER

create
	make

feature {NONE}

	make (proc: PROCEDURE_I)
		do
			is_inside_class := TRUE
			routine := proc
			create context_stack.make
			create model_queries_list.make
			create may_change_list.make
			create may_change_query_list.make
		end
	process_access_inv_as (l_as: ACCESS_INV_AS)
		do
		end

	process_index_as (l_as: INDEX_AS)
		local
			l_cursor: INTEGER
			models: EIFFEL_LIST [AST_EIFFEL]
		do
			if l_as.tag.name_8.is_equal ("model") then
				from
					models := l_as.index_list
					l_cursor := models.index
					models.start
				until
					models.after
				loop
					if attached {ID_AS} models.item as l_item and then not model_queries_list.has (l_item.name_8) then
						model_queries_list.extend (l_item.name_8)
					else
--						check
--							False
--						end
					end
					models.forth
				end
				models.go_i_th (l_cursor)
			else
				l_as.index_list.process (CURRENT)
			end
		end

	process_access_feat_as (a_node: ACCESS_FEAT_AS)
		local
			attr: STRING_8
			list: TWO_WAY_LIST [STRING_8]
		do
			if a_node.is_local then
					-- Nothing
			elseif a_node.is_argument and routine.is_function then
				attr := a_node.access_name_8
				list := context_stack.last.list
				if not list.has (attr) then
					list.extend (attr)
				end
			elseif a_node.is_tuple_access then
					-- Nothing
			elseif a_node.is_argument then
					-- Nothing
			elseif is_inside_class and model_queries_list.has (a_node.access_name_8) then
				if not may_change_query_list.has (a_node.access_name_8) then
					may_change_query_list.extend (a_node.access_name_8)
				end
			elseif attached  find_routine (a_node) as l_routine then
				function_handling (a_node)
			else
				if is_inside_class and then not a_node.is_argument and then not may_change_list.has (a_node.access_name_8) then
					may_change_list.extend (a_node.access_name_8)
				end
			end
		end

	function_handling (a_ast: AST_EIFFEL)
		local
			routine_to_process:PROCEDURE_I
			proc: PROCEDURE_I
			context: TUPLE [inside_class: BOOLEAN; list: TWO_WAY_LIST [STRING_8]]
			mapping: HASH_TABLE [STRING_8, STRING_8]
			feat_mapping: HASH_TABLE [AST_EIFFEL, STRING_8]
			expr_as: EXPR_AS
			index: INTEGER
		do
			create feat_mapping.make (16)
			create context.default_create
			create mapping.make (16)
			context.inside_class := is_inside_class
			context.list := create {TWO_WAY_LIST [STRING_8]}.make
			proc := routine
			if attached {ACCESS_FEAT_AS} a_ast as a_node and then attached find_routine (a_node) as l_routine then
				routine := l_routine
				if a_node.internal_parameters /= VOID then
					from
						a_node.internal_parameters.parameters.start
					until
						a_node.internal_parameters.parameters.after
					loop
						expr_as := a_node.internal_parameters.parameters.item
						index := a_node.internal_parameters.parameters.index
						argument_linkage (expr_as, index, feat_mapping, mapping, proc)
						a_node.internal_parameters.parameters.forth
					end
				end
				routine_to_process:= l_routine
			elseif attached {BIN_FREE_AS} a_ast as l_as and then attached find_routine (l_as) as l_routine then
				routine := l_routine
				argument_linkage (l_as.right, 1, feat_mapping, mapping, proc)
				routine_to_process := l_routine
			end
			context_stack.extend (context)
			if routine_to_process.body /= VOID then
				routine_to_process.body.process (Current)
			end
			routine := proc
			inverse_argument_mapping (feat_mapping, mapping)
		end

	process_nested_as (l_as: NESTED_AS)
		do
			if attached {CURRENT_AS} l_as.target as l_feature then
				l_as.message.process (Current)
			else
				l_as.target.process (Current)
				is_inside_class := FALSE
				l_as.message.process (Current)
					-- it might not work with nested calls
				is_inside_class := True
			end
		end

	process_bin_free_as (l_as: BIN_FREE_AS)
		do
			l_as.left.process (Current)
			is_inside_class := FALSE
			function_handling (l_as)
				-- it might not work with nested calls
			is_inside_class := True
		end

	process_access_assert_as (a_node: ACCESS_ASSERT_AS)
		do
			process_access_feat_as (a_node)
		end

	process_if_expression_as (l_as: IF_EXPRESSION_AS)
		do
			l_as.then_expression.process (Current)
			safe_process (l_as.elsif_list)
			l_as.else_expression.process (Current)
		end

	process_un_old_as (l_as: UN_OLD_AS)
		do
		end

	find_routine (a_node: ID_SET_ACCESSOR): PROCEDURE_I
			-- Void for local variables and attributes
		require
			a_node /= Void
		do
			inspect a_node.routine_ids.count
			when 0 then
					-- local variable -> return Void
			else
				if attached {PROCEDURE_I} System.class_of_id (a_node.class_id).feature_of_rout_id (a_node.routine_ids.first) as l_r then
						-- routine
					Result := l_r
				else
						-- attribute -> return Void
				end
			end
		end

	argument_linkage (item: EXPR_AS; index: INTEGER; feat_mapping: HASH_TABLE [AST_EIFFEL, STRING_8]; mapping: HASH_TABLE [STRING_8, STRING_8]; proc: PROCEDURE_I)
		do
			if attached {EXPR_CALL_AS} item as c and then attached {ACCESS_ASSERT_AS} c.call as l_assert_as then
					if (not proc.is_function and l_assert_as.is_argument) then
						feat_mapping.extend (l_assert_as, l_assert_as.access_name_8)
					else
						if find_routine (l_assert_as) /= VOID then
							feat_mapping.extend (l_assert_as, l_assert_as.access_name_8)
						end
					end
					mapping.extend (l_assert_as.access_name_8, routine.arguments.item_name (index))
			else
				feat_mapping.extend (item, formal_argument_name.out)
				mapping.extend (formal_argument_name.out, routine.arguments.item_name (index))
				formal_argument_name := formal_argument_name + 1
			end
		end

	inverse_argument_mapping (feat_mapping: HASH_TABLE [AST_EIFFEL, STRING_8]; mapping: HASH_TABLE [STRING_8, STRING_8])
		local
			attr: STRING_8
			feat_to_process: TWO_WAY_LIST [AST_EIFFEL]
		do
			create feat_to_process.make
			across
				context_stack.last.list as c
			loop
				if is_inside_class and model_queries_list.has (c.item) and not may_change_query_list.has (c.item) and mapping [c.item] = VOID then
					may_change_query_list.extend (c.item)
				elseif is_inside_class and not may_change_list.has (c.item) and mapping [c.item] = VOID then
					may_change_list.extend (c.item)
				end
				if mapping [c.item] /= VOID then
					attr := mapping [c.item]
					if feat_mapping [attr] /= VOID then
						feat_to_process.extend (feat_mapping [attr])
					elseif context_stack.count = 1 and model_queries_list.has(mapping [c.item]) and not may_change_query_list.has (mapping [c.item]) then
						may_change_query_list.extend (mapping [c.item])
					elseif context_stack.count = 1 and not may_change_list.has (mapping [c.item]) then
						may_change_list.extend (mapping [c.item])
					elseif not context_stack.last_element.left.item.list.has (mapping [c.item]) then
						context_stack.last_element.left.item.list.extend (mapping [c.item])
					end
				end
			end
			if context_stack.count = 1 then
				is_inside_class := TRUE
			else
				is_inside_class := context_stack.last_element.left.item.inside_class
			end
			context_stack.finish
			context_stack.remove
			across
				feat_to_process as l_f
			loop
				l_f.item.process (Current)
			end
		end

	process_routine_as (l_as: ROUTINE_AS)
		do
			safe_process (l_as.postcondition)
		end

feature {ANY}

	context_stack: TWO_WAY_LIST [TUPLE [inside_class: BOOLEAN; list: TWO_WAY_LIST [STRING_8]]]

	routine: PROCEDURE_I

	may_change_list: TWO_WAY_LIST [STRING_8]

	may_change_query_list: TWO_WAY_LIST [STRING_8]

	model_queries_list: TWO_WAY_LIST [STRING_8]

	formal_argument_name: INTEGER

	is_inside_class: BOOLEAN





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
