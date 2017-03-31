note
	description: "The gui view of the alias analysis tool."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	ALIAS_ANALYZER_CLUSTER

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
			extend (feature_view.editor.widget)
		end

	reset
		do
			feature_view.editor.clear_window
		end

	clusters (c: CLUSTER_I)
			-- Apply alias analysis to all classes in cluster `c' (including nested
			-- clusters)
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
			routine: PROCEDURE_I
			class_: CLASS_C
			i: INTEGER
		do
			print (c.cluster_name)
			io.new_line
			io.new_line
			across
				c.classes as cla
			loop
				if not cla.item.actual_class.name.starts_with ("MML_") and
					not (cla.item.actual_class.name ~ "V_STRING_INPUT") and
					not (cla.item.actual_class.name ~ "V_DEFAULT")
				then
					if System.eiffel_universe.classes_with_name (cla.item.actual_class.name).count = 1 then
						print ("Class being analysed: ")
						print (cla.item.actual_class.name)
						print (": ")
						print (System.eiffel_universe.classes_with_name (cla.item.actual_class.name).count)
						io.new_line
						io.new_line
						class_ := System.eiffel_universe.classes_with_name (cla.item.actual_class.name).first.compiled_class
						print ("Analysis%N")
						from
							i := 1
						until
							i > class_.feature_table.count or
							class_.is_deferred
						loop
							if not class_.feature_table.features.at (i).is_attribute
								and class_.feature_table.features.at (i).e_feature.associated_class.class_id = class_.class_id
								and attached {E_ROUTINE} class_.feature_table.features.at (i).e_feature as r
								and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as p
							-- TODO
								and not (class_.feature_table.features.at (i).e_feature.name_32 ~ "out")
								and (class_.name ~ "V_REFERENCE_HASHABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "hash_code"))
								and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "test_insert_left"))
								and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
								and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "test_index"))
								and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "index"))
								and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
								and (class_.name ~ "V_SORTED_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "start"))
								and (class_.name ~ "V_SORTED_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "finish"))
							then
								print ("====Feature: ")
								print (class_.feature_table.features.at (i).e_feature.name_32)
								print ("==(")
								print (cla.item.actual_class.name)
								print (")==========")
								io.new_line
								routine := p
								if class_.feature_table.features.at (i).e_feature.is_function implies
									not class_.feature_table.features.at (i).e_feature.type.actual_type.name.starts_with ("MML") then
									create l_visitor.make (routine, Void)
									routine.body.process (l_visitor)
									io.new_line
									print (l_visitor.alias_graph.to_string)
									io.new_line
									print (l_visitor.alias_graph.to_graph)
									io.new_line

	--								(create {EXECUTION_ENVIRONMENT}).launch (
	--									"echo %"" + l_visitor.alias_graph.to_graph + "%" | dot -Tpdf | okular - 2>/dev/null"
	--								)
								end
							end
							i := i + 1
						end
					end
				end
			end
			io.new_line
			io.new_line
			if attached c.sub_clusters as sc then
				across
					sc as clu
				loop
					clusters (clu.item)
				end
			end
		end

	on_stone_changed (a_stone: STONE)
		do
			reset
			print ("%N=================================================================%N")
			if attached {CLUSTER_STONE} a_stone as fs then
				clusters (fs.cluster_i)
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
