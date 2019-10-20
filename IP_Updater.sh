#!/bin/sh

cd `dirname $0`

bundle exec ruby ./IP_Updater.rb config.yaml $@
