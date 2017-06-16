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
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			if attached get_alias_info (Void, a_node.target) as l_target and then l_target.is_variable and then attached get_alias_info (Void, a_node.source) as l_source then
				if alias_graph.is_conditional_branch or alias_graph.is_loop_iter or alias_graph.is_dyn_bin then
						-- check if the target is an expanded type (do nothing if so)
					stop (334)
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
				assigning (l_target, l_source)
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

	assigning (target, source: ALIAS_OBJECT_INFO)
			-- assigns objects of `source' to `target' objects
		do
			across
				alias_graph.stack_top.current_object.attributes.current_keys as k
			loop
				if k.item.name ~ target.variable_name then
					k.item.set_assigned
				end
			end
			target.alias_object := source.alias_object
		end

	process_assigner_call_as (a_node: ASSIGNER_CALL_AS)
		local
			entity_caller: TWO_WAY_LIST [STRING]
		do
			if tracing then
				io.new_line
				print (attached {BRACKET_AS} a_node.target as l_target1)
				io.new_line
				if attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo then
					print (l_foo.variable_name)
				end
				io.new_line
				if attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo and then attached find_routine (l_target2) as l_bar then
					print (l_bar.e_feature.name_32)
				end
				io.new_line
				if attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo and then attached find_routine (l_target2) as l_bar and then attached l_foo.alias_object.first.type.base_class as l_c and then attached l_c.feature_named_32 (l_bar.e_feature.name_32).assigner_name as l_set_bar1 then
					print (l_set_bar1)
				end
				io.new_line
				if attached {BRACKET_AS} a_node.target as l_target2 and then attached get_alias_info (Void, l_target2.target) as l_foo and then attached find_routine (l_target2) as l_bar and then attached l_foo.alias_object.first.type.base_class as l_c and then attached l_c.feature_named_32 (l_bar.e_feature.name_32).assigner_name as l_set_bar1 and then attached {PROCEDURE_I} l_c.feature_named_32 (l_set_bar1) as l_set_bar2 then
					print (l_set_bar2.argument_count)
				end
				io.new_line
			end
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
				across
					l_foo.alias_object as aliases
				loop
					create entity_caller.make
					entity_caller.force (l_foo.variable_name)
					aliases.item.add_entity (entity_caller, alias_graph.stack_top.locals)
					call_routine_with_arg (aliases.item, l_set_bar2, a_node.source).do_nothing
				end
			else
				Io.put_string ("Not yet supported (2): " + code (a_node) + "%N")
			end
		end

	process_create_creation_as (a_node: CREATE_CREATION_AS)
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			old_object: ALIAS_OBJECT_INFO
			entities_caller: TWO_WAY_LIST [STRING]
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
					if not l_target.alias_object.first.is_string then

						create entities_caller.make
						entities_caller.force (l_target.variable_name)
						aliases.item.add_entity (entities_caller, alias_graph.stack_top.locals)

						if attached a_node.call then
							get_alias_info (aliases.item, a_node.call).do_nothing
						else
								-- call default_create procedure
							if attached System.eiffel_universe.classes_with_name (l_target.alias_object.first.type.name) as l_classes and then l_classes.count = 1 and then attached {PROCEDURE_I} System.class_of_id (l_classes.first.compiled_class.class_id).feature_of_rout_id (System.class_of_id (l_classes.first.compiled_class.class_id).creation_feature.e_feature.rout_id_set.first) as l_r then
								call_routine (aliases.item, l_r, Void).do_nothing
							end
							stop (200)
						end
						aliases.item.entity_wipe_out
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
			stop (110)
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
			show_graph
			alias_graph.restore_graph
			show_graph
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			safe_process (a_node.elsif_list)
			alias_graph.init_cond_branch
			safe_process (a_node.else_part)
			show_graph
				--Note: no need to restore the graph: alias_graph.restore_graph
			alias_graph.restore_graph
			show_graph
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
			end
			alias_graph.finalising_cond
			show_graph
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

	show_graph
			-- depicts the graph
		local
			output_file: PLAIN_TEXT_FILE
		do
