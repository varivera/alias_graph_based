note
	description: "[
		The visitor that computes the alias state.
		It implements a visitor for the Eiffel AST and computes the Alias Graph based on 
		the calculus
	]"
	date: "August, 2018"
	author: "Victor Rivera"

class
	ALIAS_ANALYSIS_VISITOR

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
			process_routine_as,
			process_feature_as
		end

	SHARED_SERVER

	TRACING

create
	make

feature {NONE}

	make (a_routine: PROCEDURE_I)
		require
			a_routine /= Void
		do
			create alias_graph.make (a_routine)
		end

feature {ANY}

	alias_graph: ALIAS_GRAPH
			-- structure that contains the alias graph.

feature {NONE}

	process_eiffel_list (a_node: EIFFEL_LIST [AST_EIFFEL])
			-- process each instruction
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

	process_feature_as (a_node: FEATURE_AS)
				-- from {AST_ITERATOR}
		do
			a_node.feature_names.process (Current)
			safe_process (a_node.indexes)
			a_node.body.process (Current)
		end

	process_routine_as (a_node: ROUTINE_AS)
				-- from {AST_ITERATOR}
		do
				-- Note: no need for Alias Analysis safe_process (l_as.precondition)
			safe_process (a_node.internal_locals)
			a_node.routine_body.process (Current)
				-- Note: no need for Alias Analysis safe_process (l_as.postcondition)
				-- Note: no need for Alias Analysis safe_process (l_as.rescue_clause)

				-- check if this is the end of the initial routine. If so
				-- perform finalise routine in case of recursion

				-- if it is not the last routine in the STACK, transfer additions and deletions
			if alias_graph.is_last_routine then
				alias_graph.finalising_initial_routine
			end
		end

	process_assign_as (a_node: ASSIGN_AS)
				-- from {AST_ITERATOR}
		local
			target_edge: ALIAS_VISITABLE
			found: BOOLEAN
		do
			if attached get_alias_info (Void, a_node.target) as l_target then

					-- Ignoring MML actions and POINTER
				if attached l_target.alias_object as ao implies
					(ao.count > 0 and (
									not ao.first.out.has_substring ("MML")
								and
									not ao.first.out.has_substring ("POINTER")))
				then
						-- check if the target is an expanded type (do nothing if so)
					if not attached l_target.alias_object or else (attached l_target.alias_object as target and then not target.first.type.is_expanded) then
						if l_target.is_variable and then attached get_alias_info (Void, a_node.source) as l_source then
							if attached l_source.variable_map as map and then not map.has (create {ALIAS_KEY}.make (l_source.variable_name)) then
								map.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, create {ALIAS_KEY}.make (l_source.variable_name))
								map.at (create {ALIAS_KEY}.make (l_source.variable_name)).force (
														create {ALIAS_OBJECT}.make
															(
																l_target.variable_map.at
																(create {ALIAS_KEY}.make (l_target.variable_name)).first.type)
															)
								check not attached l_source.alias_object then
									l_source.set_direct_alias_object (map.at (create {ALIAS_KEY}.make (l_source.variable_name)))
								end
							end
							if alias_graph.stack_top.current_object.attributes.has (
													create {ALIAS_KEY}.make (l_target.variable_name))
							then
								target_edge := alias_graph.stack_top.current_object
							else -- is in locals
								target_edge := alias_graph.stack_top
							end
								-- updating sets Additions and Deletions used to restore the Graph after a conditional branch, loop body and recursion
							alias_graph.current_routine.registering_changes (
										target_edge,
										if attached l_source.variable_map as map then
											map.at (create {ALIAS_KEY}.make (l_source.variable_name))
										else
											l_source.alias_object
										end,
										l_target.variable_map.at (create {ALIAS_KEY}.make (l_target.variable_name)),
										l_target.variable_name)
							assigning (l_target, l_source)
						else
							--Io.put_string ("Not yet supported (1): " + code (a_node) + "%N")
						end
					else
						from
							alias_graph.stack_top.current_object.attributes.start
						until
							alias_graph.stack_top.current_object.attributes.after or found
						loop
							if alias_graph.stack_top.current_object.attributes.key_for_iteration.name ~ l_target.variable_name then
								alias_graph.stack_top.current_object.attributes.key_for_iteration.set_assigned
								found := true
							else
								alias_graph.stack_top.current_object.attributes.forth
							end
						end
					end
				else
				end
			else
				--Io.put_string ("Ignoring non references%N")
			end
		end

	assigning (target, source: ALIAS_OBJECT_INFO)
			-- assigns objects of `source' to `target' objects
		local
			found: BOOLEAN -- check cursors for HASH_TABLEs
		do
			from
				alias_graph.stack_top.current_object.attributes.start
			until
				alias_graph.stack_top.current_object.attributes.after or found
			loop
				if alias_graph.stack_top.current_object.attributes.key_for_iteration.name ~ target.variable_name then
					alias_graph.stack_top.current_object.attributes.key_for_iteration.set_assigned
					found := true
				else
					alias_graph.stack_top.current_object.attributes.forth
				end
			end


			target.set_switch_normal
			target.alias_object := source.alias_object
		end


	process_assigner_call_as (a_node: ASSIGNER_CALL_AS)
				-- from {AST_ITERATOR}
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
					call_routine_with_arg (aliases.item, l_set_bar2, a_node.source).do_nothing
				end
			elseif
					-- foo [bar] := baz
				attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo and then attached find_routine (l_target2, l_foo.alias_object.first) as l_bar and then attached l_foo.alias_object.first.type.base_class as l_c and then attached l_c.feature_named_32 (l_bar.e_feature.name_32).assigner_name as l_set_bar1 and then attached {PROCEDURE_I} l_c.feature_named_32 (l_set_bar1) as l_set_bar2
			then
				across
					l_foo.alias_object as aliases
				loop
					call_routine_with_arg (aliases.item, l_set_bar2, a_node.source).do_nothing
				end
			else
				Io.put_string ("Not yet supported (2): " + code (a_node) + "%N")
			end
		end


	process_create_creation_as (a_node: CREATE_CREATION_AS)
				-- from {AST_ITERATOR}
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			target_edge: ALIAS_VISITABLE
			old_object: ALIAS_OBJECT_INFO
		do
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable then
					-- ignore MML actions
				if attached l_target.alias_object as ao implies
				(ao.count > 0 and (
									not ao.first.out.has_substring ("MML")
								and
									not ao.first.out.has_substring ("POINTER"))) then



					-- February 6th 2018
					--old_alias_info := l_target.deep_twin
					-- February 6th 2018

						--create old_object.make
					if attached l_target.alias_object as objects then
						create old_object.make_object (objects)
					end
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))

					l_target.set_switch_normal
					l_target.alias_object := l_obj

					if alias_graph.stack_top.current_object.attributes.has (
											create {ALIAS_KEY}.make (l_target.variable_name))
					then
						target_edge := alias_graph.stack_top.current_object
					else -- is in locals
						target_edge := alias_graph.stack_top
					end
					-- updating sets Additions and Deletions used to restore the Graph after a conditional branch, loop body and recursion
					alias_graph.current_routine.registering_changes (
								target_edge,
								l_target.alias_object,
								old_object.alias_object,
								l_target.variable_name)

					-- February 6th 2018

					--alias_graph.updating_graph (old_alias_info, l_target)

					-- February 6th 2018
					across
						l_target.alias_object as aliases
					loop
						if not l_target.alias_object.first.is_string
							and not l_target.alias_object.first.out.has_substring ("STRING")
						then
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

					across
						alias_graph.stack_top.current_object.attributes.current_keys as k
					loop
						if k.item.name ~ l_target.variable_name then
							k.item.set_assigned
						end
					end
				end
			else
				Io.put_string ("Not yet supported (3): " + code (a_node) + "%N")
			end
		end

	process_instr_call_as (a_node: INSTR_CALL_AS)
				-- from {AST_ITERATOR}
		do
			if attached get_alias_info (Void, a_node.call) as call then
				call.do_nothing
			else
				--print ("Ignoring Void calls%N")
			end

		end

	process_elseif_as (a_node: ELSIF_AS)
				-- from {AST_ITERATOR}
		do
				-- Aliasing does not make any assuption about the condition in a conditional
			a_node.expr.process (Current)
			alias_graph.current_routine.init_cond_branch
			safe_process (a_node.compound)
			alias_graph.restore_graph
		end

	assert_condition (cond: EXPR_AS): detachable CELL [BOOLEAN]
			-- it analyses the condition. If it is possible to assert it
			-- ir returns True or False, Void otherwise
			-- basic cases are handled:
			--			if a = b then
			--			if a /= b then
			-- where a and b are class variables. TODO: to extend
			-- the analysis. The implmentation accepts paths.
		local
			var1, var2: STRING
			aliased: ARRAYED_LIST [BOOLEAN]
		do
				-- for a /= b
			if attached {BIN_NE_AS} cond as c then
				if attached {BINARY_AS} c as bin then
					if attached {EXPR_CALL_AS} bin.left as left then
						if attached {ACCESS_ID_AS} left.call as l then
							var1 := l.access_name_32
						end
					end
					if attached {EXPR_CALL_AS} bin.right as right then
						if attached {ACCESS_ID_AS} right.call as r then
							var2 := r.access_name_32
						end
					end
				end
				if not var1.is_empty and not var2.is_empty  then
					aliased := alias_graph.are_paths_aliased (<<var1>>, <<var2>>)

					if aliased[1] and not aliased[2] then
						-- It is not possible to assert the condition
						do_nothing
					elseif aliased[1] then
						create Result.put (False)
					else
						create Result.put (True)
					end
				end
				-- for a = b
			elseif attached {BIN_EQ_AS} cond as c then
				if attached {BINARY_AS} c as bin then
					if attached {EXPR_CALL_AS} bin.left as left then
						if attached {ACCESS_ID_AS} left.call as l then
							var1 := l.access_name_32
						end
					end
					if attached {EXPR_CALL_AS} bin.right as right then
						if attached {ACCESS_ID_AS} right.call as r then
							var2 := r.access_name_32
						end
					end
				end
				if not var1.is_empty and not var2.is_empty  then
					aliased := alias_graph.are_paths_aliased (<<var1>>, <<var2>>)

					if aliased[1] and not aliased[2] then
						-- It is not possible to assert the condition
						do_nothing
					elseif aliased[1] then
						create Result.put (True)
					else
						create Result.put (False)
					end
				end
			end

		end

	process_if_as (a_node: IF_AS)
				-- from {AST_ITERATOR}
		local
			assert_cond: detachable CELL [BOOLEAN]
		do
				-- Alias Analysis does not take into account the condition. However,
				-- it might be an object test with definition of a
				-- fresh variable (hence, the need of processing it)

			assert_cond := assert_condition (a_node.condition)

			if tracing then
				print (assert_cond)
			end
			if assert_cond = Void then
				a_node.condition.process (Current)
			end

			alias_graph.current_routine.init_cond
			alias_graph.current_routine.init_cond_branch

			if attached assert_cond as cond implies cond.item then
				safe_process (a_node.compound)
				alias_graph.restore_graph
			end

			if a_node.elsif_list /= Void then
				assert_cond := Void
			end
			safe_process (a_node.elsif_list)
			alias_graph.current_routine.init_cond_branch

			if attached assert_cond as cond implies not cond.item then
				safe_process (a_node.else_part)
					--Note: no need to restore the graph: alias_graph.restore_graph
				alias_graph.restore_graph
			end
			alias_graph.current_routine.finalising_cond
		end

	process_loop_as (a_node: LOOP_AS)
		do
			safe_process (a_node.iteration)
			safe_process (a_node.from_part)
			--safe_process (a_node.invariant_part)
			--safe_process (a_node.stop)
				-- initialiase a loop iteration and repeat the body of the loop until reaching the fixpoint
			from
				alias_graph.current_routine.init_loop
			until
				alias_graph.current_routine.fixpoint_reached > 0
			loop
				alias_graph.current_routine.iter
				safe_process (a_node.compound)
				alias_graph.current_routine.checking_fixpoint
			end

			alias_graph.current_routine.finalising_loop
				--			safe_process (a_node.variant_part)
		end

	process_object_test_as (a_node: OBJECT_TEST_AS)
				-- from {AST_ITERATOR}
		local
			aoi: ALIAS_OBJECT_INFO
			ao: ALIAS_OBJECT
			key: ALIAS_KEY
		do
				-- TODO only keep it in its scope
			if a_node.name /= Void then
				if attached get_alias_info (Void, a_node.expression) as l_expression then
					create key.make (a_node.name.name_32)
					alias_graph.stack_top.locals.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, key)
					create ao.make (l_expression.alias_object.first.type)
					ao.add_predecessor (alias_graph.current_routine, a_node.name.name_32)
					alias_graph.stack_top.locals.at (key).force (ao)

					create aoi.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_node.name.name_32)
					aoi.set_switch_normal
					aoi.alias_object := l_expression.alias_object
				else
					Io.put_string ("Not yet supported (4): " + code (a_node) + "%N")
				end
			end
		end

