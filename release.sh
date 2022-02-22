#!/bin/sh
heroku container:push web -a pob-http
heroku container:release web -a pob-http
