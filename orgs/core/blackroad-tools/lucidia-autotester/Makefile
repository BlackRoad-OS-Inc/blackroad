.RECIPEPREFIX := >
ENV ?= staging

collect-services:
>python bin/collect_services.py --env $(ENV)

test:
>SERVICES_BLOB='$(shell python bin/collect_services.py --env $(ENV))' pytest -q

.PHONY: test collect-services
