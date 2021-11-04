create or replace view lib_fsm.state_machine_events as
select sme.event_id,
       sme.state_machine__id,
       sme.created_at,

       -- we have to use state_machine_event recorded state because the underlying abstract_state might have been removed
       sme.abstract_state_name as "state_name",

       -- description might be null if the underlying abstract_state has been emoved
       ast.description         as "state_description",

       sme.event as "event_name"
from lib_fsm.state_machine_event sme
         left outer join lib_fsm.abstract_state ast on ast.abstract_state__id = sme.abstract_state__id;
