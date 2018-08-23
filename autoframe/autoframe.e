note
	description: "The gui view of all tools."
	date: "August, 2018" 
	author: "Victor Rivera"

class
	AUTOFRAME

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
			info_text.set_text ("Processing")
		end

	on_stone_changed (a_stone: STONE)
			-- the analysis starts when the users makes a change in the stone (i.e. drag and drop a
			-- feature, class or clauster into AutroFrame's graphical window.
		local
			l_result: STRING
			info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING]
		do
			reset
			l_result := ""
			print ("%N=================================================================%N")
			print ("%N=================================================================%N")
			print ("%N=================================================================%N")
			create info.make (0)
			if attached {CLUSTER_STONE} a_stone as fs then
				clusters (fs.cluster_i, l_result, info)
			elseif attached {FEATURE_STONE} a_stone as fs and then attached {E_ROUTINE} fs.e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
					--feature_view.set_stone (a_stone)
					feature_to_analyse (routine, routine.access_class.name, l_result, info)
			elseif attached {CLASSC_STONE} a_stone as c and then attached {CLASS_C} c.class_i.compiled_class as cla then
				class_to_analyse (cla, l_result,info)
			end
			info_text.set_text (l_result)


			print_info (info)
			--print_info_fail (info)
			--print_info_scv (info)
		end

	clusters (c: CLUSTER_I; a_result: STRING; info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
			-- Apply AutoFraming to all classes in cluster `c' (including nested
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
				class_to_analyse (class_, a_result, info)
			end
			io.new_line
			io.new_line
			if attached c.sub_clusters as sc then
				across
					sc as clu
				loop
					clusters (clu.item, a_result, info)
				end
			end
		end

	class_to_analyse (class_: CLASS_C; a_result: STRING; info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
			-- Apply Autoframe to each feautre of class `class_'.
		local
			modified_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modified attributes per feature in class `class_'

			actual_class_name: STRING

			i: INTEGER
			t: TUPLE [name:STRING; time:REAL_64; only_clause: TWO_WAY_LIST [STRING]]
		do
			actual_class_name := class_.name
			if not actual_class_name.starts_with ("MML_")
				and (actual_class_name /~ "V_HASH_LOCK")  --for verification purposes, no need during the analysis
				and (actual_class_name /~ "V_LOCK")  --for verification purposes, no need during the analysis
			then
				if not class_.is_deferred then

					if System.eiffel_universe.classes_with_name (actual_class_name).count = 1 then
						print ("Class: " + actual_class_name)
						if not info.has_key (actual_class_name) then
							info.put (create {ARRAYED_LIST [TUPLE [name:STRING; time:REAL_64; only_clause: TWO_WAY_LIST [STRING]]]}.make (40), actual_class_name)
						end
						io.new_line
						create modified_atts.make (0)
						analyse_class (class_, modified_atts, info)
						visualisation (modified_atts, class_.name, a_result)
					end
				else
					info.force (create {ARRAYED_LIST [TUPLE [name:STRING; time:REAL_64; only_clause: TWO_WAY_LIST [STRING]]]}.make (0), class_.name+"**")
					from
						i := 1
					until
						i > class_.feature_table.count
					loop
						if not class_.feature_table.features.at (i).is_attribute and
						class_.feature_table.features.at (i).e_feature.associated_class.class_id = class_.class_id
						 and attached {E_ROUTINE} class_.feature_table.features.at (i).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
							create t
							t.name := routine.e_feature.name_32+"**"
							t.time := 0
							t.only_clause := create {TWO_WAY_LIST [STRING]}.make
							info.at (class_.name+"**").force (t)
						end
						i := i + 1
					end
				end
			end
		end

	feature_to_analyse (routine: PROCEDURE_I; class_name: STRING; a_result: STRING; info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
			-- Apply Autoframe to each feautre of class `class_'.
		local
			modified_atts: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modified attributes per feature in class `class_'
		do
			create modified_atts.make (0)
			analyse_feature (routine, class_name, modified_atts, info)
			visualisation (modified_atts, class_name, a_result)
		end


	analyse_class (class_: CLASS_C; atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
			-- stores the modified attributes per feature in class `class'
		local
			i: INTEGER
			actual_class_name: STRING
		do
			actual_class_name := class_.name
			from
				i := 1
			until
				i > class_.feature_table.count or class_.is_deferred
			loop
				if not class_.feature_table.features.at (i).is_attribute and class_.feature_table.features.at (i).e_feature.associated_class.class_id = class_.class_id
				 and attached {E_ROUTINE} class_.feature_table.features.at (i).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
					analyse_feature (routine, actual_class_name, atts_mod, info)
				end
				i := i + 1
			end
		end

	analyse_feature (routine: PROCEDURE_I; class_name: STRING; atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
			feature_name: STRING
			start_time, finish_time: DATE_TIME
			t: TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]
		do
			feature_name := routine.e_feature.name_32

			if
				(class_name ~ "V_DOUBLY_LINKED_LIST" implies not (feature_name ~ "prepend")) and
				(class_name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (feature_name ~ "insert_left")) and
				(class_name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (feature_name ~ "insert_right")) and
				(class_name ~ "V_DOUBLY_LINKED_LIST" implies not (feature_name ~ "insert_at")) and

				-- HW
				(class_name ~ "EV_EDITABLE_LIST" implies not (feature_name ~ "extend")) and
				(class_name ~ "EV_EDITABLE_LIST" implies not (feature_name ~ "change_widget_type")) and
				(class_name ~ "EV_EDITABLE_LIST" implies not (feature_name ~ "generate_edit_dialog")) and
				(class_name ~ "EV_EDITABLE_LIST" implies not (feature_name ~ "update_actions")) and
				(class_name ~ "EV_EDITABLE_LIST" implies not (feature_name ~ "resized")) and
				(True implies not (feature_name ~ "put_pixmap_on_right")) and
				(class_name ~ "EV_GRID_PIXMAPS_ON_RIGHT_LABEL_ITEM" implies not (feature_name ~ "computed_initial_grid_label_item_layout")) and
				(class_name ~ "EV_PATH_FIELD" implies not (feature_name ~ "browse_for_save_file")) and
				(class_name ~ "EV_PATH_FIELD" implies not (feature_name ~ "browse_for_open_file")) and
				(class_name ~ "EV_PATH_FIELD" implies not (feature_name ~ "browse_for_file")) and
				(class_name ~ "EV_RICH_TEXT_TAB_POSITIONER" implies False) and
				(class_name ~ "EV_TOP_LEFT_SCROLLABLE_AREA" implies not (feature_name ~ "on_mouse_wheel")) and
				(class_name ~ "EV_TOP_LEFT_SCROLLABLE_AREA" implies not (feature_name ~ "on_refresh")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "enable_top_widget_resizing")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "disable_top_widget_resizing")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "extend")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "close_actions")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "insert_widget")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "remove")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "wipe_out")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "maximize_item")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "minimize_item")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "restore_item")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "set_heights_no_resize")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "set_heights")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "rebuild")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "initialize_docking_areas")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "remove_docking_areas")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "maximize_tool")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "restore_maximized_tool")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "restore_stored_positions")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "minimize_tool")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "restore_minimized_tool")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "minimize_all_tools")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "update_all_minimize_buttons")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "unparent_all_holders")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "remove_implementation")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA" implies not (feature_name ~ "restore_heights_post_insertion")) and
				(class_name ~ "MULTIPLE_SPLIT_AREA_TOOL_HOLDER" implies False) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM_I" implies not (feature_name ~ "make")) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM_I" implies not (feature_name ~ "set_is_checked")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "index_of_first_item")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "item")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "selected_items")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "virtual_x_position_unlocked")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "lock_at_position")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "unlock")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "hide")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "show")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "ensure_visible")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "required_width_of_item_span")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "enable_select")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "disable_select")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "is_selected")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "set_item")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "set_background_color")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "set_foreground_color")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "set_width")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "clear")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "redraw")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "destroy")) and
				((
					class_name ~ "EV_GRID_COLUMN_I" or class_name ~ "EV_GRID_ROW_I"
					) implies not (feature_name ~ "internal_update_selection")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "activate")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "deactivate")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "enable_select")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "disable_select")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "ensure_visible")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "redraw")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "set_background_color")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "set_foreground_color")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "enable_select_internal")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "disable_select_internal")) and
				(class_name ~ "EV_GRID_ITEM_I" implies not (feature_name ~ "destroy")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "internal_are_all_non_void_items_selected")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "virtual_y_position_unlocked")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "expand")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "collapse")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "set_height")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "ensure_expandable")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "ensure_non_expandable")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "add_subrow")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "insert_subrows")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "remove_subrow")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "add_subrows_internal")) and
				(class_name ~ "EV_GRID_ROW_I" implies not (feature_name ~ "update_for_removal")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "set_line_width")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "set_foreground_color")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "save_to_named_path")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_point")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_text")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_text_top_left")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_ellipsed_text")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_ellipsed_text_top_left")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_rotated_text")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_pixmap")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_arc")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_ellipse")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_pie_slice")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "fill_ellipse")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "fill_pie_slice")) and
				(class_name ~ "EV_POSTSCRIPT_DRAWABLE_IMP" implies not (feature_name ~ "draw_pie_slice_ps")) and
				(class_name ~ "EV_GRID_ARRAYED_LIST" implies not (feature_name ~ "resize")) and
				(class_name ~ "EV_GRID_DRAWER_I" implies not (feature_name ~ "item_at_virtual_position")) and
				(class_name ~ "EV_GRID_DRAWER_I" implies not (feature_name ~ "row_at_virtual_position")) and
				(class_name ~ "EV_GRID_DRAWER_I" implies not (feature_name ~ "column_at_virtual_position")) and
				(class_name ~ "EV_GRID_DRAWER_I" implies not (feature_name ~ "item_coordinates_at_position")) and
				(class_name ~ "EV_GRID_DRAWER_I" implies False) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "append_text_for_rtf")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "set_with_rtf")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "process_keyword")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "process_fonttable")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "add_font_to_all_fonts")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "process_colortable")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "build_font_from_format")) and
				(class_name ~ "EV_RICH_TEXT_BUFFERING_STRUCTURES_I" implies not (feature_name ~ "build_color_from_format")) and
				(class_name ~ "EV_SHARED_TRANSPORT_I" implies not (feature_name ~ "global_pnd_targets")) and
				(class_name ~ "EV_SHARED_TRANSPORT_I" implies not (feature_name ~ "global_drag_targets")) and
				(class_name ~ "EV_SHARED_TRANSPORT_I" implies not (feature_name ~ "insert_label")) and
				(class_name ~ "EV_COLUMN_ACTION_SEQUENCE" implies not (feature_name ~ "new_filled_list")) and
				(not (feature_name ~ "new_filled_list")) and
				(not (feature_name ~ "call")) and
				(class_name ~ "EV_DRAWING_AREA_PROJECTOR" implies False) and
				(class_name ~ "EV_FIGURE_EQUILATERAL" implies not (feature_name ~ "polygon_array")) and

				(class_name ~ "EV_ARROWED_FIGURE" implies False) and
				(class_name ~ "EV_ATOMIC_FIGURE" implies False) and
				(class_name ~ "EV_CLOSED_FIGURE" implies False) and
				(class_name ~ "EV_DOUBLE_POINTED_FIGURE" implies False) and
				(class_name ~ "EV_DRAWING_AREA_PROJECTOR" implies False) and
				(class_name ~ "EV_FIGURE" implies False) and
				(class_name ~ "EV_FIGURE_ARC" implies False) and
				(class_name ~ "EV_FIGURE_DOT" implies False) and
				(class_name ~ "EV_FIGURE_DRAWER" implies False) and
				(class_name ~ "EV_FIGURE_DRAWING_ROUTINES" implies False) and
				(class_name ~ "EV_FIGURE_ELLIPSE" implies False) and
				(class_name ~ "EV_FIGURE_EQUILATERAL" implies False) and
				(class_name ~ "EV_FIGURE_GROUP" implies False) and
				(class_name ~ "EV_FIGURE_LINE" implies False) and
				(class_name ~ "EV_FIGURE_MATH" implies False) and
				(class_name ~ "EV_FIGURE_PICTURE" implies False) and
				(class_name ~ "EV_FIGURE_PIE_SLICE" implies False) and
				(class_name ~ "EV_FIGURE_POLYGON" implies False) and
				(class_name ~ "EV_FIGURE_POLYLINE" implies False) and
				(class_name ~ "EV_FIGURE_POSTSCRIPT_DRAWER" implies False) and
				(class_name ~ "EV_FIGURE_RECTANGLE" implies False) and
				(class_name ~ "EV_FIGURE_ROUNDED_RECTANGLE" implies False) and
				(class_name ~ "EV_FIGURE_STAR" implies False) and
				(class_name ~ "EV_FIGURE_TEXT" implies False) and
				(class_name ~ "EV_FIGURE_WORLD" implies False) and
				(class_name ~ "EV_MOVE_HANDLE" implies False) and
				(class_name ~ "EV_MULTI_POINTED_FIGURE" implies False) and
				(class_name ~ "EV_PIXMAP_PROJECTOR" implies False) and
				(class_name ~ "EV_POSTSCRIPT_PROJECTOR" implies False) and
				(class_name ~ "EV_PROJECTION_ROUTINES" implies False) and
				(class_name ~ "EV_PROJECTOR" implies False) and
				(class_name ~ "EV_RELATIVE_POINT" implies False) and
				(class_name ~ "EV_SINGLE_POINTED_FIGURE" implies False) and
				(class_name ~ "EV_WIDGET_PROJECTOR" implies False) and
				(class_name ~ "EV_DYNAMIC_TREE_ITEM" implies not (feature_name ~ "fill_from_subtree_function")) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM" implies not (feature_name ~ "create_implementation")) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM" implies not (feature_name ~ "checkbox_handled")) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM" implies not (feature_name ~ "on_key_pressed")) and
				(class_name ~ "EV_GRID_CHECKABLE_LABEL_ITEM" implies not (feature_name ~ "computed_initial_grid_label_item_layout")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "set_item_strings")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "deactivate")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "set_strings")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "set_alignment")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "activate_action")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "on_mouse_move")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "on_mouse_press")) and
				(class_name ~ "EV_GRID_CHOICE_ITEM" implies not (feature_name ~ "on_key")) and
				(class_name ~ "EV_GRID_COLUMN" implies not (feature_name ~ "set_pixmap")) and
				(class_name ~ "EV_GRID_COLUMN" implies not (feature_name ~ "remove_pixmap")) and
				(class_name ~ "EV_GRID_COMBO_ITEM" implies not (feature_name ~ "deactivate")) and
				(class_name ~ "EV_GRID_COMBO_ITEM" implies not (feature_name ~ "handle_key")) and
				(class_name ~ "EV_GRID_EDITABLE_ITEM" implies not (feature_name ~ "deactivate")) and
				(class_name ~ "EV_GRID_EDITABLE_ITEM" implies not (feature_name ~ "handle_key")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "make_with_text")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "initialize")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "set_text")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "set_font")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "set_pixmap")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "remove_pixmap")) and
				(class_name ~ "EV_GRID_LABEL_ITEM" implies not (feature_name ~ "set_left_border")) and







				not (feature_name ~ "out")
			then

				if True then --not feature_name.has_substring ("test") then
					if routine.e_feature.is_function implies not routine.e_feature.type.actual_type.name.starts_with ("MML") then
						print ("Feature: " + routine.e_feature.name_32)
						io.new_line

						create start_time.make_now_utc
								-- Initialising time
						create l_visitor.make (routine)
						routine.body.process (l_visitor)
						create finish_time.make_now_utc
								-- taking final time
						create t
						t.name := routine.e_feature.name_32
						t.time := finish_time.relative_duration (start_time).fine_seconds_count
						t.only_clause := create {TWO_WAY_LIST [STRING]}.make
						t.only_clause := l_visitor.alias_graph.change_atts
						info.at (class_name).force (t)

						if routine.e_feature.is_function and then l_visitor.alias_graph.change_atts.count > 0 then
							print ("%N+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%N")
							print ("class: " + class_name + " feature: " + routine.e_feature.name_32)
							print ("%N+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%N")
						end

						atts_mod.force (l_visitor.alias_graph.change_atts, routine.e_feature.name_32)



					end
				end
			else
				create t
				t.name := "*"+routine.e_feature.name_32+"*"
				t.time := 0
				t.only_clause := create {TWO_WAY_LIST [STRING]}.make
				info.at (class_name).force (t)
			end
		end

	atts_mod_to_string (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as feat
			loop
				Result := Result + feat.key + "%N    ensure%N        only: "
				across
					feat.item as atts
				loop
					Result := Result + atts.item
					if not atts.is_last then
						Result := Result + ", "
					end
				end
				Result := Result + "%N"
			end
		end

	visualisation (atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]; class_name, a_result: STRING)
		do
			a_result.append ("Class: ")
			a_result.append (class_name)
			a_result.append ("%NSuggested Frame Conditions%N")
			a_result.append (atts_mod_to_string2 (atts_mod))
		end
