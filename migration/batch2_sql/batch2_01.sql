BEGIN;

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  '7707',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  3.32,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  '7708',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  '7709',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  '7655',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  '7712',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ke20',
  NULL,
  NULL,
  'received',
  25.74,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  '7713',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  '7714',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  '7715',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  '7716',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  9.9,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  '7717',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  8.8,
  '2026-01-03 09:00:00+00',
  '2026-01-03 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  '7718',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Tony',
  NULL,
  NULL,
  'received',
  6.05,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  '321',
  'guest_laundry',
  NULL,
  NULL,
  'Joan',
  '321',
  'received',
  NULL,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  '7719',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  '7720',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '37a5e027-1096-46fb-bb38-7639e879a699',
  '7721',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fd9ea6d4-6f9d-4716-8eaf-73678de9749c',
  '7722',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ke20',
  NULL,
  NULL,
  'collected',
  21.34,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'baf18642-8d39-4d24-a385-29f60afccebb',
  '7723',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  '7724',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  2.09,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  '7725',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7f30ca80-817b-4bd6-ba14-b7c4979e69fd',
  '7726',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Cadija',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '875b6d3e-23c4-494c-8909-1696080c5534',
  '7728',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  '7729',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  '7730',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6569e083-1a87-414a-bc45-63fbdb8276bc',
  '7731',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'collected',
  11.88,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  '7732',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  11.0,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7a2cdc75-b35a-40e8-8110-039963d99857',
  '7733',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Snehaa',
  NULL,
  NULL,
  'collected',
  16.5,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  '7734',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '60548ae5-82fc-41ed-92d9-f48fb8912977',
  '7727',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayelahad',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '02e829f0-e607-47f7-8eb7-5cf1d93ab616',
  '7735',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  8.7,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  '7736',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  '7737',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '08b61ef7-5428-4670-afb8-905fb7ff9301',
  '7739',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'collected',
  98.67,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  '7740',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'collected',
  4.84,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'de9a3c5f-a818-419e-8506-544eb8d2867d',
  '7741',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'collected',
  7.04,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'edc3c126-5e94-4baf-a27b-e7d0d5bf8b0e',
  '7742',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-04 09:00:00+00',
  '2026-01-04 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '33a3e2f2-19f8-43b1-95c9-4a8f12bedfa6',
  '7745',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '49076719-8ce0-40ee-99fd-b8cbf5fa7165',
  '7746',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6f2fed1d-585f-4db8-b993-443de674c993',
  '7747',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  10.45,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4404609c-cf78-4e56-aad8-6f7659db9f50',
  '7748',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  23.76,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f7c223b1-3315-42e5-b442-35b6bbf77fb0',
  '7751',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '121e14e7-a0fe-409d-be93-fb6f1a9da6c4',
  '7752',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '252af30a-300e-4bca-93b1-1fa207571c8a',
  '7755',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c31b5514-12e8-4b96-b7bd-7abe16252f8b',
  '7753',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'collected',
  4.84,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd5157592-7d88-467b-88b5-1213603ef57d',
  '775',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b08369b1-a5da-4ba1-ac11-1f6a922ac9d7',
  '7756',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ben',
  NULL,
  NULL,
  'received',
  10.78,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8cf38fa7-120b-4ba9-9cfe-c5bb6799b310',
  '7757',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayelahad',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c3ef3440-ba35-4cda-bcb5-1da3160b14fa',
  '7758',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Nihal',
  NULL,
  NULL,
  'collected',
  7.74,
  '2026-01-06 09:00:00+00',
  '2026-01-06 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dfc768ed-87d4-491e-b077-1893bceba970',
  '7759',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f386b1ff-e834-4442-a38a-991bba9b3854',
  '7760',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  16.94,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a2585545-7bc2-4b45-af38-f28752333d40',
  '7761',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Simona',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3c133b9a-4550-4488-9978-161d0aa2b457',
  '7762',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b74b6cf-4b5e-422a-87e6-0c9840057028',
  '7763',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Claudia',
  NULL,
  NULL,
  'received',
  36.08,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9c0cf2c4-d6b4-4d80-aad2-83afe47815d3',
  '7764',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HRS'),
  'Admin',
  NULL,
  NULL,
  'collected',
  3.0,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6f5eb02b-7f5a-4884-8a7d-0f49e3c2a899',
  '7765',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a250bd04-3960-401d-9db7-f3a49fb238e4',
  '7766',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  3.3,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fb9a1f6f-050f-401a-be9b-0e7f34b65f63',
  '7767',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Lorraine',
  NULL,
  NULL,
  'received',
  16.25,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c987cd87-98fa-4de7-9592-a9b7cbd7dd79',
  '7768',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Lorraine',
  NULL,
  NULL,
  'received',
  26.0,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dee072d7-1c66-4648-8184-aa9732888d43',
  '7769',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Lorraine',
  NULL,
  NULL,
  'received',
  3.25,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a08a334b-e730-40d7-8fa3-c08cb915026a',
  '7770',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '48c2a4ef-81d7-4a67-83f4-acd0ffbab0ae',
  '7771',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  14.95,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '276519da-8202-4bd4-98f5-03c113c37b2c',
  '7772',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b8f3b31b-9255-4ca0-b64f-ff271753af28',
  '7773',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  5.5,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f6c045c0-90e6-4cdb-92be-fcf9977ff772',
  '7775',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  8.14,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4d3de683-611b-4327-8b55-1d769bf75d84',
  '7776',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ghv',
  NULL,
  NULL,
  'received',
  10.78,
  '2026-01-07 09:00:00+00',
  '2026-01-07 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e79df79d-0c1b-4458-9923-ff985afea38a',
  '7777',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  2.68,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '20b1ef67-bac2-4d97-b680-510874eb451d',
  '328',
  'guest_laundry',
  NULL,
  NULL,
  'Anne crossfield',
  '328',
  'received',
  NULL,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '91474a85-88e6-44bf-bb81-bbfa47e00912',
  '509',
  'guest_laundry',
  NULL,
  NULL,
  'Eustace ojie',
  '509',
  'received',
  NULL,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c3817573-c6d9-4433-8a64-c86dc7b103df',
  '7778',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ceb4ce60-fc2e-4d0b-9ace-5589ff07b1af',
  '7779',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  2.86,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '81f84a86-5a14-435b-bdfd-c5a92349ec36',
  '7780',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5bf8ad43-72ad-4609-a534-b0dc86dc9ee7',
  '7781',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  26.91,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0e6d4f3e-3271-4f3f-ac93-d2544785867d',
  '7785',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b5ea4bd5-6f6a-46ef-b746-088ca4c2d213',
  '7782',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.02,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '51f5494d-0178-492e-9462-3be7e817f0b5',
  '7784',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dc25093c-844a-4830-a0b5-efde1e12f04d',
  '7783',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  17.38,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '05c47d77-a65b-451b-be0a-9710e24840cc',
  '7786',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'collected',
  9.68,
  '2026-01-08 09:00:00+00',
  '2026-01-08 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '10bdcd01-ca64-46f7-b05a-662d8f37fbd6',
  '7787',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'da236e8f-d47b-4091-bf45-c261e139ae67',
  '7788',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  6.38,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b59aae24-62ec-4f6b-b6a3-d4b24fdfb5fb',
  '7789',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  11.5,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a69f7d41-aa38-435e-9c6d-7b8f9002e9ba',
  '7791',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  4.84,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '488cffa0-690a-4338-96d5-0fad96deaaff',
  '7792',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd7686c8b-caf5-4fb7-a93f-8a0c73af3453',
  '7793',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '66adeeeb-01ff-43c9-9d4e-068f65ce5a5e',
  '7794',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  8.97,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e6a9a423-a19f-4a6a-a063-0eddb3589d96',
  '7795',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fd2574a2-ed5d-48f9-a40c-c6e0648fe919',
  '7796',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '675a2adf-476d-4a98-a4f5-e3b3cbcc36aa',
  '7797',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9cc355d-5bb9-4505-8045-b5e4b401dc9a',
  '7798',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  17.16,
  '2026-01-09 09:00:00+00',
  '2026-01-09 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2ae77a21-14a0-42a1-82f5-bd12e60dca35',
  '779',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'received',
  2.82,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f6c6554c-dc5b-44c3-bb74-7f3a0bf6d2e8',
  '7800',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'received',
  8.33,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8f680c13-3ed2-4a97-bba0-163cc9fa78f3',
  '7801',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  2.82,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '307fa696-3438-40b6-8f5a-e10ffc7c1d61',
  '7802',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Claudia',
  NULL,
  NULL,
  'received',
  20.68,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '70097900-b669-47dc-882d-72ca848b9d46',
  '7803',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  23.76,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'efdaf5f6-3d84-40e0-9a1e-5b7d66fd94e2',
  '7804',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayelahad',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bfdb7313-f425-4b81-81b5-1d4fbce7fcb1',
  '7805',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '13f11513-9de2-4fc0-976b-96df0c4a4f66',
  '7806',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0bfdcc9c-8e67-4abc-b601-9aa6d2362f79',
  '7807',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Paul',
  NULL,
  NULL,
  'received',
  23.92,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '00b85dfd-7041-40d3-9ee0-8b59ef384fbb',
  '7810',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a4a11a01-7bb5-4128-8769-a0b74953f06a',
  '7808',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b27c509-c392-411d-a21f-91bfcbdbb3ea',
  '7806',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  10.12,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '15d750ed-f089-4a55-afb3-a7adcc7a4013',
  '7811',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'received',
  4.84,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fb013187-95c1-4945-adc8-20a3151ccecb',
  '7812',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  14.08,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9afb3cf-348e-4936-8ca3-a400c8b460ee',
  '7813',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Shahir',
  NULL,
  NULL,
  'received',
  2.75,
  '2026-01-10 09:00:00+00',
  '2026-01-10 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4ca6b4c2-d25b-4e3c-83ed-9593d5946406',
  '7814',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f6b5443f-5eae-4704-8f9d-36c1bb2f01ec',
  '7817',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '628b8395-d324-4950-9acd-1f364eac5af5',
  '7818',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e58adc67-3dcd-4b73-b5e5-9dc599c1968e',
  '7819',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Dou',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1b97f69b-fd05-42a0-8778-8a4c36e5d7b2',
  '7820',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Telmo',
  NULL,
  NULL,
  'collected',
  5.94,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'addff0f8-768f-4b47-b436-2c51f5c35c3d',
  '7821',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1516c5ca-3507-42fe-96e7-c2eb3d211f3c',
  '7822',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c0a98779-c59e-4198-ba59-c06eff5ff9b6',
  '7823',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8d73bced-1bd7-4258-a0e5-e57b8aa82d2f',
  '7824',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Paul',
  NULL,
  NULL,
  'received',
  20.93,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1911c51d-f062-4329-9696-10748193f63f',
  '7825',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'received',
  2.09,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '591beda2-0796-4145-a512-1e1915d26805',
  '7826',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8610b155-b355-4607-8315-f0bb3a2f9788',
  '7827',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Bledar',
  NULL,
  NULL,
  'received',
  6.99,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9d1f57eb-c4cb-473b-a329-3a15643e07e0',
  '7828',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  16.5,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ab174232-2993-42ea-97f3-b79ea5e75ba4',
  '7829',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'received',
  34.1,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e2e56841-d11d-4f97-a46f-d2a215b02e36',
  '7830',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c4656d0c-53b3-4cbe-8b5c-89171df99eeb',
  '521',
  'guest_laundry',
  NULL,
  NULL,
  'Dan',
  '521',
  'collected',
  NULL,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2fe85571-05fb-4db1-923a-aaf9362568ed',
  '7831',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  15.84,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0aac4863-87b3-4d18-b1c9-cf3a74ba3651',
  '7832',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd3b4629b-8bbb-4ff6-8d7f-bdfaa81ea77d',
  '7833',
  'uniform',
  (SELECT id FROM departments WHERE code = 'ACC'),
  'Tony',
  NULL,
  NULL,
  'collected',
  6.0,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '01e6b29c-bf6d-40ea-9894-1b931cc5fceb',
  '7834',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f728fb0c-d15e-45b3-9ee7-2babea5ef32b',
  '7835',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  9.46,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '568d9b19-b019-4b26-b147-cf6b46cafcc4',
  '7836',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b5494ba-fdfa-4383-8a9b-ad88131c7b99',
  '7837',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '737d257e-7990-41e2-bcb3-f7b7c92a6e59',
  '7838',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9d0b6d70-9258-4115-ae86-73b007c112ae',
  '7839',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  2.99,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7441afb8-f6bb-4d40-92ff-03d8a15fa733',
  '7840',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Hg',
  NULL,
  NULL,
  'received',
  11.0,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8a30c456-d943-4d3e-8d55-2e0675ae9130',
  '7841',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayelahad',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '281e69b8-d44c-44b4-8594-db26dbd09286',
  '7842',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  11.43,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'acebc1bf-9b74-4194-9f0b-5ad730612682',
  '521',
  'guest_laundry',
  NULL,
  NULL,
  'Hedman',
  '521',
  'collected',
  NULL,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1904b7cf-fa6f-47e6-a903-4e109433d4ed',
  '7761',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Simona',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e10b25da-5a07-4fe2-948d-7a3a0418e1c0',
  '7814',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giih',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '525f28e6-cf9b-445d-8919-83b25bc54d19',
  '7843',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b80bc694-548d-44f9-85bd-83735259ad43',
  '7844',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2603afbb-e6ae-48e8-940b-4b7ec04aa8e4',
  '7845',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd1545539-eaf5-4933-8954-2268874e120d',
  '7846',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Daniele',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4ca1c41a-ba14-4876-99f9-76946619b9ef',
  '7847',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  20.93,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ed0765a7-0a8f-4619-bb19-3bc1fb6543cc',
  '7848',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Emmanuel',
  NULL,
  NULL,
  'collected',
  10.49,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e6ae8e06-77b5-4eca-893d-a18549cf97d3',
  '7850',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0dd667c0-6881-486c-9039-55f3256bba97',
  '7849',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Yg',
  NULL,
  NULL,
  'received',
  13.2,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '73403f52-545e-4821-95ca-ec89f8b03aad',
  '7851',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  17.6,
  '2026-01-11 09:00:00+00',
  '2026-01-11 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd2555f02-9be5-416c-9385-c05ec8a969af',
  '521',
  'guest_laundry',
  NULL,
  NULL,
  'Dan redfeld',
  '521',
  'collected',
  NULL,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6520a462-9032-4859-9ac5-d972acbc3e73',
  '7837',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7d1a5616-8e8c-4e0c-a96d-b75b1506b5cf',
  '7853',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5425f741-aad5-4b4f-8433-ef901f21bc5c',
  '7854',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Alberto cambus',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '85295bb7-9b21-46d8-9217-15c65f68fd96',
  '78',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Paul',
  NULL,
  NULL,
  'received',
  5.98,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ce2c9d30-8caf-4153-ac86-d4038042ea98',
  '7856',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  12.92,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f9179897-526c-4542-aa5f-a7b602077a1a',
  '7858',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8c771f29-cb2e-4cb8-bb3c-1817c0ee2cfe',
  '7859',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'collected',
  5.5,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b3a38e4c-0665-4add-9055-cfc2cc07dcee',
  '7861',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5a849b95-4b70-435d-97bb-4e5513550c93',
  '7863',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Dy',
  NULL,
  NULL,
  'received',
  14.52,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1ed2fc30-1786-4395-8449-b133b83be456',
  '7862',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  24.2,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bef4ffaf-4c81-408a-9f8d-f8331a9f0add',
  '7852',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Valentina',
  NULL,
  NULL,
  'collected',
  13.75,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '884672b3-6779-4173-a462-b2b179bad68b',
  '7864',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  1.98,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '272860b2-03b8-4945-a3de-833fbca8d6c5',
  '7865',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '770656b5-b1c8-45cc-85b3-38b21a55e679',
  '7866',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1d3dcd24-38c3-4ad4-ae0b-a4e9eea77053',
  '7868',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'received',
  3.67,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f4bc525b-6609-434b-abd0-ff8d41bba031',
  '7869',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  20.9,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '82658737-8136-470f-b236-a927c851b6af',
  '7870',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c3f68dfb-3d8a-49e0-9744-530b990e428a',
  '7871',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Nihr',
  NULL,
  NULL,
  'collected',
  10.17,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c57a1a45-3b02-4bdb-92d7-f5049abb505e',
  '7872',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  11.96,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c9e5d618-f4cf-44cc-8884-7d6ed549c182',
  '7875',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '25c2516e-d992-41b1-aece-92cc333c6714',
  '7873',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ftr',
  NULL,
  NULL,
  'received',
  7.92,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '62a2b4c6-997a-4762-929a-309fc6f23061',
  '7874',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Bayelahad',
  NULL,
  NULL,
  'collected',
  7.04,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '34a620fd-d20c-4bbd-a031-e252b426abd8',
  '7878',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Tony',
  NULL,
  NULL,
  'received',
  72.32,
  '2026-01-14 09:00:00+00',
  '2026-01-14 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '008ee3d9-7691-49fd-8a16-bc7815d353e8',
  '7877',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eef12bb2-82c1-4b20-991e-667f52e76b02',
  '7879',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  17.38,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd729a1f6-721d-4e0a-a777-97201d28ac82',
  '7880',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd0ef4358-0dcd-4a32-9ef3-54fb25712f81',
  '7881',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '27fac6ca-cea0-407f-88b8-5b337b4aecc7',
  '7882',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8277a628-2749-4dd4-9fb7-744d769b8e23',
  '7883',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Lucia',
  NULL,
  NULL,
  'received',
  4.95,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c2512381-1db2-4aca-8da5-12b684a261e2',
  '7884',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  17.94,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '34f34676-4bab-48c2-8030-149ba7b65e2a',
  '7885',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f967790e-5d97-4a5b-acca-266eaa280f12',
  '7887',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '21bd48a2-9e0b-42d0-b03d-10f26dbc1440',
  '7888',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4f36ec2c-ba0e-4026-a1ca-c7b94d37c0d5',
  '7889',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '61f1ffa7-da96-4ada-b60e-2a35fc0d32a3',
  '7890',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e4018529-d879-4107-9d22-d82a36d4fb09',
  '7891',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  7.48,
  '2026-01-16 09:00:00+00',
  '2026-01-16 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '41b5e489-3124-4850-b4f3-66483a64c92f',
  '7816',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  6.05,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9b9e029f-61d5-41f0-9b1f-c6dba3909aac',
  '7892',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5e746359-708b-46b6-aa6c-6f742745449b',
  '7893',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9f2974be-d42f-485f-bed6-315545c5a590',
  '7894',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  5.5,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '22dc5515-e738-4a2d-adfe-5abf7ac3a016',
  '7895',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  15.62,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b211720a-bc37-466e-afa9-d112de2d0a11',
  '7896',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  29.04,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '37b6edba-5fd6-4c55-a3ad-9642ef4e9f2c',
  '7897',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  32.5,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '93318d52-ddfb-433e-b8a8-e2deb82cff68',
  '7899',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  19.5,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cdec3e87-1e37-47f5-b621-ed4373b54d4f',
  '7900',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9066c278-b87b-49d4-beb9-45710d441faa',
  '7901',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Kailen',
  NULL,
  NULL,
  'received',
  6.6,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9307e4ee-87f9-4c67-aafb-ec4f6654685b',
  '7903',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9bc804b2-448d-4e35-870b-11ae9f43ccd6',
  '7905',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'received',
  3.67,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a8f58bed-634a-421d-89a4-8606473aca70',
  '7904',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Abi',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0f272cca-0737-4f94-938f-12b5c03f22bb',
  '7906',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e4b08853-e737-48ba-bba3-cc2623560e31',
  '7907',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  1.34,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f1eb4ba3-9f41-4cfd-9870-4e2bcaa264f5',
  '7908',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  26.91,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f8559b53-727b-4efb-bd27-1133f3f555b0',
  '7909',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  14.74,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e44c34a1-dc8a-44bb-a2d6-84bd86307874',
  '7911',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Dina',
  NULL,
  NULL,
  'received',
  22.88,
  '2026-01-17 09:00:00+00',
  '2026-01-17 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bc6c5187-4004-4bcb-bd86-5c787d840b20',
  '7912',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'received',
  4.3,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '886bebcf-552a-42b7-96f7-d7c16d4f865c',
  '7914',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cb38c97f-de4e-47de-a8b5-d7e52670a0ac',
  '7915',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b492540d-8258-40db-93b1-7d0e70b9fcb1',
  '7913',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  26.84,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5a462bf4-d18a-4232-9afd-d9f819f8ed24',
  '7916',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Wania',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '24f4bdfe-143f-4618-93f2-366981e8ab1a',
  '7917',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  5.28,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7ee6a0f1-a947-45ef-a3fa-2e28e18857cb',
  '7918',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e9672670-bac9-4192-8c75-16c88afd25fb',
  '7919',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cf9b0842-01f4-4d95-a284-7245b7139c53',
  '7920',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  32.89,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b5558d15-e61c-4fab-929f-248f520af625',
  '7921',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bd355676-7049-4e12-bbca-5dc08595f954',
  '7922',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  10.34,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '891af782-a045-4f99-97e5-5dea9776e753',
  '7923',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2e388104-b8ec-4ce9-8365-956cde79e282',
  '7924',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Dina',
  NULL,
  NULL,
  'received',
  9.68,
  '2026-01-18 09:00:00+00',
  '2026-01-18 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cac60ce1-baf4-42b8-81b5-185f5c2bd0c2',
  '7925',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Dou',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c7bda7da-08ae-47fe-ac0b-7701c57655c8',
  '7928',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c7331ba8-7972-4065-acb2-f73563e37717',
  '7927',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '32bf9265-26bb-40e6-baeb-ec8a555a8f38',
  '7902',
  'uniform',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '76440663-d981-48aa-be2c-e586c9d66951',
  '7929',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'received',
  5.15,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '00d4653f-4269-4ff6-b1ef-702c4c2d2e5a',
  '7930',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '449c92bf-40d5-4f2e-aeb2-f8a78f0301d4',
  '7931',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  32.89,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'af82f79d-ead9-4849-950d-3848ecb32ab2',
  '7932',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd0b248db-4dba-424a-93e6-1cda5360c70f',
  '7933',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'received',
  6.99,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2b65f36a-1250-43f2-afe8-e50636c21107',
  '7934',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Will McNess',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8542de6e-b503-44fa-8dd0-fea042c10df6',
  '7935',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '13785446-e432-4c8d-8d4c-95d302d524b1',
  '7936',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  16.72,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f8f48095-5d1c-402d-9bf7-87622d8c4ee6',
  '7937',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  16.94,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dfa999fc-12e2-48e5-ba3d-85a2544b98d9',
  '7938',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-19 09:00:00+00',
  '2026-01-19 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '15d93eed-7acc-4c8a-981d-cee5d3016525',
  '7939',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  4.4,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7eb82445-2ee6-4588-bd9f-fa405e6251d0',
  '521',
  'guest_laundry',
  NULL,
  NULL,
  'Hedman',
  '521',
  'collected',
  NULL,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '90d59488-4964-4fe5-b57a-b6da6c0ebcb7',
  '7940',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '428b1eb6-abd2-4743-941a-e73005e30e13',
  '791',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Simona',
  NULL,
  NULL,
  'received',
  2.2,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c989a9c1-7c81-41e4-b27c-8f46d00b7cf8',
  '7942',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd3ac0cb4-5896-4dd8-82a9-88757c7c3452',
  '7943',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'received',
  6.96,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cc33b37e-59cd-4812-b554-e8fc0b589268',
  '7944',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'received',
  7.7,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0295d7d9-110d-4ca5-b8b9-30a0c1911512',
  '7945',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  23.92,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '43e6d94c-2c71-4f4d-8d32-2e0057a79429',
  '7946',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  8.75,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'da6dd082-8cee-4292-8cf7-b99bb84eeac6',
  '7947',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'de232720-6b96-4808-8a70-388ca6c8a178',
  '7948',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bead61eb-acf4-44f8-b4f9-e42e113551dc',
  '7949',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  30.8,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bdb7d9bc-d639-43ea-8d26-3ba5ef01202c',
  '7950',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  8.36,
  '2026-01-20 09:00:00+00',
  '2026-01-20 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2849f82e-39ad-4246-8ac2-60a2fa280035',
  '7951',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Emma',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7fb317e7-458a-4bdb-9892-d026097321a0',
  '7952',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5186fa2e-0306-4b27-8b93-89676fec5536',
  '7953',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '838e95a0-af2b-4335-9308-3b00b33fc31f',
  '7954',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  24.64,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7ff6d31e-4d4b-4411-afd2-e2fd78f3f8b7',
  '7955',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Ldn Lions',
  NULL,
  NULL,
  'received',
  16.94,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7cf53e98-eacd-4b5d-b05f-8825094d96d1',
  '7956',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  20.93,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a6c9455f-025a-42b9-a9d7-34dc17525e8d',
  '7957',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'received',
  7.62,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '48771923-0b19-4dfe-ad35-d7f475354081',
  '7960',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Kye',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '26217fa4-a862-4087-856a-6da74ecc2ca6',
  '7958',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  8.14,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a7dc9333-4360-4cea-a647-92758a3956c8',
  '7959',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Sam',
  NULL,
  NULL,
  'received',
  11.0,
  '2026-01-21 09:00:00+00',
  '2026-01-21 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f8868ee5-fdab-4eba-a808-c016e93c4176',
  '7962',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LFT'),
  'Claire oki',
  NULL,
  NULL,
  'collected',
  5.5,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e9066e9f-fbc8-410f-9b71-e51323d58f60',
  '7963',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  23.1,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8fa53821-4a70-4e66-98ab-e611f954a893',
  '7964',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  5.08,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '26b06005-e7de-4c85-96f5-0abfeb769d64',
  '7965',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f0548853-5b0a-46b0-9bf2-633fcb6465c6',
  '7966',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  29.9,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '96b90d7d-fed7-45ae-9066-666fb719a651',
  '7967',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '635df0b1-220c-446a-ac33-5db11ffdd748',
  '7968',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'received',
  7.41,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '78be4c62-f475-4119-9969-ae38cd87fb8d',
  '7969',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  11.44,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2c680076-6bd3-4b67-9ad9-9ec1ae3faaf8',
  '7970',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'received',
  2.33,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5d0631e1-acda-4b2a-954e-944bb1ce0b04',
  '7971',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  12.54,
  '2026-01-22 09:00:00+00',
  '2026-01-22 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1bfffd22-4ec3-441f-95a0-bd723ae814e8',
  '7973',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'received',
  5.2,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e18dd17a-0842-4e1c-b214-7583b243bcc0',
  '7974',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '19e62d62-a67f-4cba-9585-57096ddf9867',
  '7975',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Chris',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8544c622-d60c-44da-8a15-5313f7bc32c4',
  '7976',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  20.24,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7586d0b2-24db-4671-9e58-4d8d2901be6d',
  '7977',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '09962f0f-c05c-4816-850d-4675915bb68f',
  '7978',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  8.36,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '701697b0-3230-4319-ad35-24f24a426695',
  '7979',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  1.1,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd45ae464-b642-4569-8ba0-ff7b967f6efa',
  '7980',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7f91a1e7-9f43-4164-ad50-2c5fa4ea3b31',
  '7981',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  50.83,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '74adcdb3-1066-4320-b1b6-fc9be3481a68',
  '7982',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd679ec25-9d72-42b5-849c-232919d93b37',
  '7985',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '22cfe02a-689a-4844-bfa9-eee02ed15c30',
  '7983',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'JACK',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8c48ee2a-d078-468f-8a01-9bd3818535f4',
  '7984',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Lewis',
  NULL,
  NULL,
  'received',
  23.76,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3ceea1d6-837e-47e2-a13b-02b484a1c082',
  '7986',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '91586a95-5145-4261-92ad-5bd855d1ca29',
  '7987',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Tony',
  NULL,
  NULL,
  'collected',
  10.08,
  '2026-01-23 09:00:00+00',
  '2026-01-23 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c1d96b2c-6c0f-4f47-ab79-8c0723abbfe7',
  '428',
  'guest_laundry',
  NULL,
  NULL,
  'Nama',
  '428',
  'collected',
  NULL,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6c85411b-4fa8-4683-a027-067b403b227f',
  '7988',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'West ham',
  NULL,
  NULL,
  'received',
  20.46,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e2293ad7-a86d-45ed-951e-20386b46ddde',
  '7989',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'EVENTS Staff',
  NULL,
  NULL,
  'received',
  32.5,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3cc48915-1442-451a-8f24-25c7d3d76daa',
  '7990',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  16.25,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cbc63a08-2f4b-4b12-af86-5e94fe8ed649',
  '7991',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'EVT'),
  'Shahwaiz',
  NULL,
  NULL,
  'received',
  16.25,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1055ee74-3e06-4b32-9a6a-059bb99a8e9c',
  '7992',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bd8cf061-476a-4ca0-b82e-7618a874b153',
  '7993',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  68.42,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eb067871-5236-4097-831e-372b1849c1b1',
  '79942',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Val',
  NULL,
  NULL,
  'received',
  4.95,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f4672b2a-12d0-4dba-b0bd-cacef36a0192',
  '7996',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b87eff9a-7e25-4a11-9b77-22b15ca6583b',
  '7997',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '334a3d43-4c1d-4437-afb5-645863ae92ff',
  '7998',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5860763b-7fc0-483a-952a-cc6b6bb5c489',
  '8000',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Kevin Hoffmann',
  NULL,
  NULL,
  'collected',
  7.7,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'fce3d54a-6992-4b9c-9872-3f20d16f69e6',
  '8001',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  7.41,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '618f6c98-147b-4eb2-affc-7424b13886b0',
  '8002',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina l',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '09a3a6f8-8525-4924-9c6a-2e472a3dee9a',
  '8005',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  3.67,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2947d836-4b8d-4dac-8544-53fa7c3027f6',
  '8003',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  8.97,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '769a4583-3d7a-413f-8843-42e97fd4041a',
  '8004',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  NULL,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ac3b86c3-6599-44c7-8327-59f55c83d861',
  '8006',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  6.63,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cf5a86ca-b089-47d8-ba1f-0822b7787c33',
  '8007',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  17.16,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '64edfc5f-61cb-49da-9abc-f2ed754d9542',
  '8008',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Valentine',
  NULL,
  NULL,
  'collected',
  0.99,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cf8aa9dd-6450-483e-840c-d5c281d5d4b9',
  '8009',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  12.32,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f548e063-3f43-4d67-b572-1233d73d3187',
  '8011',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Nihal',
  NULL,
  NULL,
  'collected',
  2.84,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0cc51c16-e86c-46a3-b2ab-5ceaed55c46c',
  '8012',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  21.56,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a1b1a576-de18-4a52-95fe-1b5486b36220',
  '8013',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3d68be3a-0263-43bc-a763-4ad300309573',
  '8014',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '87ce60bb-4500-4a3f-aa46-eadde404ccdb',
  '8015',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Wania',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7366e1de-d1e8-473c-a087-f60596765ed4',
  '8016',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '702d1640-ca55-49f5-b3e1-e505aa35d919',
  '8017',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '502cba1c-7740-4473-9a82-cf5a7166969e',
  '8018',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '77075a93-333e-4996-a3b3-5abf201f860e',
  '8019',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5353d11a-a8d3-4e68-8ed7-1eb4b80cabbd',
  '8021',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Adomas',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f6430bb3-cd21-44c8-b251-c7c3ab685239',
  '8022',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f3ddc398-2aad-4c46-9bb2-70b6cd152672',
  '8023',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  9.46,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a8d0141e-0272-44f0-92ba-144f32d4dd21',
  '8024',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  13.42,
  '2026-01-24 09:00:00+00',
  '2026-01-24 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c29c9ac1-ca8b-4573-ac5a-8e3ca084097c',
  '8026',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  5.5,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0b440d63-3261-428f-a12e-7cc0f47b7d40',
  '8027',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Jim',
  NULL,
  NULL,
  'collected',
  6.6,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '299c0040-e749-48a7-8d7b-9f9a6708a805',
  '8028',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Amber',
  NULL,
  NULL,
  'received',
  6.99,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bd36c0d4-a27e-4742-a043-e7c23a80e961',
  '8029',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  12.98,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '09eaf51d-059c-46d9-8664-53cf26b68a29',
  '8030',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '43684422-9435-4e56-bc5a-b3f124a84178',
  '8031',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd1f742ab-4162-47e5-ac68-cf75b0e0cb68',
  '8032',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c8ecb035-6dce-43d2-ae57-22210b5bb0ab',
  '8033',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Madalina',
  NULL,
  NULL,
  'collected',
  41.86,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6f3872c6-b6d7-4769-ac33-3c2b8a452721',
  '8034',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'eb6330f3-c295-433c-af41-3af74b227ea5',
  '8035',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  12.1,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a7194e1b-d27c-4a20-896d-e806e0caa44a',
  '8036',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6841d8d7-584f-44ed-aa1f-61c3118f2451',
  '8037',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Shahwaiz',
  NULL,
  NULL,
  'collected',
  12.32,
  '2026-01-26 09:00:00+00',
  '2026-01-26 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1c9c4a47-a050-4e99-be07-1be6d20deddf',
  '8038',
  'uniform',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Telmo',
  NULL,
  NULL,
  'collected',
  5.94,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '153fe917-00d1-41dd-aa34-90db8f059ac7',
  '8039',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Nawal',
  NULL,
  NULL,
  'received',
  14.96,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1adc8691-a534-404a-8ff0-d910afef4bdb',
  '8040',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ab87c471-dc23-4c4b-a1c4-3b6934a76d16',
  '7972',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Dina',
  NULL,
  NULL,
  'collected',
  2.75,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7254b071-1aad-4143-9971-ec80e7523670',
  '8041',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dba171b6-0684-4503-b74e-212b6afce43d',
  '8042',
  'uniform',
  (SELECT id FROM departments WHERE code = 'RSV'),
  'Kevin Hoffmann',
  NULL,
  NULL,
  'collected',
  4.95,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '195107fa-8a0a-4485-a9bc-65ee5aacc233',
  '8044',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  29.9,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bb2f46cf-bbb5-4372-8cde-08e8382a2072',
  '8045',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  2.99,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '786df39a-d0c8-4eb4-a835-fefdd4157c34',
  '8046',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SMK'),
  'Jithin',
  NULL,
  NULL,
  'collected',
  8.43,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f731c167-8f79-4043-9f0c-6183ef808fb1',
  '8048',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '4d3af652-2bad-4588-b55b-6b9b571adbb2',
  '8049',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  7.26,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1f54f5d7-f192-4da3-8677-d850f742ca8d',
  '8047',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'received',
  12.98,
  '2026-01-27 09:00:00+00',
  '2026-01-27 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '828aad05-4b88-4025-8e70-5e37abb5634b',
  '8051',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  4.09,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '983014f0-665c-4481-bb17-6a06e59f3b82',
  '428',
  'guest_laundry',
  NULL,
  NULL,
  'Alexander',
  '428',
  'received',
  NULL,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '0a101622-e2b9-4bfb-8268-5f3ec60d302c',
  '8052',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f2bab28a-37e5-489c-be14-eb549e0ec471',
  '8053',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6531c406-8ea8-41dc-af91-b8fa450224ac',
  '8054',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'KE 20',
  NULL,
  NULL,
  'received',
  17.6,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9838c77b-b1d2-4840-8aec-d437066359e4',
  '8055',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Kamrul alam',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7b3ac88c-8d58-41a6-8fe4-1102b817765e',
  '8056',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  17.94,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '57b7ad77-5b86-4f57-a4ea-8e5b1991ce12',
  '8057',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'received',
  4.66,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b9b7e45d-5589-4b9c-8bc1-a57158cc26ca',
  '8058',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Adam',
  NULL,
  NULL,
  'collected',
  5.08,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '968fb31e-a131-4400-962f-862314f76468',
  '8059',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  8.8,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'e44a531f-7349-48ef-837a-f2dbf597efbd',
  '8060',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Laura',
  NULL,
  NULL,
  'received',
  10.12,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '176f31e2-a44c-487c-8fc4-b81af2b222be',
  '8061',
  'uniform',
  (SELECT id FROM departments WHERE code = 'GMT'),
  'Ash',
  NULL,
  NULL,
  'collected',
  6.05,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '15074563-fd7d-4547-9ae7-7b5f806fc646',
  '8063',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '560f7500-4739-48a3-bdf3-0ae6feba74cd',
  '8062',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Michelle janeiro',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '02674c3d-756b-422c-8944-bc93e34170ba',
  '8064',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'd52ff063-3f49-47e7-adcc-62f6df6640e7',
  '8065',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  23.92,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c6187d2e-a5a9-429e-b334-32b9e76e74de',
  '8066',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  14.3,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '004d68d8-ddf5-496b-8878-65091112aeef',
  '8067',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz l',
  NULL,
  NULL,
  'received',
  9.24,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ebe93862-3b8b-43a4-a549-790e014fcb1c',
  '8068',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5e4c7d84-46c2-4216-81d0-1943c60e6434',
  '8070',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kye',
  NULL,
  NULL,
  'collected',
  9.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2f73df4f-9fbc-4cec-bd32-00991fa4866a',
  '8069',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  5.28,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5fa5babe-9738-40fa-ad27-3b7837d7bd4b',
  '8071',
  'uniform',
  (SELECT id FROM departments WHERE code = 'SEC'),
  'Massamba',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'bde843eb-4d54-4c22-8517-02e92271e83b',
  '3',
  'uniform',
  (SELECT id FROM departments WHERE code = 'MNT'),
  'Dou',
  NULL,
  NULL,
  'received',
  3.85,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '22de7f8e-e4d6-404d-9b88-b07a99706d94',
  '8073',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  14.96,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '482a04c7-e6dd-486a-b620-b4a7ef05c588',
  '8050',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Carlos',
  NULL,
  NULL,
  'received',
  1.1,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '93f7ea26-cd74-459c-af0d-1df6e27bb154',
  '8074',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'received',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '29650e0a-15d9-48f1-a261-edfb8529ce29',
  '8075',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'received',
  4.62,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7d4d18da-da2a-4043-a7f6-8927de526e70',
  '8076',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jenny',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9f88f4fe-ecec-4c91-add0-563d9bf57727',
  '8077',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  14.95,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '7ca4faf9-70df-4594-aff3-45ac149166ad',
  '603',
  'guest_laundry',
  NULL,
  NULL,
  'Lisa',
  '603',
  'received',
  NULL,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '014966d1-4c46-4181-912f-14e84898f949',
  '8078',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Alfie',
  NULL,
  NULL,
  'collected',
  4.66,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '6f82d311-4293-4dbc-853b-602aceb4b14d',
  '8079',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Cristina',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '450dd920-1fe3-4ab4-87e7-7d31fea860fe',
  '8080',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '1a432d36-12a0-4654-bdaa-dd496c343eb6',
  '8081',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Leila',
  NULL,
  NULL,
  'collected',
  3.85,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'c4be13d2-61e8-459b-948d-086489dc3cc9',
  '8082',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  10.12,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '885c484e-2ac9-46e5-abde-cdf19ce60460',
  '8083',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingrid',
  NULL,
  NULL,
  'received',
  9.46,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'b6459b54-137a-4899-86f1-890156b00385',
  '8084',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'received',
  17.82,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '3beae2d1-73b1-4af2-b1ac-5346f916c3b8',
  '8085',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Yacine',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '742eaf82-bd09-4537-a5b3-315e15d90974',
  '8086',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Maria',
  NULL,
  NULL,
  'collected',
  7.62,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ce65eff6-0a49-4927-8394-3532fb176870',
  '8087',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Ahmed',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cfd8d50a-c5c3-4572-a30c-7ed652639481',
  '8088',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Kema',
  NULL,
  NULL,
  'collected',
  3.81,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'f3250bfa-567e-4f16-b612-28145b2b0427',
  '8089',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Giuseppe',
  NULL,
  NULL,
  'collected',
  3.32,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '2a7120a1-67e0-4856-9173-932a1de1c32b',
  '8090',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KIT'),
  'Jack',
  NULL,
  NULL,
  'collected',
  2.33,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'dd8cbb2f-eeb7-46ad-ac70-05b9a554a88d',
  '8091',
  'hsk_linen',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Ouadii',
  NULL,
  NULL,
  'received',
  35.88,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '5bedc885-349a-479b-9f75-afc797e3f092',
  '8092',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Ingid',
  NULL,
  NULL,
  'received',
  36.08,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '9a358ade-4bc9-4a2b-91d6-c2a7c5d879ff',
  '8093',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Ramiz',
  NULL,
  NULL,
  'received',
  26.4,
  '2026-01-28 09:00:00+00',
  '2026-01-28 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cecf2b96-cb2d-4bf2-b9c4-58c5209867e6',
  '530',
  'guest_laundry',
  NULL,
  NULL,
  'Angelica',
  '530',
  'received',
  NULL,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'a9f383a9-0bef-4fa3-93e0-6a6097f6ab38',
  '8094',
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
  'a5ade450-16ce-4918-ab11-10756e3a5c91',
  '8095',
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
  '7c8ae02a-833e-4fef-aef8-74595470052a',
  '8096',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Nawal',
  NULL,
  NULL,
  'collected',
  46.2,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'ce059717-3302-41a1-acfc-24a9a496d8d6',
  '8097',
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
  '2ecf25df-12dd-4380-ae88-c35efaf43fe3',
  '8098',
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
  'a6067397-8260-46d1-906d-04ad0754b61e',
  '8099',
  'fnb_linen',
  (SELECT id FROM departments WHERE code = 'LNG'),
  'Mihai',
  NULL,
  NULL,
  'collected',
  4.84,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  '8d8849a9-060d-4f3f-9193-90dc34e4d8eb',
  '8100',
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
  '080a97e5-629e-4c97-838f-f1f95650faf7',
  '8105',
  'uniform',
  (SELECT id FROM departments WHERE code = 'KEF'),
  'Bledar',
  NULL,
  NULL,
  'collected',
  6.99,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

INSERT INTO orders (id, docket_number, order_type, department_id, staff_name, guest_name, room_number, status, total_price, created_at, updated_at)
VALUES (
  'cfb99149-632b-4871-b58a-c2eb93c5bdaa',
  '8101',
  'uniform',
  (SELECT id FROM departments WHERE code = 'HSK'),
  'Zana',
  NULL,
  NULL,
  'collected',
  2.2,
  '2026-02-01 09:00:00+00',
  '2026-02-01 09:00:00+00'
);

COMMIT;