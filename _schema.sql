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

-------------------------
-- USE IT
-------------------------


create table lib_fsm.test_contract_version
(
    contract_version__id uuid      not null primary key default public.gen_random_uuid(),
    -- contract__id         uuid      not null references contract_manager.contract (contract__id) on delete cascade on update cascade,
    validity             tstzrange not null             default tstzrange(now(), 'infinity'), -- [start_date; +inf[  [start_date; end_date]
    status1              uuid      not null references lib_fsm.state_machine (state_machine__id) on delete cascade on update cascade,
    status2              uuid      not null references lib_fsm.state_machine (state_machine__id) on delete cascade on update cascade,
    description          text check (length(description) > 10 and length(description) < 500)
);

-- select cv.description, cv.validity, (cv.status1).state from lib_fsm.test_contract_version cv;

-- update lib_fsm.test_contract_version
-- set status1 = 'sent'
-- where contract__id = '081d831f-8f88-4650-aebe-4360599d4ba4';


-- create table lib_fsm.test_user
-- (
--     user__id           uuid not null primary key default public.gen_random_uuid(),
--     status             text not null,
--     status_abstract_machine__id uuid
-- );