--			create output_file.make_open_write ("c:\Users\v.rivera\Desktop\toDelete\testingGraphViz\dd.dot")
--			output_file.put_string  (alias_graph.to_graph)
--			output_file.close;
			(create {EXECUTION_ENVIRONMENT}).launch ("echo %"" + alias_graph.to_graph + "%" | dot -Tpdf | okular - 2>/dev/null")
		end

	get_alias_info (a_target: ALIAS_OBJECT; a_node: AST_EIFFEL): ALIAS_OBJECT_INFO
		require
			a_node /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			entities_caller: TWO_WAY_LIST [STRING]
		do
			if tracing then
				if not attached a_node then
					print ("Void")
				end
			end
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
						l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (l_node.class_id)))
						alias_graph.stack_top.locals.force (l_obj, create {ALIAS_KEY}.make (l_node.access_name_32))
					end
					create Result.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, l_node.access_name_8)
				elseif l_node.is_tuple_access then
						-- TODO
				elseif attached find_routine (l_node) as l_routine then
						-- routine

						Result := process_routine (a_target, l_routine, l_node.class_id,
										if attached l_node.parameters as params then
											params
										else
											create {EIFFEL_LIST [EXPR_AS]}.make (0)
										end)
				else
					stop (909)
					if attached a_target as target and then attached target.type as type and then attached type.base_class as base then
							-- check if there are attributes to be added
						alias_graph.update_class_atts (base, target.attributes)
					end
						-- attribute
					create Result.make_variable (alias_graph.stack_top.routine, (if a_target /= Void then a_target else alias_graph.stack_top.current_object end).attributes, l_node.access_name_8)
				end
			elseif attached {PRECURSOR_AS} a_node as l_node then
				stop (10)
				if attached find_routine (l_node) as l_routine then
					Result := process_routine (a_target, l_routine, l_node.class_id,
									if attached l_node.parameters as params then
										params
									else
										create {EIFFEL_LIST [EXPR_AS]}.make (0)
									end)
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
							stop (124)
							create entities_caller.make
							if l_target.function then
								stop (125)
									-- The name of the entity should be changed. It is being carried out by the stack_top routine
								if alias_graph.stack_top.map_funct.has_key (create {ALIAS_KEY}.make (l_target.context_routine.e_feature.name_32)) then
									if attached a_target as target  then
										across
											--target.entity as ent
											1 |..| target.entity.count as i
										loop
											if tracing then
												io.new_line
												print (target.entity [i.item])
											end

											aliasses.item.add_entity (target.entity [i.item], target.entity_locals [i.item])
										end
									end
									entities_caller := alias_graph.stack_top.map_funct [create {ALIAS_KEY}.make (l_target.context_routine.e_feature.name_32)]
									aliasses.item.add_entity (entities_caller, alias_graph.stack_top.locals)
								else
									aliasses.item.set_entity_error
								end
							else
								stop (130)
								if tracing then
									print (l_target.variable_name)
									io.new_line
								end

								if attached a_target as target then
									across
										--target.entity as ent
										1 |..| target.entity.count as i
									loop
											if tracing then
											io.new_line
											print ("[")
											across
												target.entity [i.item] as e
											loop
												print (e.item)
												print (", ")
											end
											print ("]")
										end
										aliasses.item.add_entity (target.entity [i.item], target.entity_locals [i.item])
									end
								end

								entities_caller.force (l_target.variable_name)

									-- TODO: to ask for argument
								if tracing then
									stop (-1)
									print (alias_graph.stack_top.locals.has (create {ALIAS_KEY}.make (l_target.variable_name)))
								end

								aliasses.item.add_entity (entities_caller, alias_graph.stack_top.locals)
								if tracing then
									across
										aliasses.item.entity as tt
									loop
										io.new_line
										print ("[")
										across
											tt.item as e
										loop
											print (e.item)
											print (", ")
										end
										print ("]")
									end
								end


							end
							stop (906)
							Result := get_alias_info (aliasses.item, l_node.message)
							Result.add_entity (entities_caller, alias_graph.stack_top.locals)

							aliasses.item.entity_wipe_out
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
							Result := call_routine_with_arg (aliases.item, l_routine, l_node.right)
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
							if alias_graph.stack_top.map_funct.has_key (create {ALIAS_KEY}.make (l_target.context_routine.e_feature.name_32))
								and attached l_target as l
							then
								across
									--l.entity as ent
									1 |..| l.entity.count as i
								loop
									if tracing then
										io.new_line
										print (l.entity [i.item])
									end
									aliasses.item.add_entity (l.entity [i.item],  l.entity_locals [i.item])
								end
								aliasses.item.add_entity (alias_graph.stack_top.map_funct [create {ALIAS_KEY}.make (l_target.context_routine.e_feature.name_32)],
										alias_graph.stack_top.locals)
							else
								aliasses.item.set_entity_error
							end
						else
							stop (131)
							if tracing then
								print (l_target.variable_name)
								io.new_line
							end
							if attached l_target as l then
								across
									--l_target.entity as ent
									1 |..| l_target.entity.count as i
								loop
									if tracing then
										io.new_line
										print (l_target.entity [i.item])
									end
									aliasses.item.add_entity (l_target.entity [i.item], l_target.entity_locals [i.item])
								end
							end

							entities_caller.force (l_target.variable_name)
							aliasses.item.add_entity (entities_caller, alias_graph.stack_top.locals)
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
							Result := call_routine (aliasses.item, l_routine, l_node.operands)
						end
						aliasses.item.entity_wipe_out
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
						stop (555)
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
				if tracing then
					if attached System.eiffel_universe.compiled_classes_with_name (l_node.class_name.name_8) as l_classes then -- and then l_classes.count = 1 then
						print (l_classes.count)
					end
				end
			elseif attached {CONVERTED_EXPR_AS} a_node as l_node then
				stop (9)
				Result := get_alias_info (a_target, l_node.expr)
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

	process_routine (a_target: ALIAS_OBJECT; a_routine: PROCEDURE_I; a_class_id: INTEGER; a_parameters: EIFFEL_LIST [EXPR_AS]): ALIAS_OBJECT_INFO
			-- process routine `a_routine' on target `a_target'.
			-- `a_class_id' is needed to get the type and `a_parameters' to call the routine
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			dyn_ana: BOOLEAN
		do
				-- check for "hack": special routines that do not need to be analysed
			if a_routine.e_feature.name_32 ~ "default_value" and across System.eiffel_universe.classes_with_name ("V_DEFAULT") as ancestor some System.class_of_id (a_class_id).inherits_from (ancestor.item.compiled_class) end then
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
					if attached a_target as target and then
							-- this is indeed a qualified call
						attached System.eiffel_universe.classes_with_name (target.type.name) as l_classes and then l_classes.count > 0
					then
						if l_classes.first.compiled_class.direct_descendants.count >= 1 then
							stop (907)
							alias_graph.init_dyn_bin
							dyn_ana := True
							across
								l_classes.first.compiled_class.direct_descendants as descendant
							loop
								if attached {PROCEDURE_I} descendant.item.feature_of_rout_id (a_routine.rout_id_set.first) as l_r then
									alias_graph.update_class_atts_routine_in_obj (l_r, target.attributes)
									alias_graph.init_feature_version

									Result := call_routine (target, l_r, a_parameters)
									alias_graph.restore_graph_dyn
								end
							end
						end
					end
					stop (908)
					if alias_graph.is_dyn_bin and dyn_ana then
						stop (909)
						alias_graph.init_feature_version
					end
					stop (910)
					Result := call_routine (a_target, a_routine, a_parameters)
					if alias_graph.is_dyn_bin and dyn_ana then
						alias_graph.finalising_dyn_bind
					end
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
				if n = 98 then
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
		require
			a_routine /= Void
		local
			l_params: TWO_WAY_LIST [ALIAS_OBJECT_INFO]
			may_aliasing_external: TWO_WAY_LIST [STRING]
			alias_a, alias_b: STRING
			objs: ALIAS_OBJECT
			ent_local: TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]
			tmp_entity: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]
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
						if attached a_target as target then
							create tmp_entity.make
							create ent_local.make
							across
								target.entity as ent
							loop
								tmp_entity.force (ent.item)
							end
							across
								target.entity_locals as l
							loop
								ent_local.force (l.item)
							end
							target.entity_wipe_out
						end
						l_params.extend (get_alias_info (Void, c.item))

						if attached a_target as target then
							target.entity_wipe_out
							across
								1 |..| tmp_entity.count as i
							loop
								target.add_entity (tmp_entity.at (i.item), ent_local.at (i.item))
							end
						end
					end
				end
