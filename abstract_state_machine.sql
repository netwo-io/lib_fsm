create table if not exists lib_fsm.abstract_state_machine
(
    abstract_machine__id uuid        not null primary key default public.gen_random_uuid(),
    name                 varchar(30) not null check (length(name) >= 4), -- for internal use/debugging
    description          text        null,     -- for internal use/debugging
    created_at           timestamptz not null             default now()
);

create or replace function lib_fsm.abstract_machine_create(name varchar(30), description text default null) returns uuid as $$
declare
    id uuid;
begin
    insert into lib_fsm.abstract_state_machine (abstract_machine__id, name, description)
        values (DEFAULT, name, description) returning abstract_machine__id into id;
    return id;
end;
$$ language plpgsql;

create or replace function lib_fsm.abstract_machine_update(abstract_machine__id uuid, new_name varchar(30), new_description text default null) returns void as $$
begin
    update lib_fsm.abstract_state_machine
    set name = new_name, description = new_description
    where lib_fsm.abstract_state_machine.abstract_machine__id = abstract_machine_update.abstract_machine__id;

    if not found then
        raise sqlstate '42P01' using
            message = 'abstract_machine__id not found',
            hint = abstract_machine__id;
    end if;
end;
$$ language plpgsql;

create or replace function lib_fsm.abstract_machine_delete(abstract_machine__id uuid) returns void as $$
begin
    delete from lib_fsm.abstract_state_machine
    where lib_fsm.abstract_state_machine.abstract_machine__id = abstract_machine_delete.abstract_machine__id;
end;
$$ language plpgsql;