feature {NONE} -- utilities

	show_graph (name: STRING)
			-- depicts the graph
		do
			(create {TRACING}.plot_name (alias_graph.to_graph, name)).do_nothing
		end

	get_alias_info (a_target: ALIAS_OBJECT; a_node: AST_EIFFEL): ALIAS_OBJECT_INFO
				-- builds the Alias information according to the type of node visited (`a_node').
				-- `a_target' is the alias object that the current call comes from. Void in case of
				-- unqualified calls.
		require
			a_node /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			l_o: ALIAS_OBJECT
			obj_key: ALIAS_KEY
		do
			if attached {VOID_AS} a_node as l_node then
					--create Result.make_void
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make_void)
				create Result.make_object (l_obj)
			elseif attached {STRING_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.string_8_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {CHAR_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.character_8_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {INTEGER_AS} a_node or attached {BIN_PLUS_AS} a_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.integer_32_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {BOOL_AS} a_node or attached {UN_NOT_AS} a_node or attached {BIN_OR_AS} a_node or attached {BIN_AND_AS} a_node or attached {BIN_EQ_AS} a_node or attached {BIN_TILDE_AS} a_node or attached {BIN_AND_THEN_AS} a_node or attached {BIN_OR_ELSE_AS} a_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.boolean_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {CURRENT_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (alias_graph.stack_top.current_object)
				create Result.make_object (l_obj)
			elseif attached {CREATE_CREATION_EXPR_AS} a_node as l_node then
				if attached {CLASS_TYPE_AS} l_node.type as l_type and then attached System.eiffel_universe.classes_with_name (l_type.class_name.name_8) as l_classes and then l_classes.count = 1 then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
					create Result.make_object (l_obj)
				end
			elseif attached {RESULT_AS} a_node as l_node then
				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, "Result")
			elseif attached {ACCESS_FEAT_AS} a_node as l_node then
				if l_node.is_local or l_node.is_argument or l_node.is_object_test_local then
						-- check is l_node.is_local is already created in the graph
					if not alias_graph.stack_top.locals.has (create {ALIAS_KEY}.make (l_node.access_name_32)) then
						create l_obj.make
						create l_o.make (create {CL_TYPE_A}.make (l_node.class_id))
						create obj_key.make (l_node.access_name_32)
						l_o.predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, obj_key)
						if attached a_target as target then
							l_o.predecessors.at (obj_key).force (target)
						else
							--l_o.predecessors.at (obj_key).force (alias_graph.stack_top.current_object)
							l_o.predecessors.at (obj_key).force (alias_graph.stack_top)
						end
						l_obj.force (l_o)
						alias_graph.stack_top.locals.force (l_obj, obj_key)
					end
					create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, l_node.access_name_8)
				elseif l_node.is_tuple_access then
						-- TODO
				elseif attached find_routine (l_node, a_target) as l_routine then
						-- routine
					Result := process_routine (a_target, l_routine, l_node.class_id, if attached l_node.parameters as params then params else create {EIFFEL_LIST [EXPR_AS]}.make (0) end)
				elseif attached {STATIC_ACCESS_AS} l_node as s_node then
					create obj_key.make (s_node.class_type.dump)
					if not alias_graph.static_access.locals.has (obj_key) then
						alias_graph.add_class_constant (s_node.class_type.dump, l_node.class_id)

					end
					create Result.make_variable (alias_graph.stack_top.routine,
								alias_graph.static_access.locals.at (obj_key).first.attributes,
								l_node.access_name_32)
				else

					create obj_key.make (l_node.access_name_32)
					if attached a_target as target then
						if not target.attributes.has (obj_key) then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (
									target.type.base_class.feature_named_32 (l_node.access_name_32).type))
							l_obj.last.add_predecessor (target, l_node.access_name_32)
							target.attributes.force (l_obj, obj_key)
						end
					elseif not alias_graph.current_routine.current_object.attributes.has (obj_key) then
						create l_obj.make
						if alias_graph.current_routine.det_atts.at (l_node.access_name_32) then
							l_obj.force (create {ALIAS_OBJECT}.make_void)
						else
							l_obj.force (create {ALIAS_OBJECT}.make (
								alias_graph.current_routine.current_object.type.base_class.feature_named_32 (l_node.access_name_32).type))
						end
						l_obj.last.add_predecessor (alias_graph.current_routine.current_object, l_node.access_name_32)
						alias_graph.current_routine.current_object.attributes.force (l_obj, obj_key)
					end
						-- attribute
					create Result.make_variable (alias_graph.stack_top.routine, (if a_target /= Void then a_target else alias_graph.stack_top.current_object end).attributes, l_node.access_name_8)
				end
			elseif attached {PRECURSOR_AS} a_node as l_node then
				if attached find_routine (l_node, Void) as l_routine then
					Result := process_routine (a_target, l_routine, l_node.class_id, if attached l_node.parameters as params then params else create {EIFFEL_LIST [EXPR_AS]}.make (0) end)
				end
			elseif attached {NESTED_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.target) as l_target and then l_target.is_variable then
					if l_target.alias_object = Void then
							-- target doesn't exist yet (e.g. expanded type) -> create
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
						l_target.set_switch_normal
						l_target.alias_object := l_obj
					end
					if attached l_target.alias_object as objs and then objs.count > 0
							and then (objs.first.type.is_basic
									or objs.first.is_string
									or objs.first.out.has_substring ("STRING")) then
						if objs.first.type.is_basic and then attached System.eiffel_universe.classes_with_name (objs.first.type.name) as l_classes and then l_classes.count > 0 then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
							create Result.make_object (l_obj)
						else
							create Result.make_object (objs)
						end
					elseif attached {ROUTINE} l_target then
							-- TODO HW
							do_nothing
					else
						across
							1 |..| l_target.alias_object.count as aliasses
							--l_target.alias_object as aliasses
						loop
							--if not attached {VOID_A} aliasses.item.type  then
							if not attached {VOID_A} l_target.alias_object.at (aliasses.item).type  then
								--Result := get_alias_info (aliasses.item, l_node.message)
								Result := get_alias_info (l_target.alias_object.at (aliasses.item), l_node.message)
							end
						end
					end
				end
			elseif attached {NESTED_EXPR_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.target) as l_target and then l_target.is_variable then
					if l_target.alias_object = Void then
							-- target doesn't exist yet (e.g. expanded type) -> create
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
						l_target.set_switch_normal
						l_target.alias_object := l_obj
					end
					if attached l_target.alias_object as objs and then objs.count > 0 and then (objs.first.type.is_basic or objs.first.is_string) then
						if objs.first.type.is_basic and then attached System.eiffel_universe.classes_with_name (objs.first.type.name) as l_classes and then l_classes.count > 0 then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
							create Result.make_object (l_obj)
						else
							create Result.make_object (objs)
						end
					elseif attached {ROUTINE} l_target then
						-- TODO
						do_nothing
					else
						across
							1 |..| l_target.alias_object.count as aliasses
							--l_target.alias_object as aliasses
						loop
							--if not attached {VOID_A} aliasses.item.type  then
							if not attached {VOID_A} l_target.alias_object.at (aliasses.item).type  then
								--Result := get_alias_info (aliasses.item, l_node.message)
								Result := get_alias_info (l_target.alias_object.at (aliasses.item), l_node.message)
							end
						end
					end
				end
			elseif attached {BINARY_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.left) as l_target and then attached find_routine (l_node, l_target.alias_object.first) as l_routine then
						-- there is not need to go further if the operation is on Basic Types
					if attached l_target.alias_object as objs and then objs.count > 0 and then objs.first.type.is_basic then
						if attached System.eiffel_universe.classes_with_name (objs.first.type.name) as l_classes and then l_classes.count > 0 then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
							create Result.make_object (l_obj)
						end
					else
						across
							l_target.alias_object as aliases
						loop
							if not attached {VOID_A} aliases.item.type  then
								Result := call_routine_with_arg (aliases.item, l_routine, l_node.right)
							end
						end
					end
				end
			elseif attached {BRACKET_AS} a_node as l_node then
				if attached get_alias_info (a_target, l_node.target) as l_target and then attached find_routine (l_node, l_target.alias_object.first) as l_routine then
					if l_target.alias_object = Void then
							-- target doesn't exist yet (e.g. expanded type) -> create
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
						l_target.set_switch_normal
						l_target.alias_object := l_obj
					end
					across
						l_target.alias_object as aliasses
					loop
							-- check for "hack": special routines that do not need to be analysed
						if l_routine.e_feature.name_32 ~ "default_value" and across System.eiffel_universe.classes_with_name ("V_DEFAULT") as ancestor some System.class_of_id (l_node.class_id).inherits_from (ancestor.item.compiled_class) end then
							if attached l_routine.e_feature.type as type then
								create l_obj.make
								l_obj.force (create {ALIAS_OBJECT}.make (type))
								create Result.make_object (l_obj)
							else
									-- TODO
							end
						elseif l_routine.e_feature.name_32 ~ "print" then
								--create Result.make_void
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make_void)
							create Result.make_object (l_obj)
						else
							if not attached {VOID_A} aliasses.item.type  then
								Result := call_routine (aliasses.item, l_routine, l_node.operands)
							end
						end
					end
				end
			elseif attached {EXPR_CALL_AS} a_node as l_node then
				Result := get_alias_info (a_target, l_node.call)