--				if a_target /= Void then
--						-- qualified call
--					create ent_local.make
--					ent_local.force (alias_graph.stack_top.locals)
--				end
				alias_graph.stack_push (
					if a_target /= Void then a_target else alias_graph.stack_top.current_object end,
					a_routine,
					if a_target /= Void then a_target.entity else create {TWO_WAY_LIST [TWO_WAY_LIST [STRING]]}.make end,
					if a_target /= Void then a_target.entity_locals else create {TWO_WAY_LIST [HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]]}.make end,
					a_target /= Void)
				across
					l_params as c
				loop
					(create {ALIAS_OBJECT_INFO}.make_variable (alias_graph.stack_top.routine, alias_graph.stack_top.locals, a_routine.arguments.item_name (c.target_index))).alias_object := c.item.alias_object
				end
				stop (11)
				if a_routine.e_feature.name_32 ~ "out" then
					alias_by_external ("Result", "+")
					stop (150)
				elseif a_routine.access_class.name ~ "ANY" then
						-- ToDo: implement all "hacks"
					if tracing then
						io.new_line
						stop (123)
						print ("ANY Class")
						io.new_line
						print (a_routine.e_feature.name_32)
						io.new_line
					end
					stop (600)
					if a_routine.e_feature.name_32 ~ "copy" then
							-- Implementation of copy:
							--							a.copy (b)
							--								create a
							--								for_all atts in a ==> add the alias objects in b
						if tracing then
							alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
							alias_graph.print_atts_depth (alias_graph.stack_top.locals)
						end
						alias_graph.update_class_atts (alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.type.base_class, alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.attributes)
						across
							alias_graph.stack_top.locals.at (create {ALIAS_KEY}.make ("other")).first.attributes as atts
								-- note: from ANY class the name will always be 'other'
						loop
								-- wipe out all elements (if any)
							a_target.attributes.force (create {TWO_WAY_LIST [ALIAS_OBJECT]}.make, atts.key)
							if tracing then
								print (atts.key)
								print (" n: ")
								print (atts.item.count)
								io.new_line
							end
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
						if tracing then
							alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
							alias_graph.print_atts_depth (alias_graph.stack_top.locals)
						end
						alias_graph.update_class_atts (a_target.type.base_class, a_target.attributes)
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
				elseif a_routine.access_class.name ~ "SPECIAL" or a_routine.is_external then
						-- external features do not have implementation information.
						-- they should have additional information in the form of
						-- a note clause in Eiffel with tag 'external_alias'.

						-- The information of the signature is still available and needed
					may_aliasing_external := get_alias_pairs (a_routine)
					if (may_aliasing_external.count \\ 2) = 0 then
						from
							may_aliasing_external.start
						until
							may_aliasing_external.after
						loop
							alias_a := may_aliasing_external.item
							may_aliasing_external.forth
							alias_b := may_aliasing_external.item
							may_aliasing_external.forth
							if tracing then
								print_aliases (alias_a, alias_b)
							end
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
			if tracing then
				alias_graph.print_atts_depth (alias_graph.stack_top.current_object.attributes)
				alias_graph.print_atts_depth (alias_graph.stack_top.locals)
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
						across
							s as objs
						loop
							if not graph.at (val).has (objs.item) then
								across
									graph as g
								loop
									if g.key.name ~ val.name then
										g.key.set_assigned
									end
								end
								graph.at (val).force (objs.item)
							end
						end
					else -- create
						type := graph.at (val).first.type
						graph.at (val).wipe_out
						graph.at (val).force (create {ALIAS_OBJECT}.make (type))
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
