create table lib_fsm.abstract_state
(
    abstract_machine__id uuid                              not null references lib_fsm.abstract_state_machine (abstract_machine__id) on delete cascade on update cascade,
    abstract_state__id   uuid                              not null default public.gen_random_uuid(),
    name                 lib_fsm.abstract_state_identifier not null,
    -- state_parent_id  varchar(30) null comment 'can OPTIONALLY refers to a repository of states (if it does not, it is a user-defined state)',
    description          text                              null,
    is_initial           boolean                           not null default false,
    primary key (abstract_machine__id, abstract_state__id),
    unique (abstract_state__id) -- unique state per machine
);

create unique index abstract_state_abstract_machine_id_is_initial on lib_fsm.abstract_state (abstract_machine__id, is_initial) where is_initial = 'true';

comment on column lib_fsm.abstract_state.abstract_state__id is 'user-defined state name';
comment on column lib_fsm.abstract_state.description is 'optional user-defined and user-visible description';
comment on table lib_fsm.abstract_state is 'Store every state possible for a defined finie state machine (lib_fsm.abstract_state_machine.abstract_machine__id)';

create or replace function lib_fsm.ensure_at_least_one_initial_state_per_abstract_machine() returns trigger as $$
declare
  count int;
begin

  -- We do a short path here if initial already declared unicity constraint will raise an exception.
  if new.is_initial = true then
    return new;
  end if;

  --
  select count(1)
    from lib_fsm.abstract_state as1
    where as1.abstract_machine__id = new.abstract_machine__id
      and as1.is_initial = true
    limit 1
    into count;

  if count = 0 then
    raise 'a state machine must have one initial state. none found.' using errcode = 'check_violation';
  end if;

  return new;
end;
$$ language plpgsql;

create trigger ensure_at_least_one_initial_state_per_abstract_machine
  before insert or update
  on lib_fsm.abstract_state
  for each row
execute procedure lib_fsm.ensure_at_least_one_initial_state_per_abstract_machine();

create or replace function lib_fsm.abstract_state_create(
  abstract_machine__id$ uuid,
  name$ lib_fsm.abstract_state_identifier,
  description$ text default null,
  is_initial$ boolean default false,
  abstract_state__id$ uuid default public.gen_random_uuid()
) returns uuid as $$
declare
  id uuid;
begin
  insert into lib_fsm.abstract_state (abstract_state__id, abstract_machine__id, name, description, is_initial)
    values (abstract_state__id$, abstract_machine__id$, name$, description$, is_initial$)
    returning abstract_state__id into id;
  return id;
end;
$$ language plpgsql;
