mod game
mod infra
mod user-service
mod matchmaker
mod fleet

[default]
build: game::build
	mkdir -p user-service/catalog
	cp game/dist/catalog/catalog.json user-service/catalog/catalog.json

[parallel]
fix: game::fix infra::fix user-service::fix matchmaker::fix fleet::fix

gcloud:
	gcloud config configurations activate ironfront

gcloud-adc:
	gcloud auth application-default login