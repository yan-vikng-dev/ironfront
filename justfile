mod game
mod infra
mod user-service
mod fleet

[default]
build: game::build-dry

[parallel]
fix: game::fix infra::fix user-service::fix fleet::fix

gcloud:
	gcloud config configurations activate ironfront

gcloud-adc:
	gcloud auth application-default login
