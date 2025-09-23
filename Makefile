.PHONY: check

check:
	terraform fmt
	terraform validate
