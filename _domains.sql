create domain lib_fsm.event_identifier as varchar(30);
create domain lib_fsm.abstract_state_identifier as varchar(50) not null check (length(VALUE) >= 3);
