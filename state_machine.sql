create table lib_fsm.state_machine
(
  state_machine__id uuid        not null primary key default public.gen_random_uuid(),
  abstract_state__id          uuid not null, -- e.g. 'ordered'
  foreign key (abstract_state__id) references lib_fsm.abstract_state (abstract_state__id) on delete cascade on update cascade
);

comment on column lib_fsm.state_machine.state_machine__id is 'unique entry per column per table that refers to a single state inside the defined abstract_machine__id. A table can N references to N state (e.g. contract_instance table has 2 kind of status).';
comment on column lib_fsm.state_machine.state_machine__id is 'one of ';
comment on table lib_fsm.state_machine is 'Store every state possible for a defined finite state machine (lib_fsm.abstract_state_machine.abstract_machine__id)';

create or replace function lib_fsm.state_machine_create(abstract_state_machine__id_or_abstract_state__id uuid) returns uuid as $$
declare
  initial_abstract_state__id uuid;
  id uuid;
begin

  select abstract_state__id into initial_abstract_state__id
    from lib_fsm.abstract_state abst
    where abst.abstract_machine__id = abstract_state_machine__id_or_abstract_state__id
      and is_initial = true;

  if not found then
    -- Then provided id is either an abstract state id or not linked uiid.
    initial_abstract_state__id = abstract_state_machine__id_or_abstract_state__id;
  end if;

  insert into lib_fsm.state_machine (state_machine__id, abstract_state__id)
    values (default, initial_abstract_state__id)
    returning state_machine__id into id;
    return id;
end;
$$ language plpgsql;

create or replace function lib_fsm.state_machine_get(state_machine__id uuid) returns record as $$
declare
  state record;
begin

  select abstract_state__id, name, description into state
    from lib_fsm.state_machine
    inner join lib_fsm.abstract_state using (abstract_state__id)
    where  lib_fsm.state_machine.state_machine__id = state_machine_get.state_machine__id;

  if not found then
    raise sqlstate '42P01' using
      message = 'state_machine__id not found',
      hint = state_machine__id;
  end if;
  return state;
end;
$$ language plpgsql;

create or replace function lib_fsm.state_machine_delete(state_machine__id uuid) returns void as $$
begin

  delete from lib_fsm.state_machine
    where lib_fsm.state_machine.state_machine__id = state_machine_delete.state_machine__id;
end;
$$ language plpgsql;

create function lib_fsm.state_machine_transition(state_machine__id uuid, event varchar(30), dry_run boolean default false) returns record as $$
declare
   to_state record;
begin

  -- ensure event is a valid next state for `state_machine__id`
  select ast.abstract_state__id, ast.name, ast.description into to_state
    from lib_fsm.state_machine sm
    inner join lib_fsm.abstract_transition abtr on abtr.from_abstract_state__id = sm.abstract_state__id
    inner join lib_fsm.abstract_state ast on ast.abstract_state__id = abtr.to_abstract_state__id
    where sm.state_machine__id = state_machine_transition.state_machine__id
      and abtr.event = state_machine_transition.event;

  -- if no next state => raise an exception
  if not found then
    raise sqlstate 'P0001' using
    message = 'Invalid event for this machine';
  end if;

  -- if dry_run mode stop there and yield the to_state record
  if dry_run = true then
    return to_state;
  end if;

  -- update state machine to next state
  update lib_fsm.state_machine set abstract_state__id = to_state.abstract_state__id
    where state_machine.state_machine__id = state_machine_transition.state_machine__id;

  return to_state;
end;
$$ language plpgsql;

create function lib_fsm.state_machine_get_next_transitions(state_machine__id uuid) returns record as $$
-- can yield an empty array []
declare
  transitions record;
begin

  select asmt.* from lib_fsm.abstract_state_machine_transition asmt where asmt.from_abstract_state__id = (
    select abstract_state__id
      from lib_fsm.state_machine sm
      where sm.state_machine__id = state_machine_get_next_transitions.state_machine__id
  );
  return transitions;
end;
$$ language plpgsql;
