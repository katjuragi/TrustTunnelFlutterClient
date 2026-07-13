# Without FVM

init:
	@echo "* Getting latest dependencies *"
	@flutter pub get
	@echo "* Running build runner *"
	@$(MAKE) gen

gen:
	@echo "* Generate pigeon *"
	@dart run pigeon --input pigeons/platform_api.dart --swift_out ios/Classes/PlatformApi.g.swift
	@dart run pigeon --input pigeons/platform_api.dart --swift_out macos/Classes/PlatformApi.g.swift