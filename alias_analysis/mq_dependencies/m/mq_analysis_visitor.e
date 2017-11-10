note
	description: "The visitor that computes the MQ list."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-20 18:49:14 +0300 (Fri, 20 Nov 2015) $"
	revision: "$Revision: 98127 $"

class
	MQ_ANALYSIS_VISITOR

inherit

	AST_ITERATOR
		redefine
			process_eiffel_list,
			process_assign_as,
			process_assigner_call_as,
			process_create_creation_as,
			process_instr_call_as,
			process_if_as,
			process_elseif_as,
			process_object_test_as,
			process_loop_as,
			process_routine_as
		end

	SHARED_SERVER

	TRACING

create
	make

feature {NONE}

	make (a_routine: PROCEDURE_I; a_statement_observer: like statement_observer)
		require
			a_routine /= Void
		do
			statement_observer := a_statement_observer
		ensure
			statement_observer = a_statement_observer
		end

feature {ANY}

	mq_list: TWO_WAY_LIST [STRING]
			-- stores the class attributes needed to build a Model Query

	statement_observer: PROCEDURE [ANY, TUPLE [AST_EIFFEL, TWO_WAY_LIST [STRING]]]

feature {NONE}

	process_eiffel_list (a_node: EIFFEL_LIST [AST_EIFFEL])
		local
			l_cursor: INTEGER
		do
			from
				l_cursor := a_node.index
				a_node.start
			until
				a_node.after
			loop
				if attached a_node.item as l_item then
					if statement_observer /= Void then
						statement_call (l_item)
					end
					l_item.process (Current)
				else
					check
						False
					end
				end
				a_node.forth
			end
			a_node.go_i_th (l_cursor)
		end

	statement_call (l: AST_EIFFEL)
			-- makes the call to the agent
		do
			statement_observer.call (l, alias_graph, Void)
		end

	process_routine_as (a_node: ROUTINE_AS)
		do
				-- Note: no need for Alias Analysis safe_process (l_as.precondition)
			safe_process (a_node.internal_locals)
			a_node.routine_body.process (Current)
				-- Note: no need for Alias Analysis safe_process (l_as.postcondition)
				-- Note: no need for Alias Analysis safe_process (l_as.rescue_clause)
		end

	process_assign_as (a_node: ASSIGN_AS)
		do
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable and then attached get_alias_info (Void, a_node.source) as l_source then
				target.alias_object := source.alias_object
			else
				Io.put_string ("Not yet supported (1): " + code (a_node) + "%N")
			end
		end

	process_assigner_call_as (a_node: ASSIGNER_CALL_AS)
		local
			entity_caller: TWO_WAY_LIST [STRING]
		do
				-- foo.bar := baz  ->  handle as: foo.set_bar(baz)
			if attached {EXPR_CALL_AS} a_node.target as l_target1 and then -- foo.bar
				attached {NESTED_AS} l_target1.call as l_target2 and then -- foo.bar
				attached get_alias_info (Void, l_target2.target) as l_foo and then -- foo
				attached {ACCESS_FEAT_AS} l_target2.message as l_bar and then -- bar
					-- TODO 04.11.2016
					--attached l_foo.alias_object as objects and then attached objects.first.type.base_class as l_c and then -- class of bar
				attached l_foo.alias_object.first.type.base_class as l_c and then -- class of bar
				attached l_c.feature_named_32 (l_bar.access_name_32).assigner_name as l_set_bar1 and then -- set_bar
				attached {PROCEDURE_I} l_c.feature_named_32 (l_set_bar1) as l_set_bar2 and then -- set_bar
				l_set_bar2.argument_count = 1
			then
				across
					l_foo.alias_object as aliases
				loop
					create entity_caller.make
					entity_caller.force (l_foo.variable_name)
					aliases.item.add_entity (entity_caller, alias_graph.stack_top.locals)
					call_routine_with_arg (aliases.item, l_set_bar2, a_node.source).do_nothing
				end
			elseif
					-- foo [bar] := baz
				attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo and then attached find_routine (l_target2) as l_bar and then attached l_foo.alias_object.first.type.base_class as l_c and then attached l_c.feature_named_32 (l_bar.e_feature.name_32).assigner_name as l_set_bar1 and then attached {PROCEDURE_I} l_c.feature_named_32 (l_set_bar1) as l_set_bar2
			then
				call_routine_with_arg (aliases.item, l_set_bar2, a_node.source).do_nothing
			else
				Io.put_string ("Not yet supported (2): " + code (a_node) + "%N")
			end
		end

	process_create_creation_as (a_node: CREATE_CREATION_AS)
		do
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable then
					if attached a_node.call then
							get_alias_info (aliases.item, a_node.call).do_nothing
						else
								-- call default_create procedure
							if attached System.eiffel_universe.classes_with_name (l_target.alias_object.first.type.name) as l_classes and then l_classes.count = 1 and then attached {PROCEDURE_I} System.class_of_id (l_classes.first.compiled_class.class_id).feature_of_rout_id (System.class_of_id (l_classes.first.compiled_class.class_id).creation_feature.e_feature.rout_id_set.first) as l_r then
								call_routine (aliases.item, l_r, Void).do_nothing
							end
						end
					end
				end
			else
				Io.put_string ("Not yet supported (3): " + code (a_node) + "%N")
			end
		end

	process_instr_call_as (a_node: INSTR_CALL_AS)
		do
			get_alias_info (Void, a_node.call).do_nothing
		end

	process_elseif_as (a_node: ELSIF_AS)
		do
				-- TODO: to check the condition
			a_node.expr.process (Current)
			safe_process (a_node.compound)
		end

	process_if_as (a_node: IF_AS)
		do
				-- TODO: to check the condition

			a_node.condition.process (Current)
			safe_process (a_node.compound)
			safe_process (a_node.elsif_list)
			safe_process (a_node.else_part)
			alias_graph.finalising_cond
		end

	process_loop_as (a_node: LOOP_AS)
		do
			-- TODO: to check the condition
			safe_process (a_node.iteration)
			safe_process (a_node.from_part)
			safe_process (a_node.invariant_part)
			safe_process (a_node.stop)
			safe_process (a_node.compound)
		end

	process_object_test_as (a_node: OBJECT_TEST_AS)
		do
				-- TODO only keep it in its scope
			if a_node.name /= Void then
				if attached get_alias_info (Void, a_node.expression) as l_expression then
					(create {ALIAS_OBJECT_INFO}.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_node.name.name_8)).alias_object := l_expression.alias_object
				else
					Io.put_string ("Not yet supported (4): " + code (a_node) + "%N")
				end
			end
		end