--			elseif attached {NESTED_EXPR_AS} a_node as l_node then
--				if attached get_alias_info (a_target, l_node.target) as l_target then
--					across
--						l_target.alias_object as aliases
--					loop
--						if not attached {VOID_A} aliases.item.type  then
--							Result := get_alias_info (aliases.item, l_node.message)
--						end
--					end
--				end
			elseif attached {PARAN_AS} a_node as l_node then
				Result := get_alias_info (a_target, l_node.expr)
			elseif attached {TYPE_EXPR_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.type_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
					-- Note (17.2.17) No need to call get_alias_info (a_target, l_node.type)
			elseif attached {CLASS_TYPE_AS} a_node as l_node then
					-- TODO
			elseif attached {AGENT_ROUTINE_CREATION_AS} a_node as l_node then
					-- TODO
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.function_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {CONVERTED_EXPR_AS} a_node as l_node then
				Result := get_alias_info (a_target, l_node.expr)
			end
			if Result = Void then
				if attached a_node then
					Io.put_string ("%N---> " + code (a_node) + " -> " + a_node.generator + "%N")
				else
					Io.put_string ("%N|---> a_node: Void -> %N")
				end
			end
		end

	process_routine (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_class_id: INTEGER; a_parameters: EIFFEL_LIST [EXPR_AS]): ALIAS_OBJECT_INFO
			-- process routine `a_routine' on target `a_target'.
			-- `a_class_id' is needed to get the type and `a_parameters' to call the routine
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			dyn_ana: BOOLEAN
		do
				-- check for "hack": special routines that do not need to be analysed
			if
				a_routine.e_feature.name_32 ~ "default_value" and across System.eiffel_universe.classes_with_name ("V_DEFAULT") as ancestor some System.class_of_id (a_class_id).inherits_from (ancestor.item.compiled_class) end
			then
				if attached a_routine.e_feature.type as type then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (type))
					create Result.make_object (l_obj)
				else
						-- TODO
				end
			elseif a_routine.e_feature.name_32 ~ "call" then
					-- TODO HW
				if attached a_routine.e_feature.type as type then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (type))
					create Result.make_object (l_obj)
				else
						-- TODO
				end
			elseif a_routine.e_feature.name_32 ~ "hash_code" and across System.eiffel_universe.classes_with_name ("V_REFERENCE_HASHABLE") as ancestor some System.class_of_id (a_class_id).inherits_from (ancestor.item.compiled_class) end then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.integer_32_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif a_routine.e_feature.name_32 ~ "print" then
					--create Result.make_void
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make_void)
				create Result.make_object (l_obj)
			else
				if a_routine.argument_count = a_parameters.count then
						-- check if there are several versions
					-- TODO: not checking dynamic binding right now
					if false and attached a_target as target and then
							-- this is indeed a qualified call
						-- System.eiffel_universe.classes_with_name (target.type.name) -> System.eiffel_universe.classes_with_name (target.type.name.as_upper)???
						attached System.eiffel_universe.classes_with_name (target.type.name.as_upper) as l_classes and then l_classes.count > 0
					then
						if l_classes.first.compiled_class.direct_descendants.count >= 1 then
							across
								l_classes.first.compiled_class.direct_descendants as descendant
							loop
								if not descendant.item.is_deferred and
								attached {PROCEDURE_I} descendant.item.feature_of_rout_id (a_routine.rout_id_set.first) as l_r then

									if not dyn_ana then
										alias_graph.current_routine.init_dyn_bin
										dyn_ana := True
									end

									--alias_graph.update_class_atts_routine_in_obj (l_r, target.attributes, target)
									alias_graph.init_feature_version
									Result := call_routine (target, l_r, a_parameters)
									alias_graph.current_routine.restore_graph_dyn (alias_graph.root_routine)
 								end
							end
						end
					end
					if alias_graph.stack_top.is_dyn_bin and dyn_ana then
						alias_graph.init_feature_version
					end
					Result := call_routine (a_target, a_routine, a_parameters)
					if alias_graph.current_routine.is_dyn_bin and dyn_ana then
						alias_graph.current_routine.finalising_dyn_bind (alias_graph.root_routine)
					end
				end
			end
		end

	find_routine (a_node: ID_SET_ACCESSOR; target: ALIAS_OBJECT): PROCEDURE_I
			-- Void for local variables and attributes
		require
			a_node /= Void
		do
			inspect a_node.routine_ids.count
			when 0 then
					-- local variable -> return Void
			else

