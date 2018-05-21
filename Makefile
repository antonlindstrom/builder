ENV:=tmp/env

$(ENV): docker-compose.yml Dockerfile test/fake_api/*
	docker-compose build
	docker-compose up -d api
	@mkdir -p $(@D)
	@touch $@

.PHONY: test-lint
test-lint:
	docker run --rm -v $(CURDIR):/data -w /data koalaman/shellcheck:v0.4.7 $(wildcard script/*)

.PHONY: test-acceptance
test-acceptance: $(ENV) | tmp/buildkite-agent
	@env \
		BUILDKITE_AGENT_METADIR=$(CURDIR)/tmp/buildkite-agent \
		GIT_FIXTURE_DIR=$(CURDIR)/test/fixtures \
		PATH=$(CURDIR)/test/stubs/bin:$$PATH \
		TEAMCI_API_URL=http://localhost:9292 \
		bats test/acceptance/*_test.bats

.PHONY: test-ci
test-ci: test-acceptance test-lint

tmp/buildkite-agent:
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(ENV) tmp/*
	docker-compose down
