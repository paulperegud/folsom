PROJECT = folsom

REBAR_DEPS_DIR ?= $(shell pwd)/deps
export REBAR_DEPS_DIR

ERLC_OPTS ?= +debug_info

DEPS = meck bear
dep_meck = git https://github.com/eTilbudsavis/meck master
dep_bear = git https://github.com/paulperegud/bear.git 0.8.1.pp

include erlang.mk