feature -- toDelete
	atts_mod_to_string2 (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as feat
			loop
				Result := Result + feat.key + ": "
				across
					feat.item as atts
				loop
					Result := Result + atts.item
					if not atts.is_last then
						Result := Result + ", "
					end
				end
				Result := Result + "%N"
			end
		end

	print_info (info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
		require
			info /= Void
		local
			feat, fail: INTEGER
			t: REAL_64
		do
			print ("%N=====================Info==================%N")
			across
				info as i
			loop
				print (i.key+ " #("+i.item.count.out+"): ")
				across
					i.item as v
				loop
					t := t + v.item.time
					print (v.item.name+" (t: "+v.item.time.out+" )"+" - ")
					if v.item.name.starts_with ("*") then
						fail := fail + 1
					else
						feat := feat + 1
					end
				end
				print ("%N%N")
			end
			print ("Total classes: " + info.count.out)
			print ("%NTotal feature analysed: " + feat.out)
			print ("%NTotal feature failed: " + fail.out)
			print ("%NTotal time: " + t.out)
			print ("%N=====================Info==================%N")
		end

	print_info_fail (info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
		require
			info /= Void
		do
			print ("%N=====================Info (fail)==================%N")
			across
				info as i
			loop
				print (i.key + ": %N")
				across
					i.item as v
				loop
					if v.item.name.starts_with ("*") then
						print (v.item.name)
						io.new_line
					end
				end
				print ("%N%N")
			end
			print ("%N=====================Info==================%N")
		end

	print_info_scv (info: HASH_TABLE [ARRAYED_LIST [TUPLE [name:STRING; time: REAL_64; only_clause: TWO_WAY_LIST [STRING]]], STRING])
		require
			info /= Void
		local
			feat, fail: INTEGER
			t: REAL_64
		do
			print ("class name,feature,time")
			io.new_line
			across
				info as i
			loop
				across
					i.item as v
				loop
					t := t + v.item.time
					print (i.key+","+v.item.name+","+v.item.time.out)
					io.new_line
					if v.item.name.starts_with ("*") then
						fail := fail + 1
					else
						feat := feat + 1
					end
				end
			end
		end

invariant
	feature_view /= Void

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
