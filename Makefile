.PHONY: deploy run commit

deploy:
	@npm version patch --no-git-tag-version
	@npx nuxt build
	@git add -A
	@git commit -m "chore: release v$$(node -p \"require('./package.json').version\")"
	@git push origin $$(git rev-parse --abbrev-ref HEAD)

run:
	@npx nuxt dev

commit:
	@git add -A
	@git commit -m "chore: update $$(date +%Y-%m-%d)"