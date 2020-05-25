revoke all privileges on lib_fsm.abstract_state_machine from public;
revoke all privileges on lib_fsm.abstract_state from public;
revoke all privileges on lib_fsm.abstract_transition from public;
revoke all privileges on lib_fsm.state_machine from public;

-- give access to the view owner to this table
grant select, insert, update, delete on lib_fsm.abstract_state_machine to api;
grant select, insert, update, delete on lib_fsm.abstract_state to api;
grant select, insert, update, delete on lib_fsm.abstract_transition to api;
grant select, insert, update, delete on lib_fsm.state_machine to api;

-- authenticated users can request/change all the columns for this view
grant select, update, insert on api.fsm_machines to webuser;

-- define the who can access machine model data
-- enable RLS on the table holding the data
alter table lib_fsm.abstract_state_machine enable row level security;

-- define the RLS policy controlling what rows are visible to a particular application user
create policy fsm_machines_access_policy on lib_fsm.abstract_state_machine to api
using (
-- the authenticated users can see his contract item
-- notice how the rule changes based on the current id
-- which is specific to each individual request
    iam.can_i('fsm', 'machines', 'list')
) with check (
    iam.can_i('fsm', 'machines', 'update')
    OR iam.can_i('fsm', 'machines', 'create')
    OR iam.can_i('fsm', 'machines', 'delete')
);

