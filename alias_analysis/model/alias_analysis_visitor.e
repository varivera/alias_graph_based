note
	description: "The visitor that computes the alias state."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-20 18:49:14 +0300 (Fri, 20 Nov 2015) $"
	revision: "$Revision: 98127 $"

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
			create alias_graph.make (a_routine)
			statement_observer := a_statement_observer
		ensure
			statement_observer = a_statement_observer
		end

--		test
--		do
--			print (routine.access_class.computed_parents.count)
--			print (routine.access_class.computed_parents.first.class_name)
--			print  (routine.access_class.number_of_ancestors)
--			print (routine.access_class.conforming_parents_classes.count)
--			
--			
--			routine.access_class.
--			from
--				routine.access_class.conforming_parents_classes.start
--			until
--				routine.access_class.conforming_parents_classes.after
--			loop
--				print (routine.access_class.conforming_parents_classes.item.name)
--				routine.access_class.conforming_parents_classes.forth
--			end

----			if attached {E_ROUTINE} routine.e_feature.updated_version as r and then
----				attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as p
----			then
----				create l_visitor.make (routine, agent  (ag_node: AST_EIFFEL; ag_alias_graph: ALIAS_GRAPH)
----					do
----						if ag_node.breakpoint_slot = 0 then
----							(create {ETR_BP_SLOT_INITIALIZER}).init_with_context (routine.e_feature.ast, routine.written_class)
----						end
----						if index = ag_node.breakpoint_slot then
----								--Io.put_string ("Taking report before " + ag_node.generator + " (slot " + index.out + ").%N")
----							as_string := ag_alias_graph.to_string
----							as_graph := ag_alias_graph.to_graph
----						end
----					end)
----				routine.body.process (l_visitor)
----			end
--		end

feature {ANY}

	alias_graph: ALIAS_GRAPH

	statement_observer: PROCEDURE [ANY, TUPLE [AST_EIFFEL, ALIAS_GRAPH]]

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
						statement_observer.call (l_item, alias_graph)
					end
						--print (alias_graph.to_string)
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
			if tracing then
					--alias_graph.print_vals
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable and then attached get_alias_info (Void, a_node.source) as l_source then
				if alias_graph.is_conditional_branch or alias_graph.is_loop_iter then
						-- check if the target is an expanded type (do nothing if so)
						--TODO: to improve
					if not attached l_target.alias_object or else (attached l_target.alias_object as target and then not target.first.type.is_expanded) then
							-- updating sets Additions and Deletions used to restore the Graph after a conditional branch, loop body and recursion
						stop (12)
						alias_graph.updating_graph (l_target, l_source)
					end
				end
				if tracing then
					alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
					alias_graph.print_atts_depth (alias_graph.stack_top.locals)
				end
				l_target.alias_object := l_source.alias_object
				if tracing then
					alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
					alias_graph.print_atts_depth (alias_graph.stack_top.locals)
				end
			else
				Io.put_string ("Not yet supported (1): " + code (a_node) + "%N")
			end
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
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
					call_routine_with_arg (aliases.item, l_set_bar2, a_node.source, entity_caller).do_nothing
				end
			else
				Io.put_string ("Not yet supported (2): " + code (a_node) + "%N")
			end
		end

	process_create_creation_as (a_node: CREATE_CREATION_AS)
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			old_object: ALIAS_OBJECT_INFO
		do
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable then
					--create old_object.make
				if attached l_target.alias_object as objects then
					create old_object.make_object (objects)
				end
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
				l_target.alias_object := l_obj
				if alias_graph.is_conditional_branch then
						--alias_graph.forget_att (l_target)
					alias_graph.forget_att (l_target, old_object)
				end
				across
					l_target.alias_object as aliases
				loop
					if attached a_node.call then
						get_alias_info (aliases.item, a_node.call).do_nothing
					else
							-- call default_create procedure
						if attached System.eiffel_universe.classes_with_name (l_target.alias_object.first.type.name)
								as l_classes and then l_classes.count = 1
								and then attached {PROCEDURE_I} System.class_of_id (l_classes.first.compiled_class.class_id)
							.feature_of_rout_id
							(System.class_of_id (l_classes.first.compiled_class.class_id).creation_feature.e_feature.rout_id_set.first) as l_r
						then
							call_routine (aliases.item, l_r, Void,
									aliases.item.entity).do_nothing
						end
						stop (200)
					end
				end

					--TODO: Creation procedures

					--				if alias_graph.is_conditional_branch or else alias_graph.is_loop_iter then
					--						-- check if the target is an expanded type (do nothing if so)
					--					--l_target.alias_object.start
					--					if attached l_target.alias_object as target and then not target.first.type.is_expanded then
					--						-- updating A and D in case of conditional branch or loop body
					--						-- addition
					--						-- deletion
					--						alias_graph.updating_A_D (l_target.variable_name, l_source.variable_name, l_target.alias_object, l_source.alias_object)
					--					end
					--				end

					-- OLD
					--				if alias_graph.is_conditional_branch or else alias_graph.is_loop_iter then
					--						-- updating A and D in case of conditional branch or loop body
					--						-- addition
					--						-- deletion
					--					alias_graph.updating_A_D (l_target.variable_name, l_target.variable_name, old_object, l_obj)
					--				end
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
				-- Aliasing does not make any assuption about the condition in a conditional
			a_node.expr.process (Current)
			alias_graph.init_cond_branch
			safe_process (a_node.compound)
			alias_graph.restore_graph
		end

	process_if_as (a_node: IF_AS)
		do
				-- Alias Analysis does not take into account the condition. However,
				-- it might be an object test with definition of a
				-- fresh variable (hence, the need of processing it)
			a_node.condition.process (Current)
			alias_graph.init_cond
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			alias_graph.init_cond_branch
			safe_process (a_node.compound)
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			alias_graph.restore_graph
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			safe_process (a_node.elsif_list)
			alias_graph.init_cond_branch
			safe_process (a_node.else_part)

				--			alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				--			alias_graph.print_atts_depth (alias_graph.stack_top.locals)

				--Vic: no need to restore the graph: alias_graph.restore_graph

			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			alias_graph.finalising_cond
				-- update the deleted links in alias_pos_rec
			alias_graph.stack_top.alias_pos_rec.update_del (alias_graph.inter_deletion_cond)
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
		end

	process_loop_as (a_node: LOOP_AS)
		do
			safe_process (a_node.iteration)
			safe_process (a_node.from_part)
			safe_process (a_node.invariant_part)
			safe_process (a_node.stop)
				-- initialiase a loop iteration and repeat the body of the loop until reaching the fixpoint
			from
				alias_graph.init_loop
			until
				alias_graph.fixpoint_reached > 0
			loop
				alias_graph.iter
				safe_process (a_node.compound)
				alias_graph.checking_fixpoint
			end
			if Tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			alias_graph.finalising_loop
