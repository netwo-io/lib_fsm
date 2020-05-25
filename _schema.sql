drop schema if exists lib_fsm cascade;
create schema lib_fsm;
grant usage on schema lib_fsm to public;
set search_path = pg_catalog;

-- ADR:


-- Context:

-- states : verb + (past (+ed) || happening (+ing)) (e.g. opened, loading, loaded, recorded, closed, locked, dumped, shipped, finished,
--                                 running, failed, entered, enabled, disabled, approved, published, archived, activated, pending, pending_renewal,
--                                 expired, ordered, canceled, returned, refunded, checked_out)
--
-- event: verb (e.g. start, open, close, lock, unlock, load, unload, dump, ship, fail, enter, enable, disable, run, return, order, cancel, refund, confirm)

-- transition = (from_state,
--               name,
--               description
--               to_state,
--               properties, <= WONT_IMPLEMENT
--               triggers (0-N, what events should automatically triggers the transition), <= MUST_LATER [ Quand un évènement est reçu, est, "orange.order.confirmed" ET "OI, =, Orange" ]
--               conditions (0-N (cf: ui-predicate)), <= MUST_LATER => based on rules_engine
--               pre_conditions (0-N, these pre-conditions are run BEFORE displaying available events from 'from_state'), <= WONT_IMPLEMENT
--               post_actions (0-N, what to do once we switched to `to_state`) <= WONT_IMPLEMENT

-- https://doc.kosc-telecom.fr/fr/principles/orders.html#cycle-de-vie

-- trying: un trigger sur toutes les tables qui watch s'il y a des columns updated with type lib_fsm.state_machine

-- tried Composite type (last state + abstract_machine__id)  + trigger but:
--  - can we join it?
--  - can we index it?
-- - Pros:
--      - Easier to maintain
--      - Does not need column names convention
-- - Cons:
--      - No foreign key on abstract_machine__id (ensure referential integrity with a trigger)
--      - No foreign key on abstract_machine__id (ensuring referential integrity with a trigger would require a schema introspection to retrieve all columns of type lib_fsm.state_machine.abstract_machine__id === old.abstract_machine__id)

-- tried an independent table that would store the state of every table field that are linked to an FSM
--
-- - Cons:
--      - Hard to keep referential integrity
--      - Looking at a table, you don't know if it has linked field (like a status field) in the lib_fsm.state_machine table
--
-- tried custom type but:
--  - they must be coded in a low level language (C-like)
--  - we are planning to leverage a managed PostgreSQL provider so we won"t be able to load our own C-extensions

-- Features:
-- *  immutable (accès à la ligne en cours ? Comment ? via l'oid ?)
-- *  multi-tenant
-- *  state machine can be user-defined (as soon as the FSM becomes user-defined, application code will need to persist the information somewhere)
-- *  calls pg_notify on state change
-- *  auto-documented ( https://github.com/jakesgordon/javascript-state-machine/blob/master/docs/visualization.md#enhanced-visualization )
--    cat <<EOF > graph.dot
--    digraph "fsm" {
--      "closed";
--      "open";
--      "closed" -> "open" [ label=" open " ];
--      "open" -> "closed" [ label=" close " ];
--    }
--    EOF
--
--    cat graph.dot | dot -Tpng -o graph.png

-- create table lib_fsm.test_contract_version_option_1(
--     contract_version__id uuid      not null primary key default public.gen_random_uuid(),
--     contract__id         uuid      not null references contract_manager.contract (contract__id) on delete cascade on update cascade,
--     validity             tstzrange not null             default tstzrange(now(), 'infinity'), -- [start_date; +inf[  [start_date; end_date]
--     status1              lib_fsm.state_machine not null,
--     status2              lib_fsm.state_machine not null,
--     description          text check (length(description) > 10 and length(description) < 500)
-- );

-- create table lib_fsm.test_contract_version_option2(
--     contract_version__id uuid      not null primary key default public.gen_random_uuid(),
--     contract__id         uuid      not null references contract_manager.contract (contract__id) on delete cascade on update cascade,
--     validity             tstzrange not null             default tstzrange(now(), 'infinity'), -- [start_date; +inf[  [start_date; end_date]
--     status1              lib_fsm.state_machine not null,
--     status1__abstract_machine__id uuid not null references lib_fsm.abstract_state_machine(abstract_machine__id) on delete cascade on update cascade,
--     status2              lib_fsm.state_machine not null,
--     status1__abstract_machine__id uuid not null references lib_fsm.abstract_state_machine(abstract_machine__id) on delete cascade on update cascade,
--     description          text check (length(description) > 10 and length(description) < 500)
-- );
--
-- create table lib_fsm.test_contract_version_option3(
--     contract_version__id uuid      not null primary key default public.gen_random_uuid(),
--     contract__id         uuid      not null references contract_manager.contract (contract__id) on delete cascade on update cascade,
--     validity             tstzrange not null             default tstzrange(now(), 'infinity'), -- [start_date; +inf[  [start_date; end_date]
--     description          text check (length(description) > 10 and length(description) < 500)
--     abstract_machine__id
--     status
-- );
--
-- create table lib_fsm.state_machine_option3(
--   table_id oid , -- references
--   primary_key ,  -- references
--   state varchar(30)
-- );

-- @todo : Selon les règles métier définies, contrainte d'unicité à écrire (un seul draft par contrat à un instant T ?)

-- https://raphael.medaer.me/2019/06/12/pglib_fsm.html
-- <<< Orange : tel produit est confirmé (ref_commande, ref_produit, status=confirmé)
-- call POST /events
--  {
--      oi:
--      event: 'order.confirmed',
--      object__id: '',
--      status: ''
--  }


-- trigger delete on lib_fsm.abstract_state_machine
--     -> schema -> columns -> lib_fsm.state_machine -> filter machine_id == old.row

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
