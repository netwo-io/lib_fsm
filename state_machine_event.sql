create table lib_fsm.state_machine_event
(
    state_machine__id   uuid                              not null references lib_fsm.state_machine (state_machine__id) on delete cascade on update cascade,
    abstract_state__id  uuid                              not null references lib_fsm.abstract_state (abstract_state__id) on delete restrict on update restrict,
    event               varchar(30)                       null,
    abstract_state_name lib_fsm.abstract_state_identifier not null, -- materialized view
    created_at          timestamptz default now()         not null
);

comment on table lib_fsm.state_machine_event is 'Store successful state changes of a state machine';
comment on column lib_fsm.state_machine_event.event is 'The event was triggered last state change for the machine. Note that we do not ensure the event still exists in the abstract state machine. There might be inconsistencies. Also "null" means the default initial state was selected';
comment on column lib_fsm.state_machine_event.abstract_state__id is 'abstract_state__id that was active once the `event` was received';