--			safe_process (a_node.variant_part)
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
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

	get_alias_info (a_target: ALIAS_OBJECT; a_node: AST_EIFFEL): ALIAS_OBJECT_INFO
		require
			a_node /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			entities_caller: TWO_WAY_LIST [STRING]
		do
			if not attached a_node then
				print ("Void")
			end
			if attached {VOID_AS} a_node as l_node then
				--create Result.make_void
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make_void)
				create Result.make_object (l_obj)
			elseif attached {CHAR_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.character_8_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {INTEGER_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.integer_32_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {STRING_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.string_8_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
			elseif attached {CURRENT_AS} a_node as l_node then
				create l_obj.make
				l_obj.force (alias_graph.stack_top.current_object)
				create Result.make_object (l_obj)
			elseif attached {UN_NOT_AS} a_node or attached {BIN_OR_AS} a_node or attached {BIN_AND_AS} a_node or attached {BIN_EQ_AS} a_node or attached {BIN_TILDE_AS} a_node then
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.boolean_class.compiled_class.class_id)))
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
					if not alias_graph.stack_top.locals.has (l_node.access_name_32) then
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_node.class_id)))
						alias_graph.stack_top.locals.force (l_obj, l_node.access_name_32)
					end
					create Result.make_variable (
						alias_graph.stack_top.routine,
						alias_graph.stack_top.locals,
						l_node.access_name_8)
				elseif l_node.is_tuple_access then
						-- TODO
				elseif attached find_routine (l_node) as l_routine then
						-- routine

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
						if l_routine.argument_count = l_node.parameter_count then

								-- check if there are several version
							if attached a_target as target then
									-- this is indeed a qualified call
								print (target.type.name)
								if attached System.eiffel_universe.classes_with_name (target.type.name) as l_classes and then l_classes.count > 0 then
									l_classes.first.compiled_class.direct_descendants.start
									from

									until
										l_classes.first.compiled_class.direct_descendants.after
									loop
										print (l_classes.first.compiled_class.direct_descendants.item.name)
										io.new_line
										l_classes.first.compiled_class.direct_descendants.forth
									end

