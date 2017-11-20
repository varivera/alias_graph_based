note
	description: "The gui view of all tools."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	VERIFICATION_VIEW

inherit

	EV_HORIZONTAL_BOX
		select
			is_equal,
			default_create,
			copy
		end

	SHARED_SERVER
		rename
			is_equal as is_equal_shared,
			default_create as default_create_shared,
			copy as copy_shared
		end

create
	make

feature {NONE}

	feature_view: EB_ROUTINE_FLAT_FORMATTER

	info_text: EV_TEXT

	make (a_develop_window: EB_DEVELOPMENT_WINDOW)
		local
			l_drop_actions: EV_PND_ACTION_SEQUENCE
		do
			default_create
			create l_drop_actions
			l_drop_actions.extend (agent on_stone_changed)
			create feature_view.make (a_develop_window)
			feature_view.set_editor_displayer (feature_view.displayer_generator.any_generator.item ([a_develop_window, l_drop_actions]))
			feature_view.set_combo_box (create {EV_COMBO_BOX}.make_with_text ((create {INTERFACE_NAMES}).l_Flat_view))
			feature_view.on_shown
			feature_view.editor.margin.margin_area.pointer_button_release_actions.wipe_out
			create info_text
			info_text.disable_edit
			extend (feature_view.editor.widget)
			extend (info_text)
		end

	reset
		do
			feature_view.editor.clear_window
			info_text.set_text ("")
		end

	on_stone_changed (a_stone: STONE)
		local
			l_result: STRING
			ver1_mq_inherited: PLAIN_TEXT_FILE
			ver1_mq_not_inherited: PLAIN_TEXT_FILE
			ver2_mq_inherited: PLAIN_TEXT_FILE
			ver2_mq_not_inherited: PLAIN_TEXT_FILE
			map: PLAIN_TEXT_FILE
		do
			reset
			l_result := ""
			print ("%N=================================================================%N")
			print ("%N=================================================================%N")
			print ("%N=================================================================%N")
			create ver1_mq_inherited.make_open_write ((create {TRACING}).ver1_file)
			ver1_mq_inherited.put_string ("Class Name,Feature Name,Atts changed, MQ changed, Allow to Change (modify clause), Ver%N")
			create ver1_mq_not_inherited.make_open_write ((create {TRACING}).ver1_a_file)
			ver1_mq_not_inherited.put_string ("Class Name,Feature Name,Atts changed, MQ changed, Allow to Change (modify clause), Ver%N")
			create ver2_mq_inherited.make_open_write ((create {TRACING}).ver2_file)
			ver2_mq_inherited.put_string ("Class Name,Feature Name,Allow to Change (may change), Allow to Change (mapped), Atts changed, Ver%N")
			create ver2_mq_not_inherited.make_open_write ((create {TRACING}).ver2_a_file)
			ver2_mq_not_inherited.put_string ("Class Name,Feature Name,Allow to Change (may change), Allow to Change (mapped), Atts changed, Ver%N")
			create map.make_open_write ((create {TRACING}).map_file)
			map.put_string ("Class Name,Map (no inherited),Map (inherited)%N")


			if attached {CLUSTER_STONE} a_stone as fs then
				clusters (fs.cluster_i, l_result, ver1_mq_inherited, ver1_mq_not_inherited, ver2_mq_inherited, ver2_mq_not_inherited, map)
			elseif attached {FEATURE_STONE} a_stone as fs and then attached {E_ROUTINE} fs.e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
					--feature_view.set_stone (a_stone)
				do_nothing
			elseif attached {CLASSC_STONE} a_stone as c and then attached {CLASS_C} c.class_i.compiled_class as cla then
				class_to_analyse (cla, cla.name, l_result, ver1_mq_inherited, ver1_mq_not_inherited, ver2_mq_inherited, ver2_mq_not_inherited, map)
			end

			ver1_mq_inherited.close
			ver1_mq_not_inherited.close
			ver2_mq_inherited.close
			ver2_mq_not_inherited.close
			map.close
			info_text.set_text (l_result)
		end

	clusters (c: CLUSTER_I; a_result: STRING; ver1_mq_inherited, ver1_mq_not_inherited, ver2_mq_inherited, ver2_mq_not_inherited, map: PLAIN_TEXT_FILE)
			-- Apply verification to all classes in cluster `c' (including nested
			-- clusters)
		local
			class_: CLASS_C
		do
			print ("%N=================================================================%N")
			print ("Cluster: " + c.cluster_name)
			print ("%N=================================================================%N")
			io.new_line
			io.new_line
			across
				c.classes as cla
			loop
				class_ := System.eiffel_universe.classes_with_name (cla.item.actual_class.name).first.compiled_class
				class_to_analyse (class_, cla.item.actual_class.name, a_result, ver1, ver1_a, ver2, map)
			end
			io.new_line
			io.new_line
			if attached c.sub_clusters as sc then
				across
					sc as clu
				loop
					clusters (clu.item, a_result, ver1, ver1_a, ver2, map)
				end
			end
		end

	class_to_analyse (class_: CLASS_C; actual_class_name, a_result: STRING; ver1_mq_inherited, ver1_mq_not_inherited, ver2_mq_inherited, ver2_mq_not_inherited, map: PLAIN_TEXT_FILE)
			-- different analysis
		local
			map_model_query_to_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- mapping from MQ to class attributes

			map_model_query_to_atts2: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- mapping from MQ to class attributes (no inheriting MQ)

			modified_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modified attributes per feature in class `class_'
			queries_modify_clause: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modify clauses per feature in class `class_'

			may_change: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
			-- set of model queries allowed to be modified in class `class_' by features
		do
			if not actual_class_name.starts_with ("MML_")
				and not (actual_class_name ~ "V_STRING_INPUT")
				and not (actual_class_name ~ "V_DEFAULT")
				and not class_.is_deferred
			then
				if System.eiffel_universe.classes_with_name (actual_class_name).count = 1 then
					print ("Class: " + actual_class_name)
					io.new_line
					create map_model_query_to_atts.make (0)
					create modified_atts.make (0)
					create queries_modify_clause.make (0)
					create may_change.make (0)
					map_mq_to_atts (class_, class_.class_id, actual_class_name, map_model_query_to_atts)
					change_modify_may (class_, actual_class_name, modified_atts, queries_modify_clause, may_change)

					--verification_1 (modified_atts, map_model_query_to_atts, queries_modify_clause, actual_class_name, ver1)
						-- without carrying our model queries
					create map_model_query_to_atts2.make (0)
					map_mq_to_atts_no_inheriting_mq (class_, class_.class_id, actual_class_name, map_model_query_to_atts2)
					verification_1 (modified_atts, map_model_query_to_atts2, queries_modify_clause, actual_class_name, ver1_a)
					verification_2 (modified_atts, map_model_query_to_atts, may_change, actual_class_name, ver2)
					--verification_2 (modified_atts, map_model_query_to_atts, may_change, actual_class_name, ver2)


					visualisation (map_model_query_to_atts, map_model_query_to_atts2, modified_atts, queries_modify_clause, may_change, class_.name, a_result)
					map.put_string (actual_class_name + "," + map_to_string_no_commas (map_model_query_to_atts2) + "," + map_to_string_no_commas (map_model_query_to_atts) + "%N")
				end
			end
		end

	verification_1 (modified_atts, map_model_query_to_atts, queries_modify_clause: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; class_name: STRING; res: PLAIN_TEXT_FILE)
			-- the result of change calculus should be a subset of
			-- the set of the modify clause
			-- it reports the result is res
		require
			modified_atts.count = queries_modify_clause.count
		local
			changed, allow_to_change: TWO_WAY_LIST [STRING]
			mapped_modified_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
		do
