.PHONY: test install lint-fix

install:
	bundle install

lint-fix:
	bundle exec standardrb --fix

test:
	 bundle exec rspec $(filter-out $@,$(MAKECMDGOALS))