--				if attached {PROCEDURE_I} System.class_of_id (
--							if is_qua then
--								--a_node.class_id
--								target.type.actual_type.base_class.
--							else
--								alias_graph.current_routine.current_object.type.actual_type.base_class.class_id
--							end
--							).feature_of_rout_id (a_node.routine_ids.first) as l_r then
--						-- routine

				if attached {PROCEDURE_I} System.class_of_id (
							if attached target as t then
								--a_node.class_id
								if attached t.type.actual_type.base_class as base then -- not a elegant solution
									base.class_id
								else
									a_node.class_id
								end
								--t.type.actual_type.base_class.class_id
							else
								if attached alias_graph.current_routine.current_object.type.actual_type.base_class as base then -- not a elegant solution
									base.class_id
								else
									a_node.class_id
								end
								--alias_graph.current_routine.current_object.type.actual_type.base_class.class_id
							end
							).feature_of_rout_id (a_node.routine_ids.first) as l_r then
						-- routine
					Result := l_r
				else
						-- attribute -> return Void
				end
			end
		end

	call_routine_with_arg (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_arg: EXPR_AS): ALIAS_OBJECT_INFO
		require
			a_routine /= Void
			a_arg /= Void
		local
			l_params: EIFFEL_LIST [EXPR_AS]
		do
			create l_params.make (1)
			l_params.extend (a_arg)
			Result := call_routine (a_target, a_routine, l_params)
		end

	call_routine (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_params: EIFFEL_LIST [EXPR_AS]): ALIAS_OBJECT_INFO
				-- perfoms (un)qualified rule from the Alias Calculus
				-- it returns the corresponding ALIAS Object of the call
		require
			a_routine /= Void
		local
			l_params: TWO_WAY_LIST [ALIAS_OBJECT_INFO]
			formal_param: ALIAS_OBJECT_INFO
			may_aliasing_external: TWO_WAY_LIST [STRING]
			alias_a, alias_b: STRING
			objs: ALIAS_OBJECT
			target_edge: ALIAS_VISITABLE
		do
				-- before analysing the call: check if recursion is present
			if attached a_target as t then
				alias_graph.check_recursive_fix_point (a_routine.feature_name_32, t)
			else
				alias_graph.check_recursive_fix_point (a_routine.feature_name_32, alias_graph.stack_top.current_object)
			end

			if alias_graph.is_recursive_fix_point then
				-- add parameters' links to the graph
				-- no need alias_graph.finalising_recursion

				create l_params.make
				if a_params /= Void then
					across
						a_params as c
					loop
						l_params.extend (get_alias_info (Void, c.item))
					end
				end
				alias_graph.stack_push (if a_target /= Void then a_target else alias_graph.stack_top.current_object end,
										a_routine,
										a_target /= Void)

				across
					l_params as c
				loop
					create formal_param.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))
					if not attached formal_param.alias_object or else (attached formal_param.alias_object as target and then not target.first.type.is_expanded) then
							-- updating sets Additions and Deletions used to restore the Graph after a conditional branch, loop body and recursion

						if attached a_target as target then
							target_edge := target
						else
							target_edge := alias_graph.current_routine
						end

						alias_graph.previous_routine.registering_changes_param (
									target_edge,																			-- target
									if attached c.item.variable_map as map then
										map.at (create {ALIAS_KEY}.make (c.item.variable_name))
									else
										c.item.alias_object
									end,																					-- new source
									alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make (formal_param.variable_name)),-- old source
									formal_param.variable_name)																	-- tag
					end
					formal_param.set_swicth_param
					formal_param.alias_object := c.item.alias_object
				end

				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, "Result")
				if Result.variable_name ~ "Result" then
					Result.set_function
				end
				alias_graph.current_routine.update_call
				alias_graph.stack_pop_noaction
			else
				create l_params.make
				if a_params /= Void then
					across
						a_params as c
					loop
						l_params.extend (get_alias_info (Void, c.item))
					end
				end

				alias_graph.stack_push (if a_target /= Void then a_target else alias_graph.stack_top.current_object end,
										a_routine,
										a_target /= Void)

				across
					l_params as c
				loop
					-- TODO: create a new one only if it does not exist. Otherwise, create a ALIAS_OBJECT_INFO from the existing one
					create formal_param.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))
					if not attached formal_param.alias_object or else (attached formal_param.alias_object as target and then not target.first.type.is_expanded) then
							-- updating sets Additions and Deletions used to restore the Graph after a conditional branch, loop body and recursion

						if attached a_target as target then
							target_edge := target
						else
							target_edge := alias_graph.current_routine
						end

						alias_graph.previous_routine.registering_changes_param (
									target_edge,
									if attached c.item.variable_map as map then
										map.at (create {ALIAS_KEY}.make (c.item.variable_name))
									else
										c.item.alias_object
									end,				-- new source
									alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make (formal_param.variable_name)),
									--formal_param.variable_map.at (create {ALIAS_KEY}.make (formal_param.variable_name)),	-- old source
									formal_param.variable_name)																	-- tag
					end

					formal_param.set_swicth_param
					formal_param.alias_object := c.item.alias_object
				end

				if a_routine.e_feature.name_32 ~ "out" then
					alias_by_external ("Result", "+")
				elseif a_routine.e_feature.name_32 ~ "call" then
					-- TODO HW
				elseif a_routine.access_class.name ~ "ANY" then
						-- ToDo: implement all "hacks"
					if a_routine.e_feature.name_32 ~ "copy" then
							-- Implementation of copy:
							--							a.copy (b)
							--								create a
							--								for_all atts in a ==> add the alias objects in b
						--TODO alias_graph.update_class_atts (alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.type.base_class, alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.attributes, alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first)
						across
							alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.attributes as atts
								-- note: from ANY class the name will always be 'other'
						loop
								-- wipe out all elements (if any)
							a_target.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, atts.key)
							across
								atts.item as to_copy
							loop
								a_target.attributes.at (atts.key).force (to_copy.item)
							end
						end
					elseif a_routine.e_feature.name_32 ~ "twin" then
							-- Implementation of twin:
							--							a := b.twin -> the semantics are:
							--													create a
							--													a.copy (b)

							-- TODO: there is a problem when attached {FORMAL_A} a_target.type. there is not information about the generic class
						--TODO alias_graph.update_class_atts (a_target.type.base_class, a_target.attributes, a_target)
						alias_graph.stack_top.locals.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, create {ALIAS_KEY}.make ("Result"))
						create objs.make (a_target.type)
						across
							a_target.attributes as vars
						loop
							objs.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, vars.key)
							across
								vars.item as oo
							loop
								objs.attributes.at (vars.key).force (oo.item)
							end
						end
						alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("Result")).force (objs)
					end
				elseif a_routine.access_class.name ~ "SPECIAL" or a_routine.is_external or a_routine.access_class.name ~ "V_SPECIAL" then
						-- external features do not have implementation information.
						-- they should have additional information in the form of
						-- a note clause in Eiffel with tag 'external_alias'.
						-- The information of the signature is still available and needed
					may_aliasing_external := get_alias_pairs (a_routine)
					--may_aliasing_external := ext_ali.at (a_routine.e_feature.name_32)


					if may_aliasing_external.count > 1 and then (may_aliasing_external.count \\ 2) = 0 then
						from
							may_aliasing_external.start
						until
							may_aliasing_external.after
						loop
							alias_a := may_aliasing_external.item
							may_aliasing_external.forth
							alias_b := may_aliasing_external.item
							may_aliasing_external.forth
							alias_by_external (alias_a, alias_b)
						end
					end
				elseif attached get_alias_pairs (a_routine) as aliases and then aliases.count > 0 then
						-- the feature declares external aliases
					if (aliases.count \\ 2) = 0 then
						from
							aliases.start
						until
							aliases.after
						loop
							alias_a := aliases.item
							aliases.forth
							alias_b := aliases.item
							aliases.forth
							alias_by_external (alias_a, alias_b)
						end
					end
				else
					a_routine.body.process (Current)
				end
				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, "Result")
				if Result.variable_name ~ "Result" then
					Result.set_function
				end
				alias_graph.current_routine.update_call
				alias_graph.stack_pop
			end
		end

	alias_by_external (alias_a, alias_b: STRING)
			-- does the corresponding aliasing taken from External features
			-- after execution, `alias_a' will be aliased to `alias_b'
		local
			source: TWO_WAY_LIST [ALIAS_OBJECT]
			path: LIST [STRING]
		do
			create source.make
			path := alias_b.split ('.')
			if path.count = 1 and path [1] ~ "+" then
				path := alias_a.split ('.')
				if alias_graph.stack_top.current_object.attributes.has (create {ALIAS_KEY}.make (path.first)) then
					alias_object_external (alias_graph.stack_top.current_object.attributes, Void, path, 1)
				else
					alias_object_external (alias_graph.stack_top.locals, Void, path, 1)
				end
			else
				if alias_b ~ "{T}.default" then
					source.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.any_class.compiled_class.class_id)))
				else
					if alias_graph.stack_top.current_object.attributes.has (create {ALIAS_KEY}.make (path.first)) then
						collect_objects_external (alias_graph.stack_top.current_object.attributes, source, path, 1)
					else
						collect_objects_external (alias_graph.stack_top.locals, source, path, 1)
					end
				end
				path := alias_a.split ('.')
				if alias_graph.stack_top.current_object.attributes.has (create {ALIAS_KEY}.make (path.first)) then
					alias_object_external (alias_graph.stack_top.current_object.attributes, source, path, 1)
				else
					alias_object_external (alias_graph.stack_top.locals, source, path, 1)
				end
			end
		end

	collect_objects_external (graph: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; source: TWO_WAY_LIST [ALIAS_OBJECT]; path: LIST [STRING]; index: INTEGER)
			-- collects the object in `source' fom `path' in `graph' to be added after external aliasing
		require
			index > 0
		local
			val: ALIAS_KEY
		do
			create val.make (path [index])
			if index < path.count then
				if graph.has_key (val) then
					across
						graph.at (val) as objs
					loop
						collect_objects_external (objs.item.attributes, source, path, index + 1)
					end
				else
						-- TODO: retrieve info
				end
			else
				if graph.has_key (val) then
					across
						graph.at (val) as objs
					loop
						source.force (objs.item)
					end
				end
			end
		end

	alias_object_external (graph: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; source: detachable TWO_WAY_LIST [ALIAS_OBJECT]; path: LIST [STRING]; index: INTEGER)
			-- aliased objects in `source' to `path' in `graph'
			-- if source = Void then the action is {(path, +)} (similar semantics than create path)
		require
			index > 0
		local
			type: TYPE_A
			val: ALIAS_KEY
			pred: ALIAS_VISITABLE
			aoi: ALIAS_OBJECT_INFO
			target_edge: ALIAS_VISITABLE
		do
			create val.make (path [index])
			if index < path.count then
				if graph.has_key (val) then
					across
						graph.at (val) as objs
					loop
						alias_object_external (objs.item.attributes, source, path, index + 1)
					end
				else
						-- TODO: retrieve info
				end
			else
				if graph.has_key (val) then
					if attached source as s then
						if s.count > 0 then
							if alias_graph.stack_top.current_object.attributes.has (val) then
								target_edge := alias_graph.stack_top.current_object
							else -- it is in locals
								target_edge := alias_graph.stack_top
							end
							alias_graph.current_routine.registering_changes (
								target_edge,
								s,
								graph.at (val),
								val.name)

							create aoi.make_variable (
								alias_graph.stack_top.routine, graph,
								val.name)
							if index > 1 then
								aoi.set_swicth_special_no_direct
							else
								aoi.set_switch_normal
							end
							aoi.set_alias_object (s)
							across
								graph as g
							loop
								if g.key.name ~ val.name then
									g.key.set_assigned
								end
							end
						end
					else -- create
						pred := graph.at (val).first.predecessors.at (val).first
						type := graph.at (val).first.type
						graph.at (val).wipe_out
						graph.at (val).force (create {ALIAS_OBJECT}.make (type))
						graph.at (val).last.predecessors.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, val)
						graph.at (val).last.predecessors.at (val).force (pred)
						across
							graph as g
						loop
							if g.key.name ~ val.name then
								g.key.set_assigned
							end
						end
					end
				end
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

	get_alias_pairs (a_routine: PROCEDURE_I): TWO_WAY_LIST [STRING]
			-- returns the alias pairs defined by users in external features
		local
			note_clause: STRING
			pair_prj: STRING
		do
			create Result.make

			if attached a_routine.e_feature.ast.indexes as indexes then
				from
					indexes.start
				until
					indexes.after or (attached indexes.item.tag as tag and then tag.name_32 ~ "external_alias")
				loop
					indexes.forth
				end
				if not indexes.after then
					create note_clause.make_from_string (indexes.item.index_list.first.string_value_32)
					note_clause.replace_substring_all (" ", "")
					if note_clause.count >= 2 then
							-- eliminate "{}"
						note_clause := note_clause.substring (3, note_clause.count - 2)
						across
							note_clause.split ('-') as aliasing
						loop
							across
								aliasing.item.split (',') as proj
							loop
								create pair_prj.make_from_string (proj.item)
								if pair_prj.count >= 2 then
									pair_prj.replace_substring_all ("(", "")
									pair_prj.replace_substring_all (")", "")
									Result.force (pair_prj)
								end
							end
						end
					end
				end
			end
		end

feature {NONE} --  for debugging purposes

invariant
	alias_graph /= Void

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
