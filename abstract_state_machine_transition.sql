create or replace view lib_fsm.abstract_state_machine_transition as
select ms_previous.abstract_machine__id,
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
                    on mt.to_abstract_state__id = ms_next.abstract_state__id;
