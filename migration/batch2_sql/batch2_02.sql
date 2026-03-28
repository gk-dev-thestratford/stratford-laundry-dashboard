BEGIN;

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b9329171-6203-4786-bb96-b79fd74704a3',
  '8102',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Liliana',
  NULL,
  NULL,
  'collected',
  41.86,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c0a17e4e-46d0-40b9-962b-72364f4702b6',
  '8103',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  6.42,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ae2877b9-348a-48ca-b0bd-3cad0393ff96',
  '8104',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2bb456d7-c1ce-4cd0-a110-d135e1c3e7c2',
  '8106',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'collected',
  11.0,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '77b3065e-1364-4fed-af25-d7bb8480ca13',
  '8107',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ke20',
  NULL,
  NULL,
  'collected',
  16.72,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fbf93c27-2c19-4865-bfec-047b54c96e6b',
  '8108',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2d77a386-cd06-416e-b59d-be05e2a00344',
  '8109',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2be1d72c-d7a5-4705-9354-1386a96bf42c',
  '8110',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '93c3f525-795e-42af-af0b-ead02062014c',
  '8111',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  10.56,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3b988a88-6e49-4a7e-aa3f-a7ac0e64234b',
  '8112',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c5a2eeb3-7f95-4377-a93e-e3b834e070e1',
  '8113',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '16070ba9-d5d6-42d0-a3a7-294dec95eead',
  '8116',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cffbb268-7774-40da-9b34-1ac501c7e938',
  '8117',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  11.18,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7f2d21f3-2636-46eb-9e66-5f8d90ea9d74',
  '8118',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  20.93,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '81651fc9-a02e-4636-9cab-0b045863f38f',
  '8119',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  14.52,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3348c796-2e0a-4a3e-855e-f0a1723a828f',
  '8120',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e7a44deb-8072-4702-8daf-2e02e4c667a8',
  '8121',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Laura',
  NULL,
  NULL,
  'collected',
  8.36,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '64955dc5-228f-4361-ba88-ff64614a4040',
  '8122',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Laura',
  NULL,
  NULL,
  'collected',
  4.84,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '58976a54-026c-4541-914a-c1a07bd5d56d',
  '428',
  'guest_laundry',
  NULL,
  NULL,
  'Paterson',
  '428',
  'received',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '74ae5814-fe32-44a6-99d2-2529c7df4651',
  '531',
  'guest_laundry',
  NULL,
  NULL,
  'Aisling killeen',
  '531',
  'collected',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c63e607e-6c21-4bec-8d67-ca33c8602cc3',
  '50',
  'guest_laundry',
  NULL,
  NULL,
  'Turner',
  '50',
  'received',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bbadb26a-3d0f-41ef-98e8-be869bade9c4',
  '8124',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6a3f01e9-7839-4fed-991e-3b095049cd65',
  '525',
  'guest_laundry',
  NULL,
  NULL,
  'Aj cully',
  '525',
  'collected',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '43384448-8d59-4734-b8da-8fecff290bfb',
  '427',
  'guest_laundry',
  NULL,
  NULL,
  'K eisule',
  '427',
  'collected',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '70fde31b-a9f6-4c65-b26f-50e0bdc234e1',
  '419',
  'guest_laundry',
  NULL,
  NULL,
  'Karolina',
  '419',
  'collected',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '63790c6f-ac56-4fe3-a367-88ab4ec2a8ef',
  '519',
  'guest_laundry',
  NULL,
  NULL,
  'Karina alues',
  '519',
  'collected',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '150f1155-d635-4212-8cf8-6ef38b3a3c38',
  '8125',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  7.92,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b32bc5d9-f2aa-40b5-82f5-6d6fbeea9d1b',
  '8126',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3a095854-9533-4bff-bc91-fe9575cdbdcd',
  '8127',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd9d04a77-cbac-4abd-b64e-250f77a1a97d',
  '425',
  'guest_laundry',
  NULL,
  NULL,
  'Sara berryane',
  '425',
  'received',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9cc78cbb-f72d-42f1-818e-898d0e74a608',
  '8128',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3912741f-7ab7-44be-be19-1b828f10bfd4',
  '8129',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f17f2022-98e4-4392-83cb-a0c375fbe731',
  '8130',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd53e4242-18e6-4b7d-b18a-92c2aa664ba5',
  '8131',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '72e0ea06-d5a6-45b7-911d-3375d3b93e87',
  '8133',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ke20',
  NULL,
  NULL,
  'collected',
  10.56,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8e8b85c9-ee66-4f35-a1f6-f49c1c4db332',
  '8134',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  17.94,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e24c6bd5-67d5-43e7-8236-31bb36514935',
  '8135',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  12.98,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ffd6559a-74fc-40e8-baf2-d698dc320656',
  '8136',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'received',
  4.95,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '401758ce-01c9-49ed-ab0c-023d66384174',
  '8137',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  10.15,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c2291ed9-1e5e-46c7-8fcb-3362e759d990',
  '8138',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Lina',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b6169b1f-6d45-4943-af75-ca0b7e915c24',
  '8139',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  17.16,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '70b28c62-6e38-40ae-afc8-b218d269b15a',
  '8140',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '87863fb5-c7af-47cd-98a7-6a20d260004b',
  '8141',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f8121870-e694-49fd-9cfa-bab8f835cfe0',
  '8142',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '16d411fc-cee4-4545-99a6-d3e88809092e',
  '8143',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  38.87,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a76534f8-f3d0-40f7-9566-6ff8c0c6f03f',
  '8144',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c0557db8-c74a-4383-ae20-9d5b81b4fdd4',
  '814',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Adomas',
  NULL,
  NULL,
  'received',
  11.66,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a129ba98-c0a0-406c-bafd-9161be9bd93d',
  '8146',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Adomas',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f04787c2-8cca-43be-903b-f9fe8a08b771',
  '8147',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'collected',
  12.32,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '91602c90-8dc3-4f9a-a594-7d72e4c7d7c0',
  '8148',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2a9a8c96-e04e-41d2-a814-37e21437422e',
  '8149',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  6.49,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '061e1391-c236-4492-98cd-0244e787ec2a',
  '519',
  'guest_laundry',
  NULL,
  NULL,
  'Karina a',
  '519',
  'received',
  NULL,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a4572d78-7719-4bf7-bb7f-b41b4d06fd09',
  '527',
  'guest_laundry',
  NULL,
  NULL,
  'Tom mcnaught',
  '527',
  'received',
  NULL,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c0a349b1-ee95-4bd9-9f2a-463b89119844',
  '8150',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9b07be4-e325-4c6d-8380-75da1f661aa4',
  '8151',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c59c8890-fcf7-455a-8cd3-25683adc2d30',
  '8152',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4d0251a7-2b07-4990-b06f-deccb8895911',
  '8123',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-04 09:00:00+00',
  '2026-02-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ce5fe11b-362c-43d4-a995-c5b5d2ae073a',
  '8155',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  6.0,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eb9def1e-2dfb-4729-b9c1-2e403dfbaadb',
  '8154',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3eac8e20-412c-491e-8c9b-2b1abfc346a0',
  '8156',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  3.3,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1432f094-177d-4158-ab83-28c9da717954',
  '8157',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  29.9,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e359c015-c0da-4d8e-865f-7bf39b1db8b1',
  '8158',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cc567b5c-f922-4e45-8468-bbc3cb5eb153',
  '8159',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  16.06,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5fb952ab-a1df-4621-9675-5cf4d8bff499',
  '8160',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  25.96,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '66049a4e-5d24-443e-abb0-a75ebea1cf3a',
  '8161',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  8.75,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3c7155e1-889a-44b9-a4dc-d646eeb6916c',
  '8162',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Tony',
  NULL,
  NULL,
  'collected',
  11.09,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9597c3d4-550b-4eca-b622-be570eaba4be',
  '8163',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ec0d7acc-5b6c-4bfb-b84c-83bc96e57fcf',
  '8164',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a912bf3d-fa67-4049-9f88-8265417f3609',
  '8165',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  7.92,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '952841fa-0dea-47e7-a7d2-0817ec099c4b',
  '8166',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'received',
  7.62,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a9dd1364-26b5-4041-8149-35fb52d828ff',
  '8167',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Emm',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cbba24e8-f93a-4ca7-8a38-81cacd1aa740',
  '8168',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  9.71,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '26bb7da9-01c4-49ee-9fe6-bd1e34819124',
  '8170',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.02,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'beb1a826-cf22-4cb8-856d-ec33a164aa70',
  '8171',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '42357930-5687-4527-b3bf-604f65ff5a8e',
  '8169',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  38.87,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a6ce9494-a749-4a54-8697-204006fc07f0',
  '8172',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  8.14,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e9fe9bd5-65e8-445d-94e0-f19bacb21b54',
  '8173',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  38.06,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e921b62c-5064-48f2-8bac-53d1efef6550',
  '8174',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Nihal',
  NULL,
  NULL,
  'received',
  4.49,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4f9e0d27-304d-4c52-a9fe-0ac37f98c0fc',
  '8175',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b3241f33-e79c-4bea-9524-22e6b0cb4aae',
  '8176',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  28.16,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '96d2375b-3293-43d9-8fd1-81bee25d8dc5',
  '8177',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  5.5,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '945918da-664d-4b61-866d-7d3eea825ce0',
  '8178',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3612474c-257d-41ec-92b0-a9d39d3956db',
  '8179',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '57145a6e-4580-41ce-8089-d7d2b5422ddc',
  '8180',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dbed7738-e587-4260-9531-555e2ee46897',
  '8182',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b68694f6-668c-4151-91a1-d68ec350cc96',
  '8182',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  7.41,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4e78215e-621f-47d5-8787-d204885acc5f',
  '8185',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '49800a34-a17b-4bb4-b37f-bf1592640419',
  '8183',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  12.54,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8bb04613-f459-446f-beb7-75ffbdd04929',
  '8186',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd5cc8745-dd02-4276-be2b-dafec56a6395',
  '8187',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  13.86,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9d923328-95b8-4826-9caa-7d5d72d56efe',
  '526',
  'guest_laundry',
  NULL,
  NULL,
  'Zana',
  '526',
  'received',
  NULL,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '88d1d359-0002-4bb3-8b42-233eea38996d',
  '8189',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a39961e4-7d47-449b-bf22-e73a546a2941',
  '8190',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Wania',
  NULL,
  NULL,
  'received',
  2.75,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b650d2cb-a144-4bd4-8adf-11b8634a2e1d',
  '8191',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6c23b389-ded2-40b7-baf2-ff6678380305',
  '8192',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  27.94,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c34331ab-6d96-4732-bef9-13f3c5f0c372',
  '8193',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  5.5,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fc096667-82f8-4846-8eea-ad2342ba2565',
  '8195',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f7fc5a7f-e535-47d9-b7d0-e42c94ae297c',
  '8196',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f8e759e3-d9e7-455b-8f5b-7e6d91f0980b',
  '8197',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8566f117-706d-48ec-b191-aacf61724ece',
  '8200',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1f530ca4-b50f-4cd0-8afe-c6735868cb80',
  '8201',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Laura',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '574697de-df35-4df4-b387-90595511d5eb',
  '8202',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Cadija',
  NULL,
  NULL,
  'received',
  3.19,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e6f1753c-24bc-4661-bf18-19a1394c89aa',
  '8203',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Sam',
  NULL,
  NULL,
  'received',
  14.08,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b07ba002-a24a-40e4-b484-e72daa137f07',
  '8204',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '66fe066f-82ed-4012-9421-150f73de9759',
  '8205',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '607ddba3-76fd-4fae-a23d-3f39af3c0184',
  '526',
  'guest_laundry',
  NULL,
  NULL,
  'Crossfield',
  '526',
  'received',
  NULL,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1d25a071-e0b0-4286-b159-3dd7f58b2658',
  '8206',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Nihal',
  NULL,
  NULL,
  'received',
  6.85,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a4feb124-7550-40ff-a7b0-799d1ff4027f',
  '8207',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Valentina',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1eab4428-5536-48bf-b5d1-df7672aa6a2d',
  '8208',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'received',
  7.48,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e822ffe5-7320-49a3-a298-f1ad9c0485f4',
  '8210',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6fcbd5cb-2300-4449-955b-90c63e511c41',
  '8215',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '742087ae-35e7-4398-9051-fa704ae6a306',
  '8211',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  15.4,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '31a8e617-a220-474b-a747-ef394dc12ebd',
  'MIG2-5000',
  'guest_laundry',
  NULL,
  NULL,
  'Crossfield',
  '0',
  'received',
  NULL,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '18da701d-0f5f-4cd8-b3fe-6c3273eb2cbd',
  '8209',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  71.76,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'be7ce172-2b50-4aff-b5a1-ee089a29d736',
  '8212',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Snehaa',
  NULL,
  NULL,
  'received',
  27.5,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3b8ae092-2e9a-4882-bc5d-71c98b92f3da',
  '8213',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ab51e48b-1985-4cb8-a0d6-c5c6a419bd42',
  '8214',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LFT'),
  'Claire oki',
  NULL,
  NULL,
  'collected',
  5.5,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c73d4f0e-403a-472a-8a03-915ff1f63845',
  '8216',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  6.14,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3b1c2244-f665-4b89-9a62-ce374d2367dd',
  '8217',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2b143678-7bf4-4785-aa29-b8c47b37ee9a',
  '8218',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'received',
  7.62,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '12300e82-dbd4-42b6-9809-fc1209a63eb0',
  '8220',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'be86c9e5-1535-426b-bb50-8ae0cc990616',
  '8221',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Kevin Hoffmann',
  NULL,
  NULL,
  'received',
  6.05,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b29438f-5562-4709-9f70-2463552c7dd7',
  '8222',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5b79d8c4-cfbb-4532-b7d5-695c9d7b1f28',
  '8223',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  15.4,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '382b0b32-e40b-4be1-80a5-eed956b1d3aa',
  '8224',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  29.9,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b02079a7-d62b-49e2-95e8-6a357e23d1cf',
  '8225',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bf365482-ab37-4b02-9aaf-9bc26d85b7fa',
  '8226',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zanaz',
  NULL,
  NULL,
  'received',
  3.85,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '02919017-22b3-4ad6-b559-b527e90affd9',
  '8227',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'received',
  19.36,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6d40ea36-122b-4f0e-97cc-fe24e4133c7b',
  '8228',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  22.0,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6d236dcd-ad5c-4806-b5f8-7f5f90fab00d',
  '8229',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  22.0,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c652402-212d-4919-a4fc-218e2b359b72',
  '8230',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  22.0,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8a00aa54-63d2-4b4b-86ca-02b32ce21b35',
  '8231',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  11.0,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd50864f1-2911-4590-b4cd-e52d258ca88c',
  '8232',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  3.96,
  '2026-02-05 09:00:00+00',
  '2026-02-05 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '38ba80c6-fa11-47fc-bdd8-5e656a0cadda',
  '8233',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  3.3,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4169fd0c-b814-4b7c-b2e9-dd94fb65d849',
  '8234',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  20.02,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c20457ca-b2e7-4d49-930a-2bb1d99f475b',
  '8235',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a501d8b2-7c03-4a6a-a590-bd48089cf1ed',
  '8236',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kem',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c9dac062-e591-4318-80a5-1fb4751f18e2',
  '8237',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  8.98,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eea82d21-7af0-4dcc-942d-912dd5d55189',
  '8239',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  3.85,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2a1d15d6-0400-407a-8694-abcb9e92181d',
  '8239',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  35.75,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd47befda-c371-4897-b9d7-663421b8694e',
  '8240',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  32.5,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '11e0dfa9-e5cf-4b46-a689-29a250993b4e',
  '8241',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  32.5,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0bbd5fcd-b56a-49d3-b733-dccbde4b3469',
  '8242',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  32.5,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '63cc514b-369f-4e04-ab5d-dab221150718',
  '8243',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Rohan',
  NULL,
  NULL,
  'received',
  19.5,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0040d8ba-3009-4a19-9ce4-04d171e36682',
  '8244',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'R ohan',
  NULL,
  NULL,
  'received',
  26.0,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '476fa9fa-3641-4e47-a3a7-5e1ae15d909c',
  '8245',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  7.41,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4b344e5c-c2a5-4b75-9098-da244a1ec00c',
  '8250',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '914c9502-55e1-40cf-845c-f4ac7346da17',
  '8249',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  1.34,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3c4d98ac-b18b-4039-bdf3-acbf1eaadc62',
  '8248',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  14.95,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '30cc4d58-f91a-4c34-a8c3-d863c5d694ce',
  '8247',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e3f60d7d-0b6b-4a99-83f4-957d36606d25',
  '8246',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  20.68,
  '2026-02-11 09:00:00+00',
  '2026-02-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8a6d62ea-4151-4b7c-990d-783a55317e18',
  '223',
  'guest_laundry',
  NULL,
  NULL,
  'Davidson',
  '223',
  'received',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1b8bd3a8-5d4c-440f-ba98-12706b325a38',
  '8251',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4b10a26f-7ae3-46c7-a81d-258f61c76cb2',
  '8252',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '06b7b1f1-a2f6-47b4-9265-d83772603243',
  '8253',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'collected',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fbb9ddf6-83d6-484c-9f80-1b48194705b4',
  '8255',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  24.86,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a4337c74-6558-49b2-8d42-e27d4bdcb917',
  '8256',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'LFT'),
  'Norbert',
  NULL,
  NULL,
  'collected',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c9357da-759e-4caa-9c07-61abdd0bc7d3',
  '8257',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'LFT'),
  'Norbert',
  NULL,
  NULL,
  'collected',
  NULL,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '49690d4a-cbeb-4536-a6cc-058bb345d1bf',
  '8258',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '370e74ac-6b23-4161-80d0-a79a0c446c04',
  '8259',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Baye',
  NULL,
  NULL,
  'collected',
  10.1,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f25e2a14-9c0e-40c6-8ce9-edb5f1bcbb41',
  '8260',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8470d885-fe8e-4591-ad7b-3794a94eb2e6',
  '8261',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '33523d54-f6fc-4d71-98bc-fdd4d82fb420',
  '8262',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '34d18743-c765-48d7-99c1-36c8b4313343',
  '8263',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  8.97,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9ea49935-5148-4310-992b-f9e4678485ce',
  '8264',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  4.84,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '24345c44-fe3e-44d5-8072-0e0e3bb7dbc5',
  '8265',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Lewis',
  NULL,
  NULL,
  'received',
  15.4,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '77da330d-ef3d-4da2-a83f-1fb2682b364a',
  '8266',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-12 09:00:00+00',
  '2026-02-12 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b4e16b24-47dc-4b33-8fa5-1dfae6b922ae',
  '8267',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  6.42,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0c5cd8c3-adf8-454a-b714-94b32d62663d',
  '8268',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  27.72,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0a073710-f163-4624-b345-6fe19d233857',
  '8269',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Dariusz',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a4ecff43-8451-4ef2-a0e0-b9f17afdc44b',
  '8270',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  3.96,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8f001e01-3ebc-4355-8c97-04c9bf34db3c',
  '8271',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '345217fb-7981-45f9-b1cc-c0958f381890',
  '8115',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Dou',
  NULL,
  NULL,
  'collected',
  4.95,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b61c0cc2-b140-430b-8850-c16f1ab12063',
  '8114',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Dou',
  NULL,
  NULL,
  'collected',
  6.85,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8c1d6e62-738b-4cb4-bc71-5a5fa459047f',
  '8272',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0cbc88d3-d6bd-46a2-901a-9bb5d2fecb28',
  '8274',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  9.32,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd84ae450-f046-4f36-b175-bf6dffa88c7a',
  '8273',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '43619760-fecf-443d-b58a-3b0146af5356',
  '8275',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '93578452-d94f-47bf-9d09-c0e696bcd9b8',
  '8276',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  7.41,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7d1ca2b1-16f5-4938-8b22-3be6bc4ea104',
  '8277',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  17.38,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5d652f7f-fe8e-40f3-9d9f-222507954021',
  '8120',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eef60fe9-857b-49b7-bf4c-1bd5d0aa90f4',
  '8279',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  36.74,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c654b518-6a2f-4661-a5a6-5e89ee63af21',
  '8280',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  7.7,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e7c9500e-f497-455f-b388-30f30826d48a',
  '8281',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  2.82,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '50b07e32-2bfb-4b2f-94b3-bc584102faea',
  '8282',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Kamrul alam',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '325ee689-3860-45d9-8864-e2cd084c978d',
  '8283',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c3367a1-bc4d-46cf-9cc0-ffa138387044',
  '8284',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '316bbcc4-b250-43b4-b937-d9c2b207ed05',
  '8285',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  14.08,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a35f630f-e361-4f8e-bedb-dbef63144f08',
  '8286',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Adomas',
  NULL,
  NULL,
  'received',
  3.85,
  '2026-02-13 09:00:00+00',
  '2026-02-13 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '836c7341-b62f-46fa-825c-4809efb86e00',
  '8287',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  4.95,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '312b8d7a-dea4-4914-9085-1d14034287fe',
  '8288',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Telmo',
  NULL,
  NULL,
  'received',
  17.82,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '40d26299-5c6a-42ef-8880-36e6a171f0bf',
  '8289',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Telmo',
  NULL,
  NULL,
  'received',
  22.0,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5a924156-df4b-4182-b191-b6123e6630f6',
  '8290',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Telmo',
  NULL,
  NULL,
  'received',
  22.0,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b341e154-0a3d-4b2c-b496-3a51fd42f840',
  '8293',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7c9d83f7-26f8-416f-b5a9-1c78ea0a172e',
  '8294',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Telmo',
  NULL,
  NULL,
  'collected',
  5.94,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9f07aac4-f334-49be-8e5f-8b6b036cff9b',
  '8295',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Dina',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6b0b2a30-c512-49dc-9730-8f26bfa13277',
  '8296',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  6.38,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '26c181f5-4110-40fa-a5d0-cb664bdd9fe4',
  '8297',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'KE 20',
  NULL,
  NULL,
  'received',
  4.84,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2672de2b-aa1b-483c-8611-eeca1b6cf223',
  '8298',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  7.41,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a5b634e7-2869-4d61-af00-55bf7986b365',
  '8303',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'received',
  38.87,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd74c83c3-4125-4e86-9d49-77492123d8bb',
  '8304',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '36fa3b02-cc7c-4358-a180-8046cbfb12bb',
  '8305',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-15 09:00:00+00',
  '2026-02-15 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '210535ae-fb7c-4e45-bb52-ad9c0adf707c',
  '8306',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  38.87,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '87a01a3c-f820-4ffd-a35f-03f391a86d9d',
  '8307',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '59e6394b-c7d7-4b05-b349-f5d42e39c044',
  '8308',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd1ea8548-3308-4a84-99f3-0e48f0e9bca3',
  '8309',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  7.26,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c9ef1ac3-1c3d-48be-b7fd-ff2f1bcfbca6',
  '8310',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  8.47,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '11f290ed-75a6-4f61-80f8-a0da8fd54614',
  '8311',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Cadija',
  NULL,
  NULL,
  'collected',
  4.29,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c841c893-8b9a-42af-8c71-db506ea9710b',
  '8315',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Kye',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8f88590f-24e1-43e3-b4fd-2ad8ce1ce126',
  '8312',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Leila',
  NULL,
  NULL,
  'received',
  27.5,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dc02b36a-5e20-4e97-8e0f-1c335cd0feeb',
  '8313',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '60e46caa-af6a-44cb-af2b-974e1b93a7b4',
  '8314',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Tony',
  NULL,
  NULL,
  'collected',
  7.79,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '65cc57a1-82c4-4bbf-a954-a787a79560f8',
  '8316',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  2.82,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4070d273-c157-4c79-9d6d-f4e500875481',
  '8317',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '244ffa6f-4877-4917-abb5-8a1f3241af84',
  '8318',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '35a4c4f0-054a-4790-bd3d-328903aff403',
  '83195',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'received',
  7.97,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '02ef67e3-08e4-4cf5-a3f2-ab6edeed00ac',
  '8320',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  1.34,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b6f5f1c-0c0d-4094-a6fd-ab8c3a6d87a8',
  '8321',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  9.9,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '40a19d12-cf1c-41a0-ad85-42fa08def821',
  '8322',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  26.91,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9687926f-a0c5-4084-90c1-025da2995d12',
  '8323',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2b3d968a-450c-451c-9594-05b654fddc2d',
  '8324',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  2.09,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '967269e3-88a8-48ba-a8ed-8ab1b10df5dc',
  '8325',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Adomas',
  NULL,
  NULL,
  'received',
  17.16,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9098dcf2-aebb-4fd4-9e50-552c5b66fc92',
  '8326',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-16 09:00:00+00',
  '2026-02-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '55ac2536-af8f-47e3-ae0a-7038a1d9c831',
  '8327',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  14.25,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b2768f41-4a74-4c2c-99df-df82966cadfd',
  '8328',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  4.4,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9843921-bf56-44bd-8b4f-0e13fb93f1bf',
  '417',
  'guest_laundry',
  NULL,
  NULL,
  'Kevin',
  '417',
  'received',
  NULL,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '12c25677-8ffb-40eb-aa8f-04606dbdcdb5',
  '8329',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f6c64962-052b-4dea-9cb6-9be4c267a276',
  '8330',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f0abed9b-be4e-4668-bc39-3bfc5f2e1f49',
  '8331',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'collected',
  NULL,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'acba3694-2a08-4f93-bedf-bb6ce6d3e132',
  '8332',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '323cc584-5ad7-42bf-8fd0-c253fd4608ef',
  '8333',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'KE20',
  NULL,
  NULL,
  'collected',
  20.68,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f08a90b4-acae-41ee-990a-b7f147213ecc',
  '8334',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '96bcd7a3-799f-4748-8676-641aeca9b156',
  '8335',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  4.4,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6b61e26f-6e4f-48ce-9535-b79876808507',
  '8336',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  4.95,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '83813e93-cfad-48f5-bff9-642817a2fcf7',
  '8337',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  44.85,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c530d1f-e5d3-4a3f-8002-3f9b0c9a6eac',
  '8338',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'da8843a3-5fc3-4997-b447-c3d1bbcbc327',
  '8339',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '56575fe9-892c-419c-92d8-bd6b10593dc5',
  '8340',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cce79f84-2cb1-4758-8935-36e10ab105c1',
  '8341',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '985b6dcb-1424-445d-9322-68ea4927e1df',
  '8342',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'received',
  7.7,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '194816f7-c874-4bf3-b208-351f84f00416',
  '8343',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cd9a9d8e-63b9-47f3-8e9c-26181acc6b32',
  '8344',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ked',
  NULL,
  NULL,
  'received',
  14.96,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '535fccad-4e2d-4a89-8f4c-b7b5787d85b1',
  '8345',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Wania',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-02-18 09:00:00+00',
  '2026-02-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8579f60f-237d-492a-a595-bda7a6c32e7b',
  '8347',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3eb5e3e8-816d-4785-8e68-2ddc156f1c74',
  '8346',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Georgi',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'af48878f-901b-4f3a-a534-a9f812dbe88c',
  '514',
  'guest_laundry',
  NULL,
  NULL,
  'Palato',
  '514',
  'received',
  NULL,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0359c2b8-34ba-4c50-a3f7-460f9c6783af',
  '8348',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'received',
  17.21,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c0ab384-e11d-4eba-bca6-0b7d279d15e1',
  '8349',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '16d3b596-7cfb-4a31-a914-43af0ab17da6',
  '8350',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  20.9,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2fbd8fe3-69c6-41d0-bf73-d2f5d3bd32d9',
  '8351',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  29.9,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1d28cd31-8215-48fa-acaf-21135e20a49d',
  '8352',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '360500d4-4e71-4eee-aa6a-b10806155f23',
  '8353',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9f44e53c-09db-44f8-822c-d3c39a539215',
  '8354',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9348f59a-c687-447b-884c-3ab2aa461dbb',
  '8355',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  7.48,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b22cfe3d-0789-4d80-9ddf-1de8cd3e04de',
  '8356',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ke29',
  NULL,
  NULL,
  'collected',
  16.28,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f72906ff-d4e7-4099-84d4-6b9873c5ddaf',
  '8357',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayela',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1edb99e2-c82c-4ad1-a290-257179460d7e',
  '8358',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Snehaa',
  NULL,
  NULL,
  'collected',
  38.5,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f51982fe-7c41-4727-bc45-b9f126a717c3',
  '8359',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  12.32,
  '2026-02-19 09:00:00+00',
  '2026-02-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '78b41182-334e-4096-a982-23b573f126ab',
  '8361',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  4.84,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a6840986-7675-4460-bec5-a3a4a844a061',
  '8362',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0099503e-ad9f-434c-b58a-12d0406bb6a1',
  '8365',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'da4d119d-9cd4-4807-977c-e9109d26dc49',
  '8363',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '940fad38-9a73-4997-a0cc-15519d732d33',
  '8364',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '39b5c550-1d1b-4b31-8988-4d1eb34cfb37',
  '8366',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '179226cc-281e-45e8-b872-49c8f2ec50b4',
  '8367',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Kevin Hoffmann',
  NULL,
  NULL,
  'collected',
  12.65,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '08165fef-d75b-40da-be65-bd8f77c67f8b',
  '8368',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  14.74,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a46d424a-cf91-4233-89eb-5a8ad6d347ae',
  '8369',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Jc',
  NULL,
  NULL,
  'received',
  14.52,
  '2026-02-20 09:00:00+00',
  '2026-02-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b95b6e9d-d403-40ec-8c59-235ef0e47e3d',
  '2369',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'submitted',
  14.96,
  '2026-03-22 09:00:00+00',
  '2026-03-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '12164ff3-ac4e-4f4c-bb0f-dd244600a701',
  '2370',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'submitted',
  3.81,
  '2026-03-22 09:00:00+00',
  '2026-03-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '63bd31b2-b0eb-4198-bd1e-25de8938b7ed',
  '2371',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'submitted',
  3.81,
  '2026-03-22 09:00:00+00',
  '2026-03-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c8ec1d51-7add-43f0-bd2e-92bbc5ab1e44',
  '2373',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giovanni Di palo',
  NULL,
  NULL,
  'submitted',
  3.81,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '088de4c5-8511-410e-b30b-4d643b4b1a77',
  '2374',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zaki',
  NULL,
  NULL,
  'submitted',
  59.8,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0d7e8220-c892-4552-b6d1-c78950aee187',
  '2375',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'submitted',
  4.95,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '066f0233-16ed-4a3d-9091-25c5f72c2a4b',
  '2376',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'submitted',
  2.33,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '195ed83d-aa97-4dda-92e9-6a78519ab6f4',
  '2377',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'submitted',
  2.33,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd7e43856-90a9-4968-8363-6e8bad2f2421',
  '2378',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'submitted',
  10.56,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0e582224-4aae-4f78-a80a-d9e654f36452',
  '2380',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Bledar',
  NULL,
  NULL,
  'submitted',
  8.47,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4f1c681e-59d6-4f28-a307-a4c329b0a344',
  '2379',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'submitted',
  5.94,
  '2026-03-27 09:00:00+00',
  '2026-03-27 09:00:00+00'
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '026a1e58-2617-4544-ab6a-1dbed513343f',
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7c84555a-31e1-45be-96ad-9138319afa0a',
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0917f997-8b85-4186-bada-f985e8e1d6e0',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'efad49ad-f40d-4b4a-a91b-221bb43f34b7',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ccdcd937-88ff-47b7-8645-57dcbf4980bd',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f036dadd-13b6-44e8-8843-7e37f88c227c',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f05d1b2a-9f59-454f-97c0-31266d0b722d',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f8affab-75d9-41d5-9cdc-039ebe12bec9',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '191da885-10db-483d-a715-8b98e7891d1a',
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8d86dee7-26ef-4cce-8085-520a11608ca6',
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e37ba786-9453-4b13-aeac-25adc1861ea2',
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  117,
  117,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '12cccacf-67b1-4888-a2e7-3631c35e6a29',
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c64ecbf3-6c89-4d76-9d11-6bf0fc79c8dc',
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a300ab03-fa04-4e02-bb85-6701dcf05276',
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ecb2821f-dafb-40e5-ab4d-1e324a7513b3',
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6bf09549-1543-4b5c-b98a-2b403d1a54d0',
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '85c539c8-2780-4871-b833-c8bf5e5ba103',
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd93bf533-e072-4cb7-90a6-96cb581c3953',
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  45,
  45,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a0f8ef7d-fe07-437d-92d5-cfa0696116f9',
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  40,
  40,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '318da038-5bd4-424c-af4a-3d801ac6df7b',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '31041176-5a20-4f23-a6c6-f3ef49d9642e',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  3,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fb9f6289-67f1-4b0c-a3bb-5fb18c4aa0a0',
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9296cabc-343d-427b-b204-3db017f545ee',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '21bef963-b87c-468b-82b0-2dce277e091b',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e6850232-92e1-4458-b138-27ab3b4ebef5',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0184510f-2c20-43fb-8293-368f981a34a3',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd6c78bb0-bbb6-4d37-9888-f28c551265d7',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a3c4656e-b347-4ed0-9c08-37bfae744729',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '55d7e126-21f5-4d2d-951c-e81a9d4e1938',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6a1011bc-5295-402c-8d1f-37a11f5204cc',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'aac3d742-3fd2-4c7f-b488-17a385408798',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f274965-de87-4687-ac92-5dcf5d89f7a7',
  'fd9ea6d4-6f9d-4716-8eaf-73678de9749c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  97,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '382c06c8-fe3d-4dc9-a33b-d9a202ba4f03',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '24dceb78-7dbd-48fb-9d19-a3d82896d70d',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4f0f40b9-9b81-4048-879f-4ed97b9afb3c',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1544e345-3f97-4981-aad8-896971f66aaf',
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f9126315-32bf-4c45-b142-f5bdc2acaa28',
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '847d7841-0adc-4df6-a122-7c09cfb8c5a6',
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ff367cd0-8b95-4ef8-8e8b-8c5015a375d3',
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4f3199c1-8fe6-4a9d-a1c1-b363794da3c7',
  '7f30ca80-817b-4bd6-ba14-b7c4979e69fd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '93e387c2-fe1b-406e-8b5f-d8f39d90fa2b',
  '875b6d3e-23c4-494c-8909-1696080c5534',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '10edeef3-8d67-4875-895d-d231e6c3a06c',
  '875b6d3e-23c4-494c-8909-1696080c5534',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6b61a7ff-5ab4-4aee-935c-6b40110a9159',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a9ed3f36-4113-4dde-b1dd-25439260b779',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '302d320f-07dc-45fb-94e5-f314f702dee0',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '44619791-14bd-42df-8786-68f576c100f2',
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6bff8dbc-cb07-4ceb-bbd0-80ec733be220',
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fab41113-ed27-406b-a896-25d6859fca87',
  '6569e083-1a87-414a-bc45-63fbdb8276bc',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  54,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '48836fa0-3291-4c4c-ad4b-c749f94f27be',
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  50,
  50,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8a1fc1df-3058-44e9-8af4-edd3ec23b0ca',
  '7a2cdc75-b35a-40e8-8110-039963d99857',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-004'),
  'Dress',
  3,
  NULL,
  5.5
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a27c312-7de0-4931-bed2-4072872c9ac3',
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'db2c8221-baeb-4431-b77e-8127dd0b32bd',
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9fadb30c-355b-4d16-b080-be58b79f1647',
  '60548ae5-82fc-41ed-92d9-f48fb8912977',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a8c5ecfa-77db-4fb6-be74-ce8134c3e262',
  '02e829f0-e607-47f7-8eb7-5cf1d93ab616',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  5,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '225c5b5b-0dc4-433c-94d9-9ca3ee457b34',
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '797f00ec-dade-4dc1-a457-2768a8e79ae5',
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'afa97e49-8f11-412c-987e-2b76fcc64284',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9b7008b4-c815-4013-9621-93ab9ce3dc34',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '522bcecc-4aed-4e09-aa4c-45d4389e5ae9',
  '08b61ef7-5428-4670-afb8-905fb7ff9301',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  33,
  NULL,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd187ca04-dd1c-4272-91c2-51703c94aad8',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5b7ae823-e4fb-43fd-81f8-0c9d45efa8af',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'df0696b4-05c3-4932-bdbe-62f72aabe526',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '45dfb7f2-2926-4835-8962-9f27390ea545',
  'de9a3c5f-a818-419e-8506-544eb8d2867d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  32,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9279cabe-176e-48ea-856a-547f679668b3',
  'edc3c126-5e94-4baf-a27b-e7d0d5bf8b0e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f243cb9d-3811-4cd9-8667-e326d210c129',
  'edc3c126-5e94-4baf-a27b-e7d0d5bf8b0e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8ff42a11-b387-435e-b304-4091883b4d5c',
  '33a3e2f2-19f8-43b1-95c9-4a8f12bedfa6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'aaa11ac3-092f-48b4-9165-0b062f1f2579',
  '33a3e2f2-19f8-43b1-95c9-4a8f12bedfa6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f6c0f4a3-c9fb-46eb-ac02-b62552306b67',
  '49076719-8ce0-40ee-99fd-b8cbf5fa7165',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4046ee5b-0a5b-4675-8cc6-7662393b5af2',
  '49076719-8ce0-40ee-99fd-b8cbf5fa7165',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cfd1eeb8-9e8c-4fb1-95ac-c9ae90c14241',
  '6f2fed1d-585f-4db8-b993-443de674c993',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  3,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ead769ad-6775-4f7f-ba93-d7a87f0e61f6',
  '6f2fed1d-585f-4db8-b993-443de674c993',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f3fd44d-9860-48b9-b0c1-a69ecf634841',
  '4404609c-cf78-4e56-aad8-6f7659db9f50',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  108,
  108,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ddacffa0-0a2a-4375-86fc-59cc2969216d',
  'f7c223b1-3315-42e5-b442-35b6bbf77fb0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4175cf6b-ba2a-4ca7-b184-b2897c0f7692',
  'f7c223b1-3315-42e5-b442-35b6bbf77fb0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0cc604cb-ae9e-4bac-9c8a-37af3b6190a6',
  '121e14e7-a0fe-409d-be93-fb6f1a9da6c4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f3fa1656-b36e-4340-bece-fa579b193db2',
  '252af30a-300e-4bca-93b1-1fa207571c8a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '75caaef9-027a-4ba2-904e-364b23570b8b',
  '252af30a-300e-4bca-93b1-1fa207571c8a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5709d676-cca4-4917-8b66-f4f24add118a',
  'c31b5514-12e8-4b96-b7bd-7abe16252f8b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '43acb3d9-8d8c-416b-9f05-cfa72e4a57d9',
  'c31b5514-12e8-4b96-b7bd-7abe16252f8b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '70b82f84-056a-4980-97cc-1c303ed3547e',
  'c31b5514-12e8-4b96-b7bd-7abe16252f8b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '09769e98-af47-4fa2-ba23-fcb805a0ddd8',
  'd5157592-7d88-467b-88b5-1213603ef57d',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3fbd9fa5-8359-4982-ae9b-823d3f78ef99',
  'b08369b1-a5da-4ba1-ac11-1f6a922ac9d7',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  49,
  49,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '88f6a148-6a5f-4e21-92e6-4f2ef4a8df05',
  '8cf38fa7-120b-4ba9-9cfe-c5bb6799b310',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b39bef5e-0687-4af1-a155-fe13b3287dc6',
  'c3ef3440-ba35-4cda-bcb5-1da3160b14fa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  2,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '55523d40-8625-412c-a432-2e524adc3631',
  'c3ef3440-ba35-4cda-bcb5-1da3160b14fa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9da616d3-eacb-4deb-8aec-56dec562b15e',
  'dfc768ed-87d4-491e-b077-1893bceba970',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c6513089-9d8c-490c-a073-519b8060f149',
  'f386b1ff-e834-4442-a38a-991bba9b3854',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  77,
  77,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '86395355-f813-438c-acaf-b4234311494b',
  'a2585545-7bc2-4b45-af38-f28752333d40',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e671cf84-abe3-494e-a270-aaadc6dd6992',
  '3c133b9a-4550-4488-9978-161d0aa2b457',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6380c039-b5bd-4802-ac57-08ad2063119e',
  '3c133b9a-4550-4488-9978-161d0aa2b457',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c8b19672-d1e5-45b2-a583-83b95caafdfe',
  '3c133b9a-4550-4488-9978-161d0aa2b457',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '070f2eeb-2ee5-4c4f-929c-8d65e7634166',
  '7b74b6cf-4b5e-422a-87e6-0c9840057028',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  164,
  164,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '30805bdc-662e-4466-92b0-aeab87ef706f',
  '9c0cf2c4-d6b4-4d80-aad2-83afe47815d3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  1,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '238fae0a-68b2-42b2-be40-d9e4695ab8f6',
  '6f5eb02b-7f5a-4884-8a7d-0f49e3c2a899',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '238d4c47-faa4-4dd2-8ff7-bd95717b5878',
  '6f5eb02b-7f5a-4884-8a7d-0f49e3c2a899',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '59a6b123-94de-4e9d-97db-ac9b3e3f4ae5',
  'a250bd04-3960-401d-9db7-f3a49fb238e4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  3,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6f177dfb-4504-4def-abad-ad82b0f21f16',
  'fb9a1f6f-050f-401a-be9b-0e7f34b65f63',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  5,
  5,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f6df7db7-f180-44a0-ab39-9b0b078e3a36',
  'c987cd87-98fa-4de7-9592-a9b7cbd7dd79',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  8,
  8,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dab32855-8b84-48e7-b82b-261bc67aab5d',
  'dee072d7-1c66-4648-8184-aa9732888d43',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  1,
  1,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb07ce91-d439-4183-993c-537e8090a205',
  'a08a334b-e730-40d7-8fa3-c08cb915026a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '37211ded-74f3-4216-9645-32ee6d2721be',
  'a08a334b-e730-40d7-8fa3-c08cb915026a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bcaacc13-27ce-47d0-b805-328b23a33a3e',
  '48c2a4ef-81d7-4a67-83f4-acd0ffbab0ae',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  5,
  5,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e91dbf72-caef-44dd-9241-07b106ec5eb2',
  '276519da-8202-4bd4-98f5-03c113c37b2c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7bcbee17-58c8-41e3-922e-29ecb981be65',
  '276519da-8202-4bd4-98f5-03c113c37b2c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '83743533-3bea-48b7-b73d-7a18ba29c215',
  'b8f3b31b-9255-4ca0-b64f-ff271753af28',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e797cf43-d113-494c-8df8-4c77a5f51e53',
  'b8f3b31b-9255-4ca0-b64f-ff271753af28',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ad19c8d6-0c2b-4698-813f-4251e6f87a38',
  'f6c045c0-90e6-4cdb-92be-fcf9977ff772',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  37,
  37,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e66159e7-caaa-43a5-a50a-b5b866c80033',
  '4d3de683-611b-4327-8b55-1d769bf75d84',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  49,
  49,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3d9ba289-d746-4285-abd3-3a89b9860573',
  'e79df79d-0c1b-4458-9923-ff985afea38a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c46eb63c-345a-486c-9a72-31355f9393c2',
  '20b1ef67-bac2-4d97-b680-510874eb451d',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4744e09a-5322-4f96-966b-4e6e619d8582',
  '91474a85-88e6-44bf-bb81-bbfa47e00912',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f6f2912-a4d1-4f92-bb51-f5868b12f03a',
  'c3817573-c6d9-4433-8a64-c86dc7b103df',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4af191d9-deea-4a3b-83d7-8c6caf65c1d2',
  'c3817573-c6d9-4433-8a64-c86dc7b103df',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a30f4a60-5e17-4f97-8caf-9c64acb4ea99',
  'c3817573-c6d9-4433-8a64-c86dc7b103df',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd5273c9f-e020-4c3c-8527-30b5c3a97395',
  'ceb4ce60-fc2e-4d0b-9ace-5589ff07b1af',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  13,
  13,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '85079c98-fa70-48d2-9628-23aabe140294',
  '81f84a86-5a14-435b-bdfd-c5a92349ec36',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9ac11215-c328-40b3-a5b3-f6bf832c02d1',
  '5bf8ad43-72ad-4609-a534-b0dc86dc9ee7',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  9,
  9,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5cc6c21a-2783-4185-9ed2-04196b9e0a0e',
  '0e6d4f3e-3271-4f3f-ac93-d2544785867d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f1e29790-135f-4e4e-9472-3ca5ce574ae9',
  '0e6d4f3e-3271-4f3f-ac93-d2544785867d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b41499ab-12c2-4bac-ada4-db9094966481',
  'b5ea4bd5-6f6a-46ef-b746-088ca4c2d213',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '37f34fba-7cf4-4900-96b7-079c24ec49de',
  '51f5494d-0178-492e-9462-3be7e817f0b5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '621b90bd-c855-43c8-b984-21c1265e888e',
  '51f5494d-0178-492e-9462-3be7e817f0b5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '40b73ac3-beac-425f-834b-016ee03a9ceb',
  'dc25093c-844a-4830-a0b5-efde1e12f04d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  79,
  79,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3baba02c-1f36-470c-92c9-0ed0f36d5b89',
  '05c47d77-a65b-451b-be0a-9710e24840cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '700b1f66-7a93-4166-bf97-c965ea143d34',
  '05c47d77-a65b-451b-be0a-9710e24840cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '79846267-d743-448b-aec3-0413c45db716',
  '05c47d77-a65b-451b-be0a-9710e24840cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '80efd154-b2f0-40f3-b2e1-eb0ddc3db7a2',
  '10bdcd01-ca64-46f7-b05a-662d8f37fbd6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b5f55664-c641-4b4f-9a5b-8cf6e8e81211',
  '10bdcd01-ca64-46f7-b05a-662d8f37fbd6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2f0db39c-5eef-4c0d-9360-3bf2a813ace4',
  '10bdcd01-ca64-46f7-b05a-662d8f37fbd6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '47e5e797-efba-4af0-b55e-5eb73a92f09e',
  'da236e8f-d47b-4091-bf45-c261e139ae67',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  29,
  29,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a84ed444-b91e-4a9d-b3d6-c69b8ec631eb',
  'b59aae24-62ec-4f6b-b6a3-d4b24fdfb5fb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3641f161-1e7c-43d3-a2ff-fe43290dfc94',
  'b59aae24-62ec-4f6b-b6a3-d4b24fdfb5fb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  2,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8cd368fd-a698-4743-9fd9-28b848b1bf78',
  'a69f7d41-aa38-435e-9c6d-7b8f9002e9ba',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  22,
  22,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '700316ab-dd94-4395-a0f8-a30b2e202631',
  '488cffa0-690a-4338-96d5-0fad96deaaff',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '73aa9a36-2fd4-4e90-8265-83e46e04a346',
  'd7686c8b-caf5-4fb7-a93f-8a0c73af3453',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '64e19162-9775-4e55-b4ca-df37c7a285f6',
  'd7686c8b-caf5-4fb7-a93f-8a0c73af3453',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bb6ce7d3-240d-4ccc-9cd1-9590f14b9591',
  '66adeeeb-01ff-43c9-9d4e-068f65ce5a5e',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  3,
  3,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '62306422-10e7-4404-82a5-3102bffaa387',
  'e6a9a423-a19f-4a6a-a063-0eddb3589d96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8508b128-9791-4c4e-9835-5a2f69e4fa06',
  'fd2574a2-ed5d-48f9-a40c-c6e0648fe919',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd3c943c7-224f-45b5-ac54-a350da0c9951',
  'fd2574a2-ed5d-48f9-a40c-c6e0648fe919',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '89eda82d-a7af-46d3-a1d2-a285e5cc5dd0',
  '675a2adf-476d-4a98-a4f5-e3b3cbcc36aa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b7b04c90-71aa-42b7-9439-f1c0bd2b2886',
  '675a2adf-476d-4a98-a4f5-e3b3cbcc36aa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b998d27f-cd77-4614-b872-c0d3076d4177',
  'f9cc355d-5bb9-4505-8045-b5e4b401dc9a',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  78,
  78,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f3afcd5e-432e-43f0-8983-8a5ed576cfad',
  '2ae77a21-14a0-42a1-82f5-bd12e60dca35',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04cccbcc-b88b-4980-8f5e-221dd18b24d7',
  '2ae77a21-14a0-42a1-82f5-bd12e60dca35',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '697b13ad-c7d5-4eef-a869-57ba85c2ba20',
  'f6c6554c-dc5b-44c3-bb74-7f3a0bf6d2e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  4,
  4,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '860a64ac-0ae7-48c9-a99a-24b5a9ce90b6',
  'f6c6554c-dc5b-44c3-bb74-7f3a0bf6d2e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  3,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '091a0caf-4351-4379-8a49-a36f52df8cf9',
  '8f680c13-3ed2-4a97-bba0-163cc9fa78f3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

COMMIT;