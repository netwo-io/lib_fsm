-- Machine with full states / transitions.
insert into lib_fsm.abstract_state_machine (abstract_machine__id, name) values ('081d831f-8f88-4650-aebe-4360599d4bdc', 'first_machine_id');

-- Machine without transitions.
insert into lib_fsm.abstract_state_machine (abstract_machine__id, name) values ('081d831f-8f88-4650-aebe-4360599d4bdd', 'second_machine_id');

insert into lib_fsm.abstract_state (abstract_machine__id, abstract_state__id, name, is_initial)
    values ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4aaa', 'starting', 'true'),
    ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4abb', 'awaiting_payment', 'false'),
    ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4acc', 'awaiting_shipment', 'false'),
    ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4add', 'canceled', 'false'),
    ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4aee', 'awaiting_refund', 'false'),
    ('081d831f-8f88-4650-aebe-4360599d4bdc', '081d831f-8f88-4650-aebe-4360599d4aff', 'shipped', 'false');


insert into lib_fsm.abstract_transition(from_abstract_state__id, event, to_abstract_state__id)
values ('081d831f-8f88-4650-aebe-4360599d4aaa', 'create',
        '081d831f-8f88-4650-aebe-4360599d4abb'),
       ('081d831f-8f88-4650-aebe-4360599d4abb', 'pay',
        '081d831f-8f88-4650-aebe-4360599d4acc'),
       ('081d831f-8f88-4650-aebe-4360599d4abb', 'cancel',
        '081d831f-8f88-4650-aebe-4360599d4add'),
       ('081d831f-8f88-4650-aebe-4360599d4acc', 'cancel',
        '081d831f-8f88-4650-aebe-4360599d4aee'),
       ('081d831f-8f88-4650-aebe-4360599d4acc', 'ship',
        '081d831f-8f88-4650-aebe-4360599d4aff'),
       ('081d831f-8f88-4650-aebe-4360599d4aee', 'refund',
        '081d831f-8f88-4650-aebe-4360599d4add');

insert into lib_fsm.state_machine (state_machine__id, abstract_state__id)
values ('603c3f8b-17a9-4cb6-b71e-ff69b4325eb9', '081d831f-8f88-4650-aebe-4360599d4aaa'),
    ('603c3f8b-17a9-4cb6-b71e-ff69b4325eba', '081d831f-8f88-4650-aebe-4360599d4aaa');

insert into lib_fsm.test_contract_version (contract_version__id, status1, status2, description)
values ('081d831f-8f88-4650-aebe-4360599d4ba4', '603c3f8b-17a9-4cb6-b71e-ff69b4325eb9', '603c3f8b-17a9-4cb6-b71e-ff69b4325eba', 'lalalalalalalala');
