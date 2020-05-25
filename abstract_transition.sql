create table lib_fsm.abstract_transition
(
    from_abstract_state__id uuid        not null,
    to_abstract_state__id   uuid        not null,
    event                   varchar(30) not null, -- no need to have an external event table
    description             text        null,
    created_at              timestamptz not null default now(),
    foreign key (from_abstract_state__id) references lib_fsm.abstract_state (abstract_state__id) on delete cascade on update cascade,
    foreign key (to_abstract_state__id) references lib_fsm.abstract_state (abstract_state__id) on delete cascade on update cascade,
    unique (from_abstract_state__id, event),
    primary key (from_abstract_state__id, event, to_abstract_state__id)
);

create or replace function lib_fsm.ensure_from_and_to_state_have_same_machine__id() returns trigger as $$
declare
    count int;
begin

    select count(1)
        from lib_fsm.abstract_state as1
        inner join lib_fsm.abstract_state as2 on as2.abstract_state__id = new.to_abstract_state__id
        where as1.abstract_state__id = new.from_abstract_state__id and as1.abstract_machine__id = as2.abstract_machine__id
        limit 1
        into count;

    if count != 1 then
        RAISE 'Both from and to state must have the same machine_id' USING ERRCODE = 'check_violation';
    end if;

    return new;
end;
$$ language plpgsql;

create trigger ensure_from_and_to_state_have_same_machine__id
    before insert or update
    on lib_fsm.abstract_transition
    for each row
execute procedure lib_fsm.ensure_from_and_to_state_have_same_machine__id();

create or replace function lib_fsm.abstract_transition_create(
    abstract_machine__id uuid,
    from_abstract_state__id uuid,
    event varchar(30),
    to_abstract_state__id uuid,
    description text default null
) returns void as $$
begin
    insert into lib_fsm.abstract_transition(from_abstract_state__id, to_abstract_state__id, event, description)
        values (from_abstract_state__id, to_abstract_state__id, event, description);
end;
$$ language plpgsql;
