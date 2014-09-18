all:
	coffee --output lib --compile src

.PHONY: test
test:
	mocha test --require should --compilers coffee:coffee-script/register
	