--			print (routine.access_class.computed_parents.count)
--			print (routine.access_class.computed_parents.first.class_name)
--			print  (routine.access_class.number_of_ancestors)
--			print (routine.access_class.conforming_parents_classes.count
								end
							end
							stop (333)
							Result := call_routine (a_target, l_routine, l_node.parameters, if a_target /= Void then a_target.entity else create {TWO_WAY_LIST [STRING]}.make end)
						end
					end
				else
					if attached a_target as target and then not attached {VOID_A} target.type then
							-- check if there are attributes to be added
						alias_graph.update_class_atts (target.type.base_class, target.attributes)
					end
						-- attribute
					create Result.make_variable (alias_graph.stack_top.routine, (if a_target /= Void then a_target else alias_graph.stack_top.current_object end).attributes, l_node.access_name_8)
				end
			elseif attached {NESTED_AS} a_node as l_node then
				stop (1)
				if attached get_alias_info (a_target, l_node.target) as l_target and then l_target.is_variable then
					if l_target.alias_object = Void then
							-- target doesn't exist yet (e.g. expanded type) -> create
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
						l_target.alias_object := l_obj
					end

					if attached l_target.alias_object as objs and then objs.count > 0 and then objs.first.type.is_basic then
						if attached System.eiffel_universe.classes_with_name (objs.first.type.name) as l_classes and then l_classes.count > 0 then
							create l_obj.make
							l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_classes.first.compiled_class.class_id)))
							create Result.make_object (l_obj)
						end
					else
						across
							l_target.alias_object as aliasses
						loop
							stop (124)
							create entities_caller.make
							if l_target.function then
								stop (125)
									-- The name of the entity should be changed. It is being carried out by the stack_top routine
								if alias_graph.stack_top.map_funct.has_key (l_target.context_routine.e_feature.name_32) then
									aliasses.item.entity := alias_graph.stack_top.map_funct [l_target.context_routine.e_feature.name_32]
								else
									entities_caller.force ("ERROR")
									aliasses.item.entity := entities_caller
								end
							else
								stop (130)
								if tracing then
									print (l_target.variable_name)
									io.new_line
								end
								entities_caller.force (l_target.variable_name)
								aliasses.item.entity := entities_caller
							end
								-- take care of 'dynamic binding'

--							if attached System.eiffel_universe.classes_with_name (aliasses.item.type.name) as l_classes and then l_classes.count > 0 then
--								l_classes.first

