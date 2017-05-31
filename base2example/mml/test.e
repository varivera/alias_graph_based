note
	description: "Summary description for {TEST}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST [G]

create
	make

feature

	test
		local
			zz:STRING
		do
			from

			until
				True
			loop
				if attached c as cc then
					a := cc
				end
			end
		end

	a,b,c: STRING

	make
		do
			a := ""
			b := ""
			c := ""
		end

	t
		do
			a := b
			c := a
		end

end
