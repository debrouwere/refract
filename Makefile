all:
	coffee --output lib --compile src

test:
	./bin/refract examples/simple/template.yml examples/simple/object.json \
		--pretty \
		--add