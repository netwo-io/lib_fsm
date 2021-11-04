drop schema if exists lib_fsm cascade;
create schema lib_fsm;
grant usage on schema lib_fsm to public;
grant usage, select on all sequences in schema lib_fsm to public;
alter default privileges in schema lib_fsm grant usage, select on sequences to public;
set search_path = pg_catalog;

-- type domains (private)
\ir _domains.sql

-- table (private)
\ir abstract_state_machine.sql
\ir abstract_state.sql
\ir abstract_transition.sql
\ir state_machine.sql
\ir state_machine_event.sql

-- views (public)
\ir abstract_state_machine_transitions.sql
\ir state_machine_events.sql

-- functions (public)
\ir _functions.sql
