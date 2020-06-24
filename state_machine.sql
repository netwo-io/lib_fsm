create table lib_fsm.state_machine
(
  state_machine__id   uuid not null primary key default public.gen_random_uuid(),
  abstract_state__id  uuid not null, -- e.g. 'ordered'
  foreign key (abstract_state__id) references lib_fsm.abstract_state (abstract_state__id) on delete cascade on update cascade
);

comment on column lib_fsm.state_machine.state_machine__id is 'unique entry per column per table that refers to a single state inside the defined abstract_machine__id. A table can N references to N state (e.g. contract_instance table has 2 kind of status).';
comment on table lib_fsm.state_machine is 'Store every state possible for a defined finite state machine (lib_fsm.abstract_state_machine.abstract_machine__id)';
