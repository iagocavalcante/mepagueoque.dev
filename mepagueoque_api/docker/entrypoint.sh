#!/bin/sh
set -e
/home/app/bin/mepagueoque_api eval "MepagueoqueApi.Release.migrate()"
exec /home/app/bin/mepagueoque_api start
