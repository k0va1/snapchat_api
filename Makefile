.PHONY: test install lint-fix

install:
	bundle install

lint-fix:
	bundle exec standardrb --fix

test:
	@env $$(cat .env | xargs) bundle exec rspec $(filter-out $@,$(MAKECMDGOALS))
