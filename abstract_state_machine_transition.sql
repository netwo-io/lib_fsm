create or replace view lib_fsm.abstract_state_machine_transition as
with machine_transitions as (select ms_previous.abstract_machine__id,
                                    ms_previous.abstract_state__id as from_abstract_state__id,
                                    ms_previous.name               as from_state_name,
                                    ms_previous.description        as from_state_description,
                                    mt.event,
                                    mt.description,
                                    ms_next.abstract_state__id     as to_abstract_state__id,
                                    ms_next.name                   as to_state_name,
                                    ms_next.description            as to_state_description
        from lib_fsm.abstract_transition mt
        inner join lib_fsm.abstract_state ms_previous
                    on mt.from_abstract_state__id = ms_previous.abstract_state__id
        inner join lib_fsm.abstract_state ms_next
                    on mt.to_abstract_state__id = ms_next.abstract_state__id
)
select  transitions.abstract_machine__id,
        jsonb_build_object(
            'id', transitions.from_abstract_state__id,
            'name', transitions.from_state_name, '' ||
            'description', transitions.from_state_description)  as from_state,
        transitions.event,
        transitions.description,
        jsonb_build_object(
            'id', transitions.to_abstract_state__id,
            'name', transitions.to_state_name,
            'description', transitions.to_state_description)    as to_state
from lib_fsm.abstract_state_machine
        left join machine_transitions transitions
                    on (transitions.abstract_machine__id = abstract_state_machine.abstract_machine__id)
order by abstract_state_machine.created_at;
