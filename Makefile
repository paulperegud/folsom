PROJECT = folsom

REBAR_DEPS_DIR ?= $(shell pwd)/deps
export REBAR_DEPS_DIR

DEPS = meck bear
dep_meck = git https://github.com/eTilbudsavis/meck master
dep_bear = git https://github.com/baden/bear.git master

include erlang.mk