--								asd
--							end

							Result := get_alias_info (aliasses.item, l_node.message)
							aliasses.item.entity := create {TWO_WAY_LIST [STRING]}.make
						end
					end
				end
			elseif attached {BINARY_AS} a_node as l_node then
				stop (2)
				if attached get_alias_info (a_target, l_node.left) as l_target and then attached find_routine (l_node) as l_routine then
						-- there is not need to go further if the operation is on Basic Types
					stop (40)
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
							Result := call_routine_with_arg (aliases.item, l_routine, l_node.right, if a_target /= Void then a_target.entity else create {TWO_WAY_LIST [STRING]}.make end)
						end
					end
				end
			elseif attached {BRACKET_AS} a_node as l_node then
				stop (3)

				if attached get_alias_info (a_target, l_node.target) as l_target and then attached find_routine (l_node) as l_routine then
					if l_target.alias_object = Void then
							-- target doesn't exist yet (e.g. expanded type) -> create
						create l_obj.make
						l_obj.force (create {ALIAS_OBJECT}.make (l_target.type))
						l_target.alias_object := l_obj
					end
					across
						l_target.alias_object as aliasses
					loop
						create entities_caller.make
						stop (128)
						if l_target.function then
							stop (129)
								-- The name of the entity should be changed. It is being carried out by the stack_top routine
							if alias_graph.stack_top.map_funct.has_key (l_target.context_routine.e_feature.name_32) then
								aliasses.item.entity := alias_graph.stack_top.map_funct [l_target.context_routine.e_feature.name_32]
							else
								entities_caller.force ("ERROR")
								aliasses.item.entity := entities_caller
							end
						else
							stop (131)
							if tracing then
								print (l_target.variable_name)
								io.new_line
							end
							entities_caller.force (l_target.variable_name)
							aliasses.item.entity := entities_caller
						end

							-- no needResult := get_alias_info (aliasses.item, l_node.message)

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
							stop (126)
							Result := call_routine (aliasses.item, l_routine, l_node.operands, aliasses.item.entity)
						end
						aliasses.item.entity := create {TWO_WAY_LIST [STRING]}.make
					end
				end
			elseif attached {EXPR_CALL_AS} a_node as l_node then
				stop (4)
				Result := get_alias_info (a_target, l_node.call)
			elseif attached {NESTED_EXPR_AS} a_node as l_node then
				stop (5)
				if attached get_alias_info (a_target, l_node.target) as l_target then
					across
						l_target.alias_object as aliases
					loop
						Result := get_alias_info (aliases.item, l_node.message)
					end
				end
			elseif attached {PARAN_AS} a_node as l_node then
				stop (6)
				Result := get_alias_info (a_target, l_node.expr)
			elseif attached {TYPE_EXPR_AS} a_node as l_node then
				stop (7)
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.type_class.compiled_class.class_id)))
				create Result.make_object (l_obj)
					-- Note (17.2.17) No need to call get_alias_info (a_target, l_node.type)
			elseif attached {CLASS_TYPE_AS} a_node as l_node then
				stop (8)
					-- TODO
				if attached System.eiffel_universe.compiled_classes_with_name (l_node.class_name.name_8) as l_classes then -- and then l_classes.count = 1 then
					print (l_classes.count)
				end
			end
			if Result = Void then
				stop (111)
				if attached a_node then
					Io.put_string ("%N---> " + code (a_node) + " -> " + a_node.generator + "%N")
				else
					Io.put_string ("%N|---> a_node: Void -> %N")
				end
			end
		end

	stop (n: INTEGER)
		do
			if tracing then
				if n = 111 then
					print ("not supported%N")
				end
				io.new_line
				print (n)
				if n = 333 then
					print (n)
				end
				io.new_line
			end
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

	call_routine_with_arg (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_arg: EXPR_AS; entity: TWO_WAY_LIST [STRING]): ALIAS_OBJECT_INFO
		require
			a_routine /= Void
			a_arg /= Void
		local
			l_params: EIFFEL_LIST [EXPR_AS]
		do
			create l_params.make (1)
			l_params.extend (a_arg)
			Result := call_routine (a_target, a_routine, l_params, entity)
		end

	call_routine (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_params: EIFFEL_LIST [EXPR_AS]; entity: TWO_WAY_LIST [STRING]): ALIAS_OBJECT_INFO
		require
			a_routine /= Void
		local
			l_params: TWO_WAY_LIST [ALIAS_OBJECT_INFO]
			may_alising_external: TWO_WAY_LIST [STRING]
			alias_a, alias_b: STRING
		do
				-- before making the call: check if recursion, if so, check for Fix Point
			alias_graph.check_recursive_fix_point (a_routine.feature_name_32)
			if alias_graph.is_recursive_fix_point then
				alias_graph.finalising_recursion
				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.rec_last_locals, "Result")
			else
				create l_params.make
				if a_params /= Void then
					across
						a_params as c
					loop
						l_params.extend (get_alias_info (Void, c.item))
					end
				end
				if tracing then
					across
						entity as ent
					loop
						io.new_line
						print (ent.item)
					end
					io.new_line
					alias_graph.stack_top.alias_pos_rec.printing_vars (1)
				end
				alias_graph.stack_push (if a_target /= Void then a_target else alias_graph.stack_top.current_object end, a_routine, entity, if a_target = Void then False else True end)
				if tracing then
					io.new_line
						--				across
						--					alias_graph.stack_top.caller_path as p
						--				loop
						--					print (p.item + ".")
						--				end
					io.new_line
				end
				across
					l_params as c
				loop
					(create {ALIAS_OBJECT_INFO}.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))).alias_object := c.item.alias_object
				end
				stop (11)
				if tracing then
					print (">>> " + a_routine.access_class.name)
				end
				if a_routine.e_feature.name_32 ~ "out" then
					alias_by_external ("Result", "+")
					stop (150)
				elseif a_routine.access_class.name ~ "ANY" then
						-- ToDo: implement all "hacks"
					io.new_line
					stop (123)
					print ("ANY Class")
					io.new_line
					print (a_routine.e_feature.name_32)
					io.new_line
				elseif a_routine.access_class.name ~ "SPECIAL" or a_routine.is_external then
						-- external features do not have implementation information.
						-- they should have additional information in the form of
						-- a note clause in Eiffel with tag 'external_alias'.

						-- The information of the signature is still available and needed
					may_alising_external := get_alias_pairs (a_routine)
					if (may_alising_external.count \\ 2) = 0 then
						from
							may_alising_external.start
						until
							may_alising_external.after
						loop
							alias_a := may_alising_external.item
							may_alising_external.forth
							alias_b := may_alising_external.item
							may_alising_external.forth
							if tracing then
								print_aliases (alias_a, alias_b)
							end
							alias_by_external (alias_a, alias_b)
						end
					end
				else
					a_routine.body.process (Current)
				end
				if tracing then
					alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
					alias_graph.print_atts_depth (alias_graph.stack_top.locals)
				end
				create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, "Result")
				if Result.variable_name ~ "Result" then
					Result.set_function
				end
				stop (129)
				alias_graph.update_call
				if tracing then
					alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
					alias_graph.print_atts_depth (alias_graph.stack_top.locals)
				end
				alias_graph.stack_pop
				if tracing then
					alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
					alias_graph.print_atts_depth (alias_graph.stack_top.locals)
				end
			end
		end

	alias_by_external (alias_a, alias_b: STRING)
			-- does the corresponding aliasing taken from External features
			-- after execution, `alias_a' will be aliased to `alias_b'
		local
			source: TWO_WAY_LIST [ALIAS_OBJECT]
			path: LIST [STRING]
		do
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			create source.make
			path := alias_b.split ('.')
			if path.count = 1 and path [1] ~ "+" then
				path := alias_a.split ('.')
				if alias_graph.stack_top.current_object.attributes.has (path.first) then
					alias_object_external (alias_graph.stack_top.current_object.attributes, Void, path, 1)
				else
					alias_object_external (alias_graph.stack_top.locals, Void, path, 1)
				end
			else
				if alias_b ~ "{T}.default" then
					source.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (System.any_class.compiled_class.class_id)))
				else
					if alias_graph.stack_top.current_object.attributes.has (path.first) then
						collect_objects_external (alias_graph.stack_top.current_object.attributes, source, path, 1)
					else
						collect_objects_external (alias_graph.stack_top.locals, source, path, 1)
					end
				end
				path := alias_a.split ('.')
				if alias_graph.stack_top.current_object.attributes.has (path.first) then
					alias_object_external (alias_graph.stack_top.current_object.attributes, source, path, 1)
				else
					alias_object_external (alias_graph.stack_top.locals, source, path, 1)
				end
			end
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
		end

	collect_objects_external (graph: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING]; source: TWO_WAY_LIST [ALIAS_OBJECT]; path: LIST [STRING]; index: INTEGER)
			-- collects the object in `source' fom `path' in `graph' to be added after external aliasing
		require
			index > 0
		do
			if index < path.count then
				if graph.has_key (path [index]) then
					across
						graph.at (path [index]) as objs
					loop
						collect_objects_external (objs.item.attributes, source, path, index + 1)
					end
				else
						-- TODO: retrieve info
				end
			else
				if graph.has_key (path [index]) then
					across
						graph.at (path [index]) as objs
					loop
						source.force (objs.item)
					end
				end
			end
		end

	alias_object_external (graph: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING]; source: detachable TWO_WAY_LIST [ALIAS_OBJECT]; path: LIST [STRING]; index: INTEGER)
			-- aliased objects in `source' to `path' in `graph'
			-- if source = Void then the action is {(path, +)} (similar semantics than create path)
		require
			index > 0
		local
			type: TYPE_A
		do
			if index < path.count then
				if graph.has_key (path [index]) then
					across
						graph.at (path [index]) as objs
					loop
						alias_object_external (objs.item.attributes, source, path, index + 1)
					end
				else
						-- TODO: retrieve info
				end
			else
				if graph.has_key (path [index]) then
					if attached source as s then
						across
							s as objs
						loop
							if not graph.at (path [index]).has (objs.item) then
								graph.at (path [index]).force (objs.item)
							end
						end
					else -- create
						type := graph.at (path [index]).first.type
						graph.at (path [index]).wipe_out
						graph.at (path [index]).force (create {ALIAS_OBJECT}.make (type))
					end
				end
			end
		end

	print_aliases (alias_a, alias_b: STRING)
		do
			if tracing then
				io.new_line
				print (alias_a)
				io.new_line
				print (alias_b)
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
					if tracing then
						print ("%NNote clause%N")
						print ("%N1: " + note_clause + "%N")
						note_clause.replace_substring_all (" ", "")
						print ("%N2: " + note_clause + "%N")
					end
					if note_clause.count >= 2 then
							-- eliminate "{}"
						note_clause := note_clause.substring (3, note_clause.count - 2)
						if tracing then
							print ("%N3: " + note_clause + "%N")
						end
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
									if tracing then
										print ("%N44: " + pair_prj + "%N")
									end
									Result.force (pair_prj)
								end
							end
						end
					end
				end
			end
		end

invariant
	alias_graph /= Void

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