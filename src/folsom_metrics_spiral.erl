%%%
%%% Copyright 2012, Basho Technologies, Inc.  All Rights Reserved.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%


%%%-------------------------------------------------------------------
%%% File:      folsom_metrics_spiral.erl
%%% @author    Russell Brown <russelldb@basho.com>
%%% @doc A total count, and sliding window count of events over the last
%%%      minute.
%%% @end
%%%------------------------------------------------------------------

-module(folsom_metrics_spiral).

-export([new/1,
         update/2,
         trim/2,
         get_value/1,
         get_values/1,
         reset/1
        ]).

%% size of the window in seconds
-define(WINDOW, 60).

-include("folsom.hrl").

new(Name) ->
    Spiral = #spiral{},
    Pid = folsom_sample_slide_sup:start_slide_server(?MODULE,
                                                           Spiral#spiral.tid,
                                                           ?WINDOW),
    ets:insert_new(Spiral#spiral.tid, {count, 0}),
    ets:insert(?SPIRAL_TABLE, {Name, Spiral#spiral{server=Pid}}).

update(Name, Value) ->
    #spiral{tid=Tid} = get_value(Name),
    Moment = folsom_utils:now_epoch(),
    ets:insert_new(Tid, {Moment, 0}),
    ets:update_counter(Tid, Moment, Value),
    ets:update_counter(Tid, count, Value).

get_value(Name) ->
    [{Name, Spiral}] =  ets:lookup(?SPIRAL_TABLE, Name),
    Spiral.

trim(Tid, _Window) ->
    Oldest = oldest(),
    ets:select_delete(Tid, [{{'$1','_'}, [{is_integer, '$1'}, {'<', '$1', Oldest}], ['true']}]).

get_values(Name) ->
    Oldest = oldest(),
    #spiral{tid=Tid} = get_value(Name),
    [{count, Count}] = ets:lookup(Tid, count),
    One =lists:sum(ets:select(Tid, [{{'$1','$2'},[{is_integer, '$1'}, {'>=', '$1', Oldest}],['$2']}])),

    [{count, Count}, {one, One}].

oldest() ->
    folsom_utils:now_epoch() - ?WINDOW.

reset(Name) ->
    Spiral = get_value(Name),
    ets:delete_all_objects(Spiral#spiral.tid),
    ets:insert(Spiral#spiral.tid, {count, 0}),
    folsom_sample_slide_server:stop(Spiral#spiral.server),
    Pid = folsom_sample_slide_sup:start_slide_server(?MODULE,
                                                           Spiral#spiral.tid,
                                                           ?WINDOW),
    ets:insert(?SPIRAL_TABLE, {Name, Spiral#spiral{server=Pid}}).
    
