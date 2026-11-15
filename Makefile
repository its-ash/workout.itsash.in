STORE_ID := workout

# Checkout of the web app (its-ash/workout.itsash.in), for `make import`.
WEB ?= ../../workout.itsash.in

.PHONY: run build clean test import

run:
	flutter pub get && flutter run

build:
	flutter pub get && flutter build apk --release

test:
	flutter analyze && flutter test

# Re-pick exercise demos and copy only the used GIFs from the web dataset.
import:
	dart run tool/import_web.dart $(WEB)

clean:
	flutter clean
	rm -rf dist

# deploy, release, bump, store-check, store-meta, version
include store.mk
