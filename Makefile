.SUFFIXES:

.PHONY: container
container:
	docker build -t fbartels/ffmpeg-vaapi .
	bash runtests.sh

