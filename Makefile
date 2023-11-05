.PHONY:web
web:
	cd example; flutter run -d web-server --web-port=8080

.PHONY:dev
dev:
	cd example; flutter run

.PHONY:get
get:
	flutter pub get
