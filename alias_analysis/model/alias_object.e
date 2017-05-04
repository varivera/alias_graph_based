class
	ALIAS_OBJECT

inherit

	ALIAS_VISITABLE
		rename
			variables as attributes
		end

create
	make, make_atts, make_void

feature {NONE}

	make (a_type: TYPE_A)
		require
			a_type /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			type := a_type
			create attributes.make (16)
				-- SPECIAL is a special class to implement Arrays. It does not contain
				-- all implementation as it is implemented in C.
			if type.name.starts_with ("detachable SPECIAL [") or type.name.starts_with ("SPECIAL [")
				-- TODO to find a better way to express that
				--if attached {detachable SPECIAL [ANY]} type as special_type then
			then
					-- 'items' is a (non-existing) attribute of class SPECIAL to represent
					-- all fields of the Array
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make (create {CL_TYPE_A}.make (a_type.system.any_class.compiled_class.class_id)))
				attributes.force (l_obj, create {ALIAS_KEY}.make ("items"))
			end
			create entity.make
		ensure
			type = a_type
			attributes /= Void
			attributes.is_empty
		end

	make_void
		do
			create {VOID_A} type
			create attributes.make (16)
			create entity.make
		ensure
			type = Void
			attributes /= Void
			attributes.is_empty
		end

	make_atts (a_type: TYPE_A; a_atts: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT],ALIAS_KEY])
			-- creates an alias object with type `a_type' and attributes `a_atts'
		require
			a_type /= Void
		do
			type := a_type
			attributes := a_atts
			create entity.make
		ensure
			type = a_type
			attributes /= Void
		end

feature {ANY}

	type: TYPE_A

	entity: TWO_WAY_LIST [TWO_WAY_LIST [STRING]]
			-- entity that called the Object represented by this ALIAS_OBJECT
			-- It is a list of list to represent remote entites, e.g. a.b.c, where 'a' and 'b' are entities
feature {ANY}

	add_entity (name: TWO_WAY_LIST [STRING])
		require
			entity /= Void
			attached name as n and then not name.is_empty
		do
			entity.force (name)
		end

	set_entity_error
		require
			entity /= Void
		local
			name: TWO_WAY_LIST [STRING]
		do
			create name.make
			name.force ("ERROR")
			entity.force (name)
		end

	entity_wipe_out
		require
			entity /= Void
		do
			entity.wipe_out
		end

	out: STRING_8
		do
			if attached {CL_TYPE_A} type then
				Result := "{" + type.base_class.name + "}"
			else
				Result := "{" + type.name + "}"
			end
		end

	is_string: BOOLEAN
			-- is the ALIAS_OBJECT a STRING?
			--TODO: to find out a better way
		do
			if attached {CL_TYPE_A} type then
				Result := type.base_class.name.starts_with ("STRING")
			end
		end

feature -- TODELETE

	out2: STRING_8
		do
			if tagged_out.split ('%N').count > 0 then
				Result := tagged_out.split ('%N').at (1)
			else
				Result := tagged_out
			end
		end

invariant
	type /= Void

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