--			print ("%N==========================================================%N")
--			print (map_to_string (map_model_query_to_atts))
--			print ("%N==========================================================%N")
--			print (map_to_string (modified_atts))
--			print ("%N==========================================================%N")
--			--print (map_to_string (atts_to_model_queries (map_model_query_to_atts, modified_atts)))
--			print ("%N==========================================================%N")
			mapped_modified_atts := atts_to_model_queries (map_model_query_to_atts, modified_atts)
			across
				mapped_modified_atts as feat
			loop
				check modified_atts.has (feat.key) end
				changed := modified_atts[feat.key]
				allow_to_change := get_map (map_model_query_to_atts, queries_modify_clause [feat.key])
				res.put_string (class_name + "," + feat.key + "," + list_to_string (changed) + "," + list_to_string (feat.item) + "," +
				list_to_string (queries_modify_clause [feat.key]) + "," + set_relation (feat.item, queries_modify_clause[feat.key]).out + "%N")
			end
		end

	atts_to_model_queries (mq_map, modified_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
			-- given the map between model queries and class attributes they depend on
			-- and the map between features and actual class attibutes being modified by features
			-- returns for each feature the set of modified model queries
		local
			tmp: TWO_WAY_LIST [STRING]
		do
			create Result.make (modified_atts.count)
			across
				modified_atts as feat
			loop
				Result.force (create {TWO_WAY_LIST [STRING]}.make, feat.key)
				across
					feat.item as atts
				loop
					across
						mq_map as mq
					loop
						if is_in_list (atts.item, mq.item) then
							across
								Result[feat.key] as i
							loop
								print (i.item)
								io.new_line
							end
							print (mq.key)
							io.new_line
							print ("%N"+feat.key+"====%N")
							if not is_in_list (mq.key, Result [feat.key]) then
								Result [feat.key].force (mq.key)
							end

						end
					end
				end
			end

			create tmp.make
			tmp.force ("a")
			tmp.force ("c")
			tmp.force ("d")

			print (is_in_list("d",tmp))
			print (is_in_list("f",tmp))

		end

	is_in_list (e: STRING; l: TWO_WAY_LIST [STRING]): BOOLEAN
		do
			Result := across l as elems some e ~ elems.item  end
		end

	verification_2 (modified_atts, map_model_query_to_atts, may_change: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; class_name: STRING; res: PLAIN_TEXT_FILE)
			-- the result of change calculus should be a subset of
			-- the set of the may change
			-- it reports the result is res
		require
			modified_atts.count = may_change.count
		local
			changed, allow_to_change: TWO_WAY_LIST [STRING]
		do
			across
				modified_atts as feat
			loop
				changed := feat.item
				allow_to_change := get_map (map_model_query_to_atts, may_change [feat.key])
				res.put_string (class_name + "," + feat.key + "," + list_to_string (may_change [feat.key]) + "," + list_to_string (allow_to_change) + "," + list_to_string (changed) + "," + set_relation (changed, allow_to_change).out + "%N")
			end
		end

	list_to_string (l: TWO_WAY_LIST [STRING]): STRING
		do
			Result := "["
			across
				l as i
			loop
				Result := Result + i.item
				if not i.is_last then
					Result := Result + "-"
				end
			end
			Result := Result + "]"
		end

	get_map (mq: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; queries: TWO_WAY_LIST [STRING]): TWO_WAY_LIST [STRING]
		do
			create Result.make
			across
				queries as q
			loop
				if mq.has (q.item) then
					Result.append (mq [q.item])
				else
					Result.force ("*" + q.item + "*")
				end
			end
		end

	set_relation (set1, set2: TWO_WAY_LIST [STRING]): INTEGER
		do
			if set1.count > set2.count then
				Result := 3
			else
				Result := if across set1 as e all across set2 as e2 some e.item ~ e2.item end end then if set1.count = set2.count then 2 else 1 end else 3 end
			end
		ensure
			Result = 1 or Result = 2 or Result = 3
				-- Result = 1 implies set1.is_subset (set2)
				-- Result = 2 implies set1 = set2
				-- Result = 3 impliens set1 /= set2
		end

	map_mq_to_atts (class_: CLASS_C; class_base_id: INTEGER; actual_class_name: STRING; mq: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
			-- it stores the map between Model Queries and Class Attributes for class `class_id'
		local
			l_visitor: MQ_ANALYSIS_VISITOR
			mqs: TWO_WAY_LIST [STRING]
		do
			create mqs.make
			find_model_queries (class_, mqs)

			across
				mqs as m
			loop
				print (m.item)
				io.new_line
			end

			if
				class_.name ~ "V_ARRAYED_LIST_ITERATOR"
				or class_.name ~ "V_ARRAY_ITERATOR"
				or class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR"
				or class_.name ~ "V_LINKED_LIST_ITERATOR"
			then
				across
					mqs as e
				loop
					if e.item ~ "key_sequence" then
						e.item.replace_substring_all ("key_sequence", "target_index_sequence")
					end
				end
			end
			if
				class_.name ~ "V_SET_TABLE_ITERATOR"
			then
				across
					mqs as e
				loop
					if e.item ~ "sequence" then
						e.item.replace_substring_all ("sequence", "value_sequence")
					end
				end
			end

			across
				mqs as model
			loop

				if class_.feature_named_32 (model.item).is_attribute then
					mq.force (create {TWO_WAY_LIST [STRING]}.make, model.item)
					mq [model.item].force (model.item)
				elseif attached {E_ROUTINE} class_.feature_named_32 (model.item).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine and then r.is_function then
					if not r.is_deferred
						-- apparently they do not need to be MML and then r.type.actual_type.name.starts_with ("MML")
					then
						print ("Mapping - Feature: " + model.item)
						io.new_line
						create l_visitor.make (class_base_id)
						routine.body.process (l_visitor)
						mq.force (l_visitor.mq_list, r.name_32)
					else
						mq.force (create {TWO_WAY_LIST [STRING]}.make, r.name_32)
						mq [r.name_32].force (r.name_32 + "*")
					end
				end
			end
		end


	map_mq_to_atts_no_inheriting_mq (class_: CLASS_C; class_base_id: INTEGER; actual_class_name: STRING; mq: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
			-- it stores the map between Model Queries and Class Attributes for class `class_id'
		local
			l_visitor: MQ_ANALYSIS_VISITOR
			mqs: TWO_WAY_LIST [STRING]
		do
			create mqs.make
			find_model_queries2 (class_, mqs)

			across
				mqs as m
			loop
				print (m.item)
				io.new_line
			end

			across
				mqs as model
			loop

				if class_.feature_named_32 (model.item).is_attribute then
					mq.force (create {TWO_WAY_LIST [STRING]}.make, model.item)
					mq [model.item].force (model.item)
				elseif attached {E_ROUTINE} class_.feature_named_32 (model.item).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine and then r.is_function then
					if not r.is_deferred
						-- apparently they do not need to be MML and then r.type.actual_type.name.starts_with ("MML")
					then
						print ("Mapping - Feature: " + model.item)
						io.new_line
						create l_visitor.make (class_base_id)
						routine.body.process (l_visitor)
						mq.force (l_visitor.mq_list, r.name_32)
					else
						mq.force (create {TWO_WAY_LIST [STRING]}.make, r.name_32)
						mq [r.name_32].force (r.name_32 + "*")
					end
				end
			end
		end

	change_modify_may (class_: CLASS_C; actual_class_name: STRING; atts_mod, mc, may: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
			-- stores the modified attributes per feature in class `class' and the set of modify mq it lists
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > class_.feature_table.count or class_.is_deferred
			loop
				if not class_.feature_table.features.at (i).is_attribute and class_.feature_table.features.at (i).e_feature.associated_class.class_id = class_.class_id and attached {E_ROUTINE} class_.feature_table.features.at (i).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
						-- feature with issues
					if (
						class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "test_prepend"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend_at"))
					and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "subtree_twin"))
					and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
					and (class_.name ~ "V_SORTED_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "remove"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend"))
					and (class_.name ~ "V_HASH_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "search"))
					and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make_at_key"))
					and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "search_key"))
					and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "less_equal"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "item"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "at"))
					and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "less_equal"))
					and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_one"))
					and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_one_predicate"))
					and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_two"))
					and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_two_predicate"))
					and (class_.name ~ "V_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "default_create"))
					and (class_.name ~ "V_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "default_create")) and
					(class_.name ~ "V_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "with_object_equality")) and
					(class_.name ~ "V_GENERAL_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make")) and
					(class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make")) and
					(class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "key_equivalence")) and
					(class_.name ~ "V_REFERENCE_HASHABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "hash_code")) and
					(class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy")) and
					(class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "key")) and
					(class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "item")) and
					(class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend")) and
					(class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at")) and
					(class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend")) and
					(class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at")) and
					not (class_.feature_table.features.at (i).e_feature.name_32 ~ "out") then
						if class_.feature_table.features.at (i).e_feature.is_function implies not class_.feature_table.features.at (i).e_feature.type.actual_type.name.starts_with ("MML") then
							print ("Feature: " + routine.e_feature.name_32)
							io.new_line
							print ("   change")
							io.new_line
							change_analysis (routine, atts_mod)
							print ("   modify")
							io.new_line
							modify_clause (routine, class_.class_id, mc)
							print ("   may change")
							io.new_line
							may_modify (routine, may)
						end
					end
				end
				i := i + 1
			end
		end

	change_analysis (routine: PROCEDURE_I; atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
		do
			create l_visitor.make (routine, Void)
			routine.body.process (l_visitor)
			atts_mod.force (l_visitor.alias_graph.change_atts, routine.e_feature.name_32)
		end

	modify_clause (routine: PROCEDURE_I; class_id: INTEGER; mc: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
		local
			modify: MODIFY_CLAUSES_VISITOR
		do
			create modify.make (class_id, routine.e_feature.name_32)
			routine.body.process (modify)
			mc.force (modify.modify_clause_list, routine.e_feature.name_32)
		end

	may_modify (routine: PROCEDURE_I; may: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
		local
			l_visitor: MAY_CHANGE_VISITOR
			assertion_server: ASSERTION_SERVER
		do
			if routine.e_feature.name_32 ~ "make" then
				print ("")
			end
			if not routine.is_function then
				create l_visitor.make (routine)
				across
					routine.access_class.parents_classes as c
				loop
					c.item.ast.top_indexes.process (l_visitor)
					find_ancestors (c.item, l_visitor)
				end
				routine.access_class.ast.top_indexes.process (l_visitor)
				create assertion_server.make_for_feature (routine, routine.body)
				across
					assertion_server.current_assertion as c
				loop
					if c.item.postcondition /= VOID then
						c.item.postcondition.process (l_visitor)
					end
				end

					--			routine.access_class.ast.features.process (l_visitor)

				across
					routine.access_class.constant_features as constants
				loop
					if l_visitor.may_change_list.has (constants.item.name_8) then
						l_visitor.may_change_list.prune (constants.item.name_8)
					elseif l_visitor.may_change_query_list.has (constants.item.name_8) then
						l_visitor.may_change_query_list.prune (constants.item.name_8)
					end
				end

					-- For non-model queries  l_visitor.may_change_list as i

				may.force (l_visitor.may_change_query_list, routine.e_feature.name_32)
			else
				may.force (create {TWO_WAY_LIST [STRING]}.make, routine.e_feature.name_32)
			end
		end

	find_ancestors (cl: CLASS_C; visitor: MAY_CHANGE_VISITOR)
		do
			if cl.parents_classes /= VOID then
				across
					cl.parents_classes as c
				loop
					c.item.ast.top_indexes.process (visitor)
					find_ancestors (c.item, visitor)
				end
			end
		end

	find_model_queries (c: CLASS_C; res: TWO_WAY_LIST [STRING])
			-- finds the model queries of class `c' and its descendants
		do
			if attached c.ast.top_indexes as top_indexes then
				across
					top_indexes as i
				loop
					if i.item.tag.name_32 ~ "model" then
						across
							i.item.index_list as ii
						loop
							if across res as mq all mq.item /~ ii.item.string_value_32 end then
								res.force (ii.item.string_value_32)
							end
						end
					end
					across
						System.class_of_id (c.class_id).parents_classes as p
					loop
						if p.item.name /~ "ANY" then
							find_model_queries (p.item, res)
						end
					end
				end
			end
		end

	find_model_queries2 (c: CLASS_C; res: TWO_WAY_LIST [STRING])
			-- finds the model queries of class `c' and its descendants
		do
			if attached c.ast.top_indexes as top_indexes then
				across
					top_indexes as i
				loop
					if i.item.tag.name_32 ~ "model" then
						across
							i.item.index_list as ii
						loop
							if across res as mq all mq.item /~ ii.item.string_value_32 end then
								res.force (ii.item.string_value_32)
							end
						end
					end
				end
			end
		end

	map_to_string (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as mq
			loop
				if mq.item.count > 0 then
					Result := Result + "     " + mq.key + ": ["
					across
						mq.item as att
					loop
						Result := Result + att.item
						if not att.is_last then
							Result := Result + ", "
						end
					end
					Result := Result + "]"
				end
				Result := Result + "%N"
			end
		end

	map_to_string_no_commas (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := "{"
			across
				res as mq
			loop
				if mq.item.count > 0 then
					Result := Result + "" + mq.key + ": ["
					across
						mq.item as att
					loop
						Result := Result + att.item
						if not att.is_last then
							Result := Result + "-"
						end
					end
					Result := Result + "]"
				end
				Result := Result + " - "
			end
			Result := Result + "}"
		end

	atts_mod_to_string (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as feat
			loop
				Result := Result + feat.key + ": ["
				across
					feat.item as atts
				loop
					Result := Result + atts.item
					if not atts.is_last then
						Result := Result + ", "
					end
				end
				Result := Result + "]%N"
			end
		end

	visualisation (mq, mq2, atts_mod, mc, may_change: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; class_name, a_result: STRING)
		local
			tmp: STRING
		do
			a_result.append ("Class: ")
			a_result.append (class_name)
			a_result.append ("%N%NMap from MQ to Class Attributes%N")
			a_result.append (map_to_string (mq))
			a_result.append ("%N%NMap from MQ to Class Attributes (no inherited MQ)%N")
			a_result.append (map_to_string (mq2))
			a_result.append ("%NModified Class Attributes per feature%N")
			a_result.append (atts_mod_to_string (atts_mod))
			a_result.append ("%NModified Clause by feature%N")
			across
				mc as feat
			loop
				a_result.append (feat.key + ": [")
				tmp := "["
				across
					feat.item as mod_clause
				loop
					a_result.append (mod_clause.item)
					if not mod_clause.is_last then
						a_result.append (", ")
					end
					if mq.has (mod_clause.item) then
						across
							mq [mod_clause.item] as map
						loop
							tmp := tmp + map.item
							if not feat.is_last or not mod_clause.is_last then
								tmp := tmp + ", "
							end
						end
					else
						tmp := tmp + "*" + mod_clause.item + "*,"
					end
				end
				tmp := tmp + "]%N"
				a_result.append ("] -- " + tmp)
			end
			a_result.append ("%NMay change atts by feature%N")
			across
				may_change as feat
			loop
				a_result.append (feat.key + ": [")
				tmp := "["
				across
					feat.item as mod_clause
				loop
					a_result.append (mod_clause.item)
					if not mod_clause.is_last then
						a_result.append (", ")
					end
					if mq.has (mod_clause.item) then
						across
							mq [mod_clause.item] as map
						loop
							tmp := tmp + map.item
							if not feat.is_last or not mod_clause.is_last then
								tmp := tmp + ", "
							end
						end
					else
						tmp := tmp + "*" + mod_clause.item + "*,"
					end
				end
				tmp := tmp + "]%N"
				a_result.append ("] -- " + tmp)
			end
		end


invariant
	feature_view /= Void

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
