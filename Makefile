.SUFFIXES:

.PHONY: container
container:
	docker build -t ffmpeg-vaapi:build .
	bash runtests.sh

