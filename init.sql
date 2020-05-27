drop schema if exists lib_fsm cascade;
create schema lib_fsm;
grant usage on schema lib_fsm to public;
set search_path = pg_catalog;


\ir abstract_state_machine.sql
\ir abstract_state.sql
\ir abstract_transition.sql
\ir abstract_state_machine_transition.sql
\ir state_machine.sql

-- @todo historisation
-- create table lib_fsm.state_machine_event
-- (
--     table__id   oid references pg_catalog.pg_class (oid) on delete cascade on update cascade, -- references the collection (table)
--     row_id      uuid                      not null,                                           -- weak references on any resource anything like a contract__id
--     column_id   uuid                      not null,                                           -- weak references on any resource anything like a contract__id
--     abstract_machine__id uuid                      not null lib_fsm.abstract_state_machine(abstract_machine__id) on delete cascade on update cascade,
--     event       varchar(30)               not null,
--     created_at  timestamptz default now() not null,
--     primary key (table__id, object__id, abstract_machine__id)
-- );


-- create function lib_fsm.order_events_transition(_state varchar, _event varchar)
--     returns varchar language sql as $$
--     select coalesce(
--                    (select to_state from order_events_transitions where state=_state and event=_event),
--                    'error'::varchar
--                );
-- $$;
--
