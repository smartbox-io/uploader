.PHONY: rubocop update

build:
	docker build -t uploader .

run:
	docker run --rm -v `pwd`:/uploader -it uploader:latest sh

rubocop:
	docker run --rm -v `pwd`:/uploader -it uploader:latest bundle exec rubocop -D

update:
	docker run --rm -v `pwd`:/uploader -it uploader:latest bundle update
