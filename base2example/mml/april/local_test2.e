note
	description: "Summary description for {LOCAL_TEST2}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	LOCAL_TEST2

create
	make

feature

	tt
		do
			p := p2
		end

	p, p2: STRING

	make
		do
			p := ""
			p2 := ""
		end

end
