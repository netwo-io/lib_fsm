drop schema if exists fsm cascade;
create schema fsm;
grant usage on schema fsm to public;
set search_path = pg_catalog;

\ir ./lib_fsm.sql
