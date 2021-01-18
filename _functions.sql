create or replace function lib_fsm.state_machine_create(abstract_state_machine__id_or_abstract_state__id$ uuid, state_machine__id$ uuid default public.gen_random_uuid()) returns uuid as
$$
declare
  initial_abstract_state__id$ uuid;
begin

  -- a) if abstract_state_machine__id_or_abstract_state__id$ is an abstract_machine__id, then find the default state machine state (abstract_state__id)
  select abstract_state__id
  into initial_abstract_state__id$
  from lib_fsm.abstract_state abst
  where abst.abstract_machine__id = abstract_state_machine__id_or_abstract_state__id$
    and is_initial = true;

  if not found then
    -- b) if we got there, it means abstract_state_machine__id_or_abstract_state__id$ might be directly an abstract_state__id
    -- if it is not a) or b) the insert below will crash because referential integrety will be broken
    initial_abstract_state__id$ = abstract_state_machine__id_or_abstract_state__id$;
  end if;

  insert into lib_fsm.state_machine (state_machine__id, abstract_state__id)
    values (state_machine__id$, initial_abstract_state__id$);

  -- history management (see why we are doing it this way in _state_machine_store_event())
  perform lib_fsm._state_machine_store_event(
    abstract_state__id$ => initial_abstract_state__id$,
    state_machine__id$ => state_machine__id$,
    event$ => null -- null means the machine just boot up to its default state
  );

  return state_machine__id$;
end;
$$ language plpgsql;

create or replace function lib_fsm.state_machine_belongs_to_abstract_machine(state_machine__id$ uuid, abstract_machine__id$ uuid) returns boolean as
$$
declare
  found_abstract_machine__id$ uuid;
begin

  select abstract_machine__id from lib_fsm.state_machine
    inner join lib_fsm.abstract_state using (abstract_state__id)
    where state_machine.state_machine__id = state_machine__id$ and abstract_machine__id = abstract_machine__id$ into found_abstract_machine__id$;

  if not found then
    raise 'state machine is not bound to required abstract machine' using errcode = 'check_violation', hint = state_machine__id$;
  end if;

  return True;
end;
$$ language plpgsql;

create type lib_fsm.state_machine_state as (abstract_state__id uuid, name lib_fsm.abstract_state_identifier, description text, created_at timestamptz);

create or replace function lib_fsm.state_machine_get(state_machine__id$ uuid) returns lib_fsm.state_machine_state as
$$
declare
  state lib_fsm.state_machine_state;
begin

  select abstract_state.abstract_state__id, abstract_state.name, abstract_state.description, events_subq.created_at
    into state
    from lib_fsm.state_machine
      inner join lib_fsm.abstract_state using (abstract_state__id)
      inner join (
        select
          fsm_event.state_machine__id,
          fsm_event.abstract_state__id,
          max(fsm_event.created_at) as created_at
        from lib_fsm.state_machine_event as fsm_event
          group by fsm_event.state_machine__id, fsm_event.abstract_state__id
      ) as events_subq
      on events_subq.state_machine__id = state_machine.state_machine__id and events_subq.abstract_state__id = abstract_state.abstract_state__id
    where state_machine.state_machine__id = state_machine__id$;

  if not found then
    raise sqlstate '42P01' using
      message = 'state_machine__id not found',
      hint = state_machine__id$;
  end if;

  return state;
end;
$$ immutable security definer language plpgsql;

-- Return a mermaid graph
create or replace function lib_fsm.state_machine_get_mermaid(abstract_state_machine__id$ uuid) returns text as
$$
declare
  diagram text;
  rec     record;
begin
  diagram = '';
  for rec in select from_state_name, to_state_name, event, description
    from lib_fsm.abstract_state_machine_transitions asmt
    where asmt.abstract_machine__id = abstract_state_machine__id$
  loop
    diagram = concat(diagram, '\n\t', rec.from_state_name, ' --> ', rec.to_state_name, ' : ',
      coalesce(rec.description, rec.event), '\n\t');
  end loop;

  return concat('stateDiagram\n\t', diagram);
end;
$$ immutable language plpgsql;

create or replace function lib_fsm.state_machine_delete(state_machine__id$ uuid) returns void as
$$
begin
  delete
    from lib_fsm.state_machine
    where state_machine__id = state_machine__id$;
end;
$$ language plpgsql;

create function lib_fsm.state_machine_transition(state_machine__id$ uuid, event$ lib_fsm.event_identifier, dry_run$ boolean default false) returns record as
$$
declare
  to_state record;
begin

  -- ensure event is a valid next state for `state_machine__id`
  select ast.abstract_state__id, ast.name, ast.description
  into to_state
  from lib_fsm.state_machine sm
    inner join lib_fsm.abstract_transition abtr on abtr.from_abstract_state__id = sm.abstract_state__id
    inner join lib_fsm.abstract_state ast on ast.abstract_state__id = abtr.to_abstract_state__id
  where sm.state_machine__id = state_machine__id$
    and abtr.event = event$;


  -- if no next state => raise an exception
  if not found then
    raise sqlstate 'P0001' using
      message = 'Invalid event for this machine';
  end if;

  -- if dry_run mode stop there and yield the to_state record
  if dry_run$ = true then
    return to_state;
  end if;

  -- update state machine to next state
  update lib_fsm.state_machine
    set abstract_state__id = to_state.abstract_state__id
    where state_machine.state_machine__id = state_machine__id$;

  -- history management (see why we are doing it this way in _state_machine_store_event())
  perform lib_fsm._state_machine_store_event(
    abstract_state__id$ =>to_state.abstract_state__id,
    state_machine__id$ => state_machine__id$,
    event$ => event$
  );

  return to_state;
end;
$$ language plpgsql;

create function lib_fsm.state_machine_get_next_transitions(state_machine__id$ uuid) returns setof lib_fsm.abstract_state_machine_transitions as
$$
begin
  return query select asmt.*
    from lib_fsm.abstract_state_machine_transitions asmt
    where asmt.from_abstract_state__id = (
      select abstract_state__id
        from lib_fsm.state_machine sm
        where sm.state_machine__id = state_machine__id$
    );
end;
$$ immutable security definer language plpgsql;

create function lib_fsm._state_machine_store_event(abstract_state__id$ uuid, state_machine__id$ uuid, event$ lib_fsm.event_identifier) returns void as
$$
declare
  name$ varchar(30);
begin
  -- raise exception 'select name from lib_fsm.abstract_state where abstract_state_id = %', abstract_state__id$;

  select name into name$ from lib_fsm.abstract_state where abstract_state__id = abstract_state__id$;

  -- history management is not handled inside a trigger on lib_fsm.state_machine because we would not have access to the `event` property
  -- instead both `lib_fsm.state_machine_transition()` and `lib_fsm.state_machine_create()` call this function in order to save the triggered event
  insert into lib_fsm.state_machine_event (state_machine__id, abstract_state__id, event, abstract_state_name, created_at)
    values (state_machine__id$, abstract_state__id$, event$, name$, default);
end;
$$ language plpgsql;