feature {NONE} -- utilities

	store_info (a_node: AST_EIFFEL)
			-- analyses `a_node' and stores the corresponding information
		require
			a_node /= Void
		do
			if attached {ACCESS_FEAT_AS} a_node as l_node then
				if l_node.is_local or l_node.is_argument or l_node.is_object_test_local then
						-- check is l_node.is_local is already created in the graph
					if not alias_graph.stack_top.locals.has (create {ALIAS_KEY}.make (l_node.access_name_32)) then
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_node.class_id)))
						alias_graph.stack_top.locals.force (l_obj, create {ALIAS_KEY}.make (l_node.access_name_32))
					end
					create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, l_node.access_name_8)
				elseif l_node.is_tuple_access then
						-- TODO
				elseif attached find_routine (l_node) as l_routine then
						-- routine

					Result := process_routine (a_target, l_routine, l_node.class_id, if attached l_node.parameters as params then params else create {EIFFEL_LIST [EXPR_AS]}.make (0) end)
				else
						-- attribute
					create Result.make_variable (alias_graph.stack_top.routine, (if a_target /= Void then a_target else alias_graph.stack_top.current_object end).attributes, l_node.access_name_8)
				end
			elseif attached {PRECURSOR_AS} a_node as l_node then
				if attached find_routine (l_node) as l_routine then
					Result := process_routine (a_target, l_routine, l_node.class_id, if attached l_node.parameters as params then params else create {EIFFEL_LIST [EXPR_AS]}.make (0) end)
				end
			elseif attached {NESTED_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.target) as l_target and then l_target.is_variable then
					if attached l_target.alias_object as objs and then objs.count > 0 and then (objs.first.type.is_basic or objs.first.is_string) then
						if objs.first.type.is_basic and then attached System.eiffel_universe.classes_with_name (objs.first.type.name) as l_classes and then l_classes.count > 0 then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
							create Result.make_object (l_obj)
						else
							create Result.make_object (objs)
						end
					else
						across
							l_target.alias_object as aliasses
						loop
							Result := get_alias_info (aliasses.item, l_node.message)
						end
					end
				end
			elseif attached {BINARY_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.left) as l_target and then attached find_routine (l_node) as l_routine then
						-- there is not need to go further if the operation is on Basic Types
					if attached l_target.alias_object as objs and then objs.count > 0 and then objs.first.type.is_basic then
						call_routine_with_arg (aliases.item, l_routine, l_node.right)
					end
				end
			elseif attached {BRACKET_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.target) as l_target and then attached find_routine (l_node) as l_routine then
					Result := call_routine (aliasses.item, l_routine, l_node.operands)
			elseif attached {EXPR_CALL_AS} a_node as l_node then
				Result := get_alias_info (a_target, l_node.call)
			elseif attached {NESTED_EXPR_AS} a_node as l_node then
				get_alias_info (aliases.item, l_node.message)
			elseif attached {PARAN_AS} a_node as l_node then
				Result := get_alias_info (a_target, l_node.expr)
			elseif attached {CONVERTED_EXPR_AS} a_node as l_node then
				stop (9)
				Result := get_alias_info (a_target, l_node.expr)
			end
		end

	process_routine (a_routine: PROCEDURE_I; a_class_id: INTEGER; a_parameters: EIFFEL_LIST [EXPR_AS]): ALIAS_OBJECT_INFO
			-- process routine `a_routine' on target `a_target'.
			-- `a_class_id' is needed to get the type and `a_parameters' to call the routine
		do
			Result := call_routine (a_routine, a_parameters)
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
					--if attached {PROCEDURE_I} System.class_of_id (a_node.class_id).feature_of_rout_id (a_node.routine_ids.first) as l_r then
				if attached {PROCEDURE_I} System.class_of_id (a_node.class_id).feature_of_rout_id (a_node.routine_ids.first) as l_r then
						-- routine
					Result := l_r
				else
						-- attribute -> return Void
				end
			end
		end

	call_routine_with_arg (a_routine: PROCEDURE_I; a_arg: EXPR_AS): ALIAS_OBJECT_INFO
		require
			a_routine /= Void
			a_arg /= Void
		local
			l_params: EIFFEL_LIST [EXPR_AS]
		do
			create l_params.make (1)
			l_params.extend (a_arg)
			Result := call_routine (a_routine, l_params)
		end

	call_routine (a_routine: PROCEDURE_I; a_params: EIFFEL_LIST [EXPR_AS]): ALIAS_OBJECT_INFO
		require
			a_routine /= Void
		do
			create l_params.make
				if a_params /= Void then
					across
						a_params as c
					loop
						l_params.extend (get_alias_info (Void, c.item))
		end
				end
				across
					l_params as c
				loop
					(create {ALIAS_OBJECT_INFO}.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))).alias_object := c.item.alias_object
				end




					--				across
					--					l_params as c
					--				loop
					--					create formal_param.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))
					--					if not attached formal_param.alias_object or else (attached formal_param.alias_object as target and then not target.first.type.is_expanded) then
					--							-- updating sets Additions and Deletions used to restore the Graph after recursion
					--						stop (12)
					--						alias_graph.updating_graph (formal_param, c.item)
					--					end
					--					--formal_param.alias_object := c.item.alias_object
					--						(create {ALIAS_OBJECT_INFO}.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))).alias_object := c.item.alias_object
					--				end

					--alias_graph.stack_push (if a_target /= Void then a_target else alias_graph.stack_top.current_object end, a_routine, if a_target /= Void then a_target.entity else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end, if a_target /= Void then a_target.entity_locals else create {TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]}.make end, a_target /= Void)
				a_routine.body.process (Current)
				end
				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, "Result")
			end
		end

	code (a_node: AST_EIFFEL): STRING_32
		require
			a_node /= Void
		local
			l_pretty_printer: PRETTY_PRINTER
		do
			create Result.make_empty
			create l_pretty_printer.make (create {PRETTY_PRINTER_OUTPUT_STREAM}.make_string (Result))
			l_pretty_printer.setup (alias_graph.stack_top.routine.written_class.ast, Match_list_server.item (alias_graph.stack_top.routine.written_class.class_id), True, True)
			l_pretty_printer.process_ast_node (a_node)
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
