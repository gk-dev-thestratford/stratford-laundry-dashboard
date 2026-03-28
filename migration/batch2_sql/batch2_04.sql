BEGIN;

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3742bd2b-25a0-44fb-83c7-78aca912924c',
  '81651fc9-a02e-4636-9cab-0b045863f38f',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  66,
  66,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f4b9a9fd-9abd-4aa3-899a-5feafec00f5a',
  '3348c796-2e0a-4a3e-855e-f0a1723a828f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c50225ac-405c-4c08-91e8-dffb20390a51',
  '3348c796-2e0a-4a3e-855e-f0a1723a828f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3711f280-bf9f-4c97-8911-8c0812bf8d0e',
  'e7a44deb-8072-4702-8daf-2e02e4c667a8',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  38,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7a4c266c-c33a-4d90-be57-f8a5439ec731',
  '64955dc5-228f-4361-ba88-ff64614a4040',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '34a3115c-6c2c-40e2-8f91-e1dea52b1673',
  '64955dc5-228f-4361-ba88-ff64614a4040',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '579415ea-a138-4f4e-8cba-838eebdeacd6',
  '64955dc5-228f-4361-ba88-ff64614a4040',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '24bb6ba4-c40f-422f-87f6-301c4c0c0982',
  '58976a54-026c-4541-914a-c1a07bd5d56d',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '96aaf3b4-ff59-46cd-8992-3ad3b32cb887',
  '74ae5814-fe32-44a6-99d2-2529c7df4651',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cb30d0dc-7ec2-4cc7-b0d9-76c26f93732c',
  'c63e607e-6c21-4bec-8d67-ca33c8602cc3',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b613ae28-66c1-4101-9430-c4a2571686a2',
  'bbadb26a-3d0f-41ef-98e8-be869bade9c4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1e5cca9a-f63f-4046-9274-deaac75ad37f',
  '6a3f01e9-7839-4fed-991e-3b095049cd65',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '83f0fbc4-eef9-415d-a55c-dc19d123aa2f',
  '43384448-8d59-4734-b8da-8fecff290bfb',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bc4301e6-f468-456e-af9d-e115d88eb548',
  '70fde31b-a9f6-4c65-b26f-50e0bdc234e1',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '95b9e6be-034d-4424-bde9-d96e6b498f99',
  '63790c6f-ac56-4fe3-a367-88ab4ec2a8ef',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0133b3a6-e11d-458c-88aa-227dff3ad7c4',
  '150f1155-d635-4212-8cf8-6ef38b3a3c38',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  36,
  36,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd8a84457-b536-46c2-9de4-38fbba8c8769',
  'b32bc5d9-f2aa-40b5-82f5-6d6fbeea9d1b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '09705bb8-ed5d-439f-bb28-55c8d918bf65',
  'b32bc5d9-f2aa-40b5-82f5-6d6fbeea9d1b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f99c1797-9886-4596-baeb-88b47e9b4b46',
  'b32bc5d9-f2aa-40b5-82f5-6d6fbeea9d1b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2500f7be-92f0-4215-9832-d1b8a0502eb4',
  '3a095854-9533-4bff-bc91-fe9575cdbdcd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0152a29e-70c7-47c9-b43a-9e3ffb7d4546',
  '3a095854-9533-4bff-bc91-fe9575cdbdcd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6d0befd3-abe8-4323-8070-806213ea85a1',
  '3a095854-9533-4bff-bc91-fe9575cdbdcd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd301d3ec-f4d3-4c76-a6c7-2353067ab7f7',
  'd9d04a77-cbac-4abd-b64e-250f77a1a97d',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '32264831-66a5-4978-92fc-55fd5ef58ce3',
  '9cc78cbb-f72d-42f1-818e-898d0e74a608',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f3fdfdb7-36da-4656-bcb6-d5e0ad50e6ae',
  '3912741f-7ab7-44be-be19-1b828f10bfd4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '293ca0da-cb61-462e-a503-dc98f312784b',
  '3912741f-7ab7-44be-be19-1b828f10bfd4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4e411d03-fa8c-45f3-9570-dbe08e3c63c5',
  '3912741f-7ab7-44be-be19-1b828f10bfd4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0bea118e-af1e-4edf-a942-b055e8175393',
  'f17f2022-98e4-4392-83cb-a0c375fbe731',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '12eb48a0-1824-410d-ad2f-c6d0fdd217ce',
  'd53e4242-18e6-4b7d-b18a-92c2aa664ba5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4d4dce14-4658-400e-9751-3cc6a9e4163b',
  'd53e4242-18e6-4b7d-b18a-92c2aa664ba5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6dfb0c7a-1923-44c2-ac10-d930609a8b86',
  '72e0ea06-d5a6-45b7-911d-3375d3b93e87',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  48,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e429d6a4-c64e-45e2-8c8e-57a3bd938467',
  '8e8b85c9-ee66-4f35-a1f6-f49c1c4db332',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  6,
  6,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd93440d5-3e9b-4462-81f5-1a6a7df08b6b',
  'e24c6bd5-67d5-43e7-8236-31bb36514935',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  59,
  59,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '77a03fb0-277c-4e0f-9e82-941de41485ab',
  'ffd6559a-74fc-40e8-baf2-d698dc320656',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f415bee-d1e6-4231-948b-8c63f9eb207f',
  'ffd6559a-74fc-40e8-baf2-d698dc320656',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8b7bb410-476c-4e69-9220-714802b93e1b',
  '401758ce-01c9-49ed-ab0c-023d66384174',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  4,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bdb8f371-e71c-4580-b26f-fbe1ac5d2f91',
  '401758ce-01c9-49ed-ab0c-023d66384174',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dd561a7b-cd1a-4d60-8950-a8f3ea6a7b94',
  '401758ce-01c9-49ed-ab0c-023d66384174',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  1,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5991064b-c558-4e9a-8b8b-b68394fb9cf5',
  'c2291ed9-1e5e-46c7-8fcb-3362e759d990',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4cabfb6d-3046-49ca-b56d-7de4ac36c522',
  'b6169b1f-6d45-4943-af75-ca0b7e915c24',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  78,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5e76dd37-ccf6-4854-82c3-88ca2f81d5e7',
  '70b28c62-6e38-40ae-afc8-b218d269b15a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2edd692e-7384-4580-833a-326277dfad2c',
  '70b28c62-6e38-40ae-afc8-b218d269b15a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5fff61fd-1aa8-4f75-82a2-2c4ab7ae5086',
  '70b28c62-6e38-40ae-afc8-b218d269b15a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5fc58f41-fae8-4467-9b72-353ba7e0c26a',
  '87863fb5-c7af-47cd-98a7-6a20d260004b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dae4a541-4f05-4db9-8f6b-5225512f00be',
  '87863fb5-c7af-47cd-98a7-6a20d260004b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '875e07c5-0286-4930-b831-0d66d0a34b48',
  'f8121870-e694-49fd-9cfa-bab8f835cfe0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '29c47407-5b2b-49c2-848a-2e205c739d2e',
  'f8121870-e694-49fd-9cfa-bab8f835cfe0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c9097039-ee0e-4084-a62c-7fa0441aae12',
  '16d411fc-cee4-4545-99a6-d3e88809092e',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  13,
  13,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7c53d9e9-66e8-49c0-b8e0-72c3544d6b24',
  'a76534f8-f3d0-40f7-9566-6ff8c0c6f03f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b27120ff-510b-4c31-95f5-e110f4f53fff',
  'a76534f8-f3d0-40f7-9566-6ff8c0c6f03f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6b96b445-7e49-4823-bddf-adbf6f097e2b',
  'c0557db8-c74a-4383-ae20-9d5b81b4fdd4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  53,
  53,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f5845226-91d1-4c5f-bc82-8235856c5775',
  'a129ba98-c0a0-406c-bafd-9161be9bd93d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6579b23e-0a2a-4207-92ba-4ffb94e1c962',
  'a129ba98-c0a0-406c-bafd-9161be9bd93d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'df262708-5e09-4ade-aebd-46197b17f76b',
  'f04787c2-8cca-43be-903b-f9fe8a08b771',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  56,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4ce96a41-f8a5-4268-92ef-45be01c10abd',
  '91602c90-8dc3-4f9a-a594-7d72e4c7d7c0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '54baa23d-2aef-4e25-a67e-7a4a84720008',
  '2a9a8c96-e04e-41d2-a814-37e21437422e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8546c427-43c4-4de1-a07a-1ab7e70de7c6',
  '2a9a8c96-e04e-41d2-a814-37e21437422e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e33537c1-d074-4dcf-a2d4-d00ba36cbf34',
  '2a9a8c96-e04e-41d2-a814-37e21437422e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c2466dd3-798e-471c-8c04-8cb9b07a2b5f',
  '061e1391-c236-4492-98cd-0244e787ec2a',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4f3ed5fa-0283-40bb-9a1d-6ecbce900ecf',
  'a4572d78-7719-4bf7-bb7f-b41b4d06fd09',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6b777ad9-4b04-4f61-9e1b-b96f48c3dc33',
  'c0a349b1-ee95-4bd9-9f2a-463b89119844',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dd902a17-4398-43da-9528-a3ff3ced6560',
  'f9b07be4-e325-4c6d-8380-75da1f661aa4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7af99d54-3801-45db-87ac-295bb654dff5',
  'f9b07be4-e325-4c6d-8380-75da1f661aa4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4d79ec54-0aed-4999-b646-c3b9c005cdfd',
  'f9b07be4-e325-4c6d-8380-75da1f661aa4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b0d8779f-f4b0-47ee-87d7-27c6df12f256',
  'c59c8890-fcf7-455a-8cd3-25683adc2d30',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e86ff98a-1bde-4e9d-8b82-90c2a363513d',
  'c59c8890-fcf7-455a-8cd3-25683adc2d30',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a8c6da0f-e292-49c3-a341-5bbc3650ba5d',
  'c59c8890-fcf7-455a-8cd3-25683adc2d30',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '372ea167-4087-41f1-9c82-f9f6d22956d8',
  '4d0251a7-2b07-4990-b06f-deccb8895911',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '410345cb-1722-49f5-a856-094619181c32',
  'ce5fe11b-362c-43d4-a995-c5b5d2ae073a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6196d0aa-95b0-41cf-a269-f69eace476c8',
  'ce5fe11b-362c-43d4-a995-c5b5d2ae073a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb9822e7-ec55-47d3-85b3-52463d2610bd',
  'eb9def1e-2dfb-4729-b9c1-2e403dfbaadb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1b6e4ca4-d115-4c5c-bf2b-7942fb1fee8c',
  'eb9def1e-2dfb-4729-b9c1-2e403dfbaadb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2b85a8fc-3445-40be-bfd4-d5ffcdddbb58',
  '3eac8e20-412c-491e-8c9b-2b1abfc346a0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  3,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8ab65e57-c74b-45dd-ae94-901e393497ef',
  '1432f094-177d-4158-ab83-28c9da717954',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  10,
  10,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1acbe5a8-d4b6-48bd-b898-04866a1e1e32',
  'e359c015-c0da-4d8e-865f-7bf39b1db8b1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1a02fec8-7814-46dd-b232-03d2f0eb9fdc',
  'e359c015-c0da-4d8e-865f-7bf39b1db8b1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b922d914-a98c-457f-8812-83f39b6c824c',
  'cc567b5c-f922-4e45-8468-bbc3cb5eb153',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  73,
  73,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3d62b6f3-c572-4ae7-ba03-6f98ff94079a',
  '5fb952ab-a1df-4621-9675-5cf4d8bff499',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  118,
  118,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2d20b7a7-477b-4bd4-9c9f-4e09458bc0b1',
  '66049a4e-5d24-443e-abb0-a75ebea1cf3a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f9a8bda4-2558-4207-a4d1-20c1d8d6ecc9',
  '66049a4e-5d24-443e-abb0-a75ebea1cf3a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '802f02cb-6117-4bb3-9496-f5c0ec19a6a0',
  '66049a4e-5d24-443e-abb0-a75ebea1cf3a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1ec68f42-e02c-49f8-b61e-0116a54ce263',
  '3c7155e1-889a-44b9-a4dc-d646eeb6916c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0f681f6c-1d0a-43b7-82ad-742f4d7118df',
  '3c7155e1-889a-44b9-a4dc-d646eeb6916c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  3,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd321f082-b09b-414f-934e-656a6cd8c1ef',
  '3c7155e1-889a-44b9-a4dc-d646eeb6916c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c3da0b2d-2620-4fdd-b3f7-e7696657f644',
  '9597c3d4-550b-4eca-b622-be570eaba4be',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '787ac848-383b-4e07-b7c0-40a20bb89c52',
  'ec0d7acc-5b6c-4bfb-b84c-83bc96e57fcf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ab941d4b-e3e7-4736-a0b9-6afa99da652a',
  'ec0d7acc-5b6c-4bfb-b84c-83bc96e57fcf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b81c24dd-bfa4-431b-bfd4-ce9826dc3f0e',
  'ec0d7acc-5b6c-4bfb-b84c-83bc96e57fcf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8c05b4e9-61b4-4153-836b-05c90dfa84a0',
  'a912bf3d-fa67-4049-9f88-8265417f3609',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  36,
  36,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '172da68d-9b2e-4a56-91aa-290537ad3e98',
  '952841fa-0dea-47e7-a7d2-0817ec099c4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c4406999-379d-4082-8df6-ad28cfe6a4e6',
  '952841fa-0dea-47e7-a7d2-0817ec099c4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  2,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '62fafdc7-f83f-4935-bf1c-f442f48cfbc6',
  '952841fa-0dea-47e7-a7d2-0817ec099c4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6244d8bd-395d-4c77-9966-3faec62dda91',
  'a9dd1364-26b5-4041-8149-35fb52d828ff',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f4e8ca7-82e9-4e69-94c3-ad9638a4543e',
  'cbba24e8-f93a-4ca7-8a38-81cacd1aa740',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  4,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7689da28-82eb-4953-8e8f-827fce479696',
  'cbba24e8-f93a-4ca7-8a38-81cacd1aa740',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ce82bf92-7232-4158-9af2-eb8ec0016a78',
  '26bb7da9-01c4-49ee-9fe6-bd1e34819124',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '55af9297-d36f-4cab-9486-f1866e33f8db',
  'beb1a826-cf22-4cb8-856d-ec33a164aa70',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '919a2f95-adc9-41e6-9744-eb1b5653b800',
  'beb1a826-cf22-4cb8-856d-ec33a164aa70',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd7be7097-ac82-4a8d-83ae-6c7c17ffa52f',
  '42357930-5687-4527-b3bf-604f65ff5a8e',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  13,
  13,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'af6643cd-4369-46c2-b686-c4e6043d6778',
  'a6ce9494-a749-4a54-8697-204006fc07f0',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  37,
  37,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9c06dae8-cbf6-41d1-a2ee-e7283dfac6e1',
  'e9fe9bd5-65e8-445d-94e0-f19bacb21b54',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  173,
  173,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '612bab73-7c6d-4b04-90e3-1c66c5cd8fdf',
  'e921b62c-5064-48f2-8bac-53d1efef6550',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  1,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd3dd0228-0767-4be2-bcf6-fda13f3fa50d',
  'e921b62c-5064-48f2-8bac-53d1efef6550',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd8a76e2f-fc32-46a5-8e3d-19d3c487c139',
  '4f9e0d27-304d-4c52-a9fe-0ac37f98c0fc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '889aa214-faeb-47c0-9ada-d2306f7eeac4',
  '4f9e0d27-304d-4c52-a9fe-0ac37f98c0fc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '693a1d5e-148c-4bd0-a0cb-5d615c4cbe9d',
  '4f9e0d27-304d-4c52-a9fe-0ac37f98c0fc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fc49d6a3-b510-4441-920c-72518bc9732e',
  'b3241f33-e79c-4bea-9524-22e6b0cb4aae',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  128,
  128,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e6db2d94-106c-4122-8b41-4b03ae63cfda',
  '96d2375b-3293-43d9-8fd1-81bee25d8dc5',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  25,
  25,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '239c5211-f527-4b4e-bad9-ba17dd74cd27',
  '945918da-664d-4b61-866d-7d3eea825ce0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '06b22259-33ea-40e1-9998-95e27a545d8f',
  '3612474c-257d-41ec-92b0-a9d39d3956db',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bdfba3ba-f224-46c2-99bb-f874897ee67e',
  '3612474c-257d-41ec-92b0-a9d39d3956db',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '824a1763-7d56-47eb-bad9-40ffd1732daf',
  '57145a6e-4580-41ce-8089-d7d2b5422ddc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2569ecc4-b1e2-4eef-8f04-ec90f6e0092b',
  '57145a6e-4580-41ce-8089-d7d2b5422ddc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4a4dc3d7-b3f7-438c-9ae7-aacf54a682f0',
  'dbed7738-e587-4260-9531-555e2ee46897',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5e85fdcd-3a05-4d53-a946-81749beb28d2',
  'dbed7738-e587-4260-9531-555e2ee46897',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5b108e0c-fef4-4afa-a9c9-cbcda745f61f',
  'b68694f6-668c-4151-91a1-d68ec350cc96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8bf7ab17-7604-453d-95d5-67d803c4c329',
  'b68694f6-668c-4151-91a1-d68ec350cc96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7e161ed7-101b-44af-8e86-dfaec13b06c1',
  'b68694f6-668c-4151-91a1-d68ec350cc96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '249e3f92-ffcf-47b3-9b6f-cb16975695bf',
  '4e78215e-621f-47d5-8787-d204885acc5f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2972c454-8fbe-414d-889e-76740f2c15dc',
  '4e78215e-621f-47d5-8787-d204885acc5f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '443d194b-5387-40a2-ae72-de2450a8e40d',
  '49800a34-a17b-4bb4-b37f-bf1592640419',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  57,
  57,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b322d384-9ed1-41af-89be-1b8ab06c393c',
  '8bb04613-f459-446f-beb7-75ffbdd04929',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2eaa73d0-df63-4856-9d17-fe7fe6f27876',
  'd5cc8745-dd02-4276-be2b-dafec56a6395',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  63,
  63,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8a1529ae-6ff5-481e-ab1e-f0a6443dda0e',
  '9d923328-95b8-4826-9caa-7d5d72d56efe',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '30c60fc2-b482-4ec0-a4ed-9ec864c95365',
  '88d1d359-0002-4bb3-8b42-233eea38996d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6c2dd112-27d3-482a-9901-528a115e38bf',
  '88d1d359-0002-4bb3-8b42-233eea38996d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5d9bee99-2ca9-4a0e-84b6-1a4e6f1782b1',
  'a39961e4-7d47-449b-bf22-e73a546a2941',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '681f64d2-4c15-4d09-b790-b3e0a3131e5d',
  'b650d2cb-a144-4bd4-8adf-11b8634a2e1d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9903925-cd9f-4d80-8e17-af9688b960a1',
  'b650d2cb-a144-4bd4-8adf-11b8634a2e1d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6524fbfe-64df-4a84-8b15-19b7779c5897',
  'b650d2cb-a144-4bd4-8adf-11b8634a2e1d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8456d34a-2f9d-4dca-9f79-d144b7faf6a4',
  '6c23b389-ded2-40b7-baf2-ff6678380305',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  127,
  127,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4dd9d7b5-d67c-4354-bf1e-a7e416215ef3',
  'c34331ab-6d96-4732-bef9-13f3c5f0c372',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  25,
  25,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '14714a90-e2e3-4549-9696-e8654c0ec0da',
  'fc096667-82f8-4846-8eea-ad2342ba2565',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '16643ca2-0ba4-4c48-a999-cc01085d8f72',
  'fc096667-82f8-4846-8eea-ad2342ba2565',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'aaa00dad-177a-4ab7-b4b0-5eb83f72b6d3',
  'f7fc5a7f-e535-47d9-b7d0-e42c94ae297c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f8455b9c-deb7-4820-ba67-c5280de3c3b1',
  'f7fc5a7f-e535-47d9-b7d0-e42c94ae297c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a80f509a-c61a-46e4-9755-2bd01dd92879',
  'f8e759e3-d9e7-455b-8f5b-7e6d91f0980b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8bc5c8e5-ac04-42bd-8ff1-3bd362d32a4c',
  'f8e759e3-d9e7-455b-8f5b-7e6d91f0980b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd9fce99e-e8c4-40e1-a7d7-18094baaa1bb',
  '8566f117-706d-48ec-b191-aacf61724ece',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b94aa970-dd35-43a6-a355-9d15048a9946',
  '8566f117-706d-48ec-b191-aacf61724ece',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9b068933-d806-4171-9a1c-1a05961d00e7',
  '1f530ca4-b50f-4cd0-8afe-c6735868cb80',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '93aa4335-7dfa-4b5b-b174-74aec33dda0e',
  '1f530ca4-b50f-4cd0-8afe-c6735868cb80',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '479805a0-1e2f-4c71-8d35-e5351b7c73c1',
  '574697de-df35-4df4-b387-90595511d5eb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '868fd6b7-23a4-419e-9991-53893bbd638b',
  '574697de-df35-4df4-b387-90595511d5eb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1468bd62-52d5-44c1-aed9-1da673885e61',
  'e6f1753c-24bc-4661-bf18-19a1394c89aa',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  64,
  64,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '61a9a68c-0d01-421a-9949-ee4f418d9286',
  'b07ba002-a24a-40e4-b484-e72daa137f07',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1d24467b-9ce5-4db9-a191-3f9a6751480e',
  '66fe066f-82ed-4012-9421-150f73de9759',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '12fd93f2-7e72-4660-b9cd-dca989846c83',
  '607ddba3-76fd-4fae-a23d-3f39af3c0184',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f91ad1b3-9af5-4723-abe2-5e47287b58fb',
  '1d25a071-e0b0-4286-b159-3dd7f58b2658',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8b063a23-9ef1-4a99-bbd0-ccce7c85e99a',
  '1d25a071-e0b0-4286-b159-3dd7f58b2658',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  1,
  1,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7381886f-6867-4562-a236-0bf2eb958cb4',
  '1d25a071-e0b0-4286-b159-3dd7f58b2658',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6f5fbe9f-59b9-4185-a1e3-ea7c1b16a3a1',
  'a4feb124-7550-40ff-a7b0-799d1ff4027f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f1a9fae8-26ed-4938-a972-872494abda4d',
  'a4feb124-7550-40ff-a7b0-799d1ff4027f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a5166c4b-2af5-41e6-8ee0-76b85cd40653',
  '1eab4428-5536-48bf-b5d1-df7672aa6a2d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  34,
  34,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '20ffcea0-d560-49a7-acb8-828ec3846b28',
  'e822ffe5-7320-49a3-a298-f1ad9c0485f4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b0e42d89-7f53-4b1e-ae1f-a56831c2cecd',
  '6fcbd5cb-2300-4449-955b-90c63e511c41',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0165799c-7fff-4a51-b841-12c6e8474d5a',
  '6fcbd5cb-2300-4449-955b-90c63e511c41',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9a7647d2-8ce2-43c5-9419-0fa9450830ec',
  '742087ae-35e7-4398-9051-fa704ae6a306',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  70,
  70,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5ca7a9af-94b1-422f-aff3-120b6665c1ad',
  '31a8e617-a220-474b-a747-ef394dc12ebd',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6a2e9db6-1bb7-465e-a360-49f4df974063',
  '18da701d-0f5f-4cd8-b3fe-6c3273eb2cbd',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  24,
  24,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b08e48b-cb2b-4af1-8976-f73275c56071',
  'be7ce172-2b50-4aff-b5a1-ee089a29d736',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-004'),
  'Dress',
  5,
  5,
  5.5
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6cbe7061-c64d-43f5-bef2-61768ce2ef2a',
  '3b8ae092-2e9a-4882-bc5d-71c98b92f3da',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cb4c417e-b6ac-4751-a372-dcf92aedeaa5',
  'ab51e48b-1985-4cb8-a0d6-c5c6a419bd42',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2169587a-24b8-44c8-8c74-c80bef4e1261',
  'c73d4f0e-403a-472a-8a03-915ff1f63845',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c43739d2-978e-4cc0-aad7-98250d4d1544',
  'c73d4f0e-403a-472a-8a03-915ff1f63845',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ad8d617c-7f42-49aa-be78-676225ee6b70',
  'c73d4f0e-403a-472a-8a03-915ff1f63845',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6dce0d0e-8a6a-4322-9476-6287ac89fb4c',
  '3b1c2244-f665-4b89-9a62-ce374d2367dd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '65438e29-db36-47c6-9346-cb0c53ead41e',
  '3b1c2244-f665-4b89-9a62-ce374d2367dd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ee3e38ff-9667-402e-a98c-05d30fda28ac',
  '3b1c2244-f665-4b89-9a62-ce374d2367dd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a9a2fe73-74aa-4e39-a944-321c9655a198',
  '2b143678-7bf4-4785-aa29-b8c47b37ee9a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  2,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7ebb878e-b358-4b68-bf6d-8e1f139b5613',
  '2b143678-7bf4-4785-aa29-b8c47b37ee9a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cd64b4a0-b0a8-4e90-9db0-7dea9f58c4b6',
  '2b143678-7bf4-4785-aa29-b8c47b37ee9a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5e053b11-e14f-475b-8877-3b71ace45665',
  '12300e82-dbd4-42b6-9809-fc1209a63eb0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0bd24900-8221-4846-b912-08606fb1b649',
  '12300e82-dbd4-42b6-9809-fc1209a63eb0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '243ef1d3-8be2-447c-a4c7-fe5a12adae4c',
  '12300e82-dbd4-42b6-9809-fc1209a63eb0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '83eaac3d-c115-435b-87e1-ebe19779aae8',
  'be86c9e5-1535-426b-bb50-8ae0cc990616',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7c697243-2034-4ede-976c-b11cfb59ca4e',
  'be86c9e5-1535-426b-bb50-8ae0cc990616',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  3,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '20549e61-bf88-4f16-a2ea-c00533637436',
  '7b29438f-5562-4709-9f70-2463552c7dd7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7cf3cd97-1c9e-4f53-9cbb-cbd8b4c062b4',
  '5b79d8c4-cfbb-4532-b7d5-695c9d7b1f28',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  70,
  70,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dc646564-274c-47cc-a5aa-a3d9ce600444',
  '382b0b32-e40b-4be1-80a5-eed956b1d3aa',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  10,
  10,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a61f4932-b745-4b0f-97fd-06e8b2afe513',
  'b02079a7-d62b-49e2-95e8-6a357e23d1cf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6272b6bb-bea4-43a0-bb42-c9158366b65c',
  'b02079a7-d62b-49e2-95e8-6a357e23d1cf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6020280b-c84e-47fe-820c-465148424b7a',
  'bf365482-ab37-4b02-9aaf-9bc26d85b7fa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ddcda4f3-055e-41e6-b732-7153221c11d1',
  'bf365482-ab37-4b02-9aaf-9bc26d85b7fa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a9a8a663-02e5-4e84-8f86-1458a3dc7594',
  '02919017-22b3-4ad6-b559-b527e90affd9',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  88,
  88,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ba0d85ff-cfd4-45c7-9832-e6338256d3f1',
  '6d40ea36-122b-4f0e-97cc-fe24e4133c7b',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  100,
  100,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7c38f88d-74d4-4d9e-bd9f-11d1cd448240',
  '6d236dcd-ad5c-4806-b5f8-7f5f90fab00d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  100,
  100,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2b57413e-18c7-46bf-ad6b-ed665b0426e6',
  '2c652402-212d-4919-a4fc-218e2b359b72',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  100,
  100,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'be8a9dd5-52a4-4dad-8b4b-246341213bba',
  '8a00aa54-63d2-4b4b-86ca-02b32ce21b35',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  50,
  50,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b58a5e2b-a329-45ea-8bee-b6343bdfa7fc',
  'd50864f1-2911-4590-b4cd-e52d258ca88c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  18,
  18,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0864fe89-184f-4c79-a8d6-08fc2785209c',
  '38ba80c6-fa11-47fc-bdd8-5e656a0cadda',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  3,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9cba8f1-c1f3-45f9-9444-3b0c05c2692b',
  '4169fd0c-b814-4b7c-b2e9-dd94fb65d849',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  91,
  91,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '93e562d7-5fc5-4356-85c9-c6819d07c622',
  'c20457ca-b2e7-4d49-930a-2bb1d99f475b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b8a8e7d-a1cd-419c-804b-80691e6b49b4',
  'c20457ca-b2e7-4d49-930a-2bb1d99f475b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7aff80fa-e8c5-48da-88a7-319200f9c3a0',
  'c20457ca-b2e7-4d49-930a-2bb1d99f475b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '36d2cf03-77d5-4222-b844-5709e67055ff',
  'a501d8b2-7c03-4a6a-a590-bd48089cf1ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '67159e24-3c98-4505-a2be-a75eff741fc8',
  'a501d8b2-7c03-4a6a-a590-bd48089cf1ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6e03d5ea-f2da-4515-80ed-86204f6d8bb9',
  'a501d8b2-7c03-4a6a-a590-bd48089cf1ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9fa79abb-b71c-4497-b956-5adaee3573b6',
  'c9dac062-e591-4318-80a5-1fb4751f18e2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f2f958d5-a4f0-4394-b731-5d15d622f720',
  'c9dac062-e591-4318-80a5-1fb4751f18e2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '89ee28c0-01ac-4296-9450-fd995c4caf42',
  'c9dac062-e591-4318-80a5-1fb4751f18e2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  2,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '595b0b38-e567-4a4e-b6a6-87958aa92575',
  'eea82d21-7af0-4dcc-942d-912dd5d55189',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f346f37f-bc9f-4cee-b8aa-2f4887153787',
  'eea82d21-7af0-4dcc-942d-912dd5d55189',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eca6e684-5f0b-4ae9-8785-9676700e4c93',
  '2a1d15d6-0400-407a-8694-abcb9e92181d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  11,
  11,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cc509c77-cd6c-42c4-9050-9d1906232bee',
  'd47befda-c371-4897-b9d7-663421b8694e',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  10,
  10,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '384be800-f094-4434-9ed8-5cbd7d4342b0',
  '11e0dfa9-e5cf-4b46-a689-29a250993b4e',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  10,
  10,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6a073b96-2624-4e00-bb25-7df83350676e',
  '0bbd5fcd-b56a-49d3-b733-dccbde4b3469',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  10,
  10,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4ac2f4c4-4c8b-4d82-ba52-82c606c8dfd4',
  '63cc514b-369f-4e04-ab5d-dab221150718',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  6,
  6,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd02e86e3-50cb-4886-b272-4b8f71ded8e7',
  '0040d8ba-3009-4a19-9ce4-04d171e36682',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  8,
  8,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '340c4973-173e-47aa-b14e-2908bee2a708',
  '476fa9fa-3641-4e47-a3a7-5e1ae15d909c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7a887202-2957-4624-b44d-79a235462817',
  '476fa9fa-3641-4e47-a3a7-5e1ae15d909c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b8ff29c5-a4f1-452f-9355-dc6bc76feebd',
  '476fa9fa-3641-4e47-a3a7-5e1ae15d909c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4918e25e-fc17-418d-9efe-3c8045f40f2e',
  '4b344e5c-c2a5-4b75-9098-da244a1ec00c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ba0ffd5a-0cd4-427f-a1b9-4746fa3bcbb9',
  '4b344e5c-c2a5-4b75-9098-da244a1ec00c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd93dc8bd-fc8d-4b9e-a9af-4d392f04b7bf',
  '914c9502-55e1-40cf-845c-f4ac7346da17',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ae1a08c5-d7eb-46c8-b0d3-aa2f7aad8eb8',
  '3c4d98ac-b18b-4039-bdf3-acbf1eaadc62',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  5,
  5,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bcc93422-dc6d-4d7b-821e-a89e7d72146c',
  '30cc4d58-f91a-4c34-a8c3-d863c5d694ce',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '74bdd134-eee4-4a4a-86a6-65383a242d37',
  '30cc4d58-f91a-4c34-a8c3-d863c5d694ce',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a8cc66a-d04c-4d16-8610-0d0c48f53d70',
  'e3f60d7d-0b6b-4a99-83f4-957d36606d25',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  94,
  94,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b530f04e-cf12-4957-89bb-57f51671de05',
  '8a6d62ea-4151-4b7c-990d-783a55317e18',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ba3ba3f0-742d-4d49-a232-53a2222e0870',
  '1b8bd3a8-5d4c-440f-ba98-12706b325a38',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9a2a3da-8a83-452f-8a9e-6bbc34233b4b',
  '4b10a26f-7ae3-46c7-a81d-258f61c76cb2',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '781f45a1-81d7-4496-83c1-e6e61fc55c5e',
  '06b7b1f1-a2f6-47b4-9265-d83772603243',
  NULL,
  'Housekeeping',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1bab381c-e1d6-4eb7-a43f-a3ec89b9af2f',
  'fbb9ddf6-83d6-484c-9f80-1b48194705b4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  113,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f7ec2d77-1e46-4f06-a9a8-37865ef09e15',
  'a4337c74-6558-49b2-8d42-e27d4bdcb917',
  NULL,
  'Housekeeping',
  2,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4d5b3a15-c89e-4ad0-b472-b745ec4a0430',
  '2c9357da-759e-4caa-9c07-61abdd0bc7d3',
  NULL,
  'Housekeeping',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a1ff87c7-694c-425e-af8e-260b95bd08fd',
  '49690d4a-cbeb-4536-a6cc-058bb345d1bf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '93fcebea-51cc-4db7-b139-b04ef8e99f48',
  '49690d4a-cbeb-4536-a6cc-058bb345d1bf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4846b642-6a67-427c-8de9-0e3f51261785',
  '49690d4a-cbeb-4536-a6cc-058bb345d1bf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b07688a8-5c94-4a4b-87ec-501f79c03e6b',
  '370e74ac-6b23-4161-80d0-a79a0c446c04',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  3,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '08306ebf-32f2-4ad4-9304-4d8788d4d5f1',
  '370e74ac-6b23-4161-80d0-a79a0c446c04',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3f7c6c75-f2d6-4492-a16b-5c6a77f866b7',
  'f25e2a14-9c0e-40c6-8ce9-edb5f1bcbb41',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'de39606f-8ef6-49f2-8286-d8a7ba6da6bd',
  'f25e2a14-9c0e-40c6-8ce9-edb5f1bcbb41',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '84e90473-feae-4374-ae7d-31ee84227478',
  'f25e2a14-9c0e-40c6-8ce9-edb5f1bcbb41',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5562b355-d247-4df5-8e15-1ee5fb776f71',
  '8470d885-fe8e-4591-ad7b-3794a94eb2e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fea21968-1574-4378-a1b3-348f0d628fed',
  '8470d885-fe8e-4591-ad7b-3794a94eb2e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f2b0cddd-47fe-4ae8-8b21-0620b28cf56c',
  '8470d885-fe8e-4591-ad7b-3794a94eb2e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4a6f7f52-cc37-440a-8b80-ebcc55b4e977',
  '33523d54-f6fc-4d71-98bc-fdd4d82fb420',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8db8a6a4-5e29-4852-b9a0-43bb47a51ac0',
  '33523d54-f6fc-4d71-98bc-fdd4d82fb420',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '11776229-b894-4873-8eb0-d0102f827f48',
  '34d18743-c765-48d7-99c1-36c8b4313343',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  3,
  3,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '054a8029-0fc1-4500-9a82-2c87f00acc26',
  '9ea49935-5148-4310-992b-f9e4678485ce',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  22,
  22,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '231934a5-298d-4002-befb-434f0594f770',
  '24345c44-fe3e-44d5-8072-0e0e3bb7dbc5',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  70,
  70,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a07ed7ba-7adc-43f3-90f1-95d80c586abf',
  '77da330d-ef3d-4da2-a83f-1fb2682b364a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '57c79cb4-215c-4080-bd0f-c4bd469df58b',
  '77da330d-ef3d-4da2-a83f-1fb2682b364a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '049216a1-9205-44e7-8ef7-a481fac5cdaa',
  'b4e16b24-47dc-4b33-8fa5-1dfae6b922ae',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '835acd7f-d3cc-4f72-99bc-32dff1efc65d',
  'b4e16b24-47dc-4b33-8fa5-1dfae6b922ae',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3e3cc42c-8267-4c56-ba5a-31b543a4bfc6',
  'b4e16b24-47dc-4b33-8fa5-1dfae6b922ae',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8b706162-8474-471e-b890-d4ee3d213b3d',
  '0c5cd8c3-adf8-454a-b714-94b32d62663d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  126,
  126,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '877c6b32-c4fb-4032-8ae8-7502dd5d88e2',
  '0a073710-f163-4624-b345-6fe19d233857',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3e75b9bb-25d5-4784-92db-14a6d0e34fe5',
  'a4ecff43-8451-4ef2-a0e0-b9f17afdc44b',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  18,
  18,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '36ea0450-45e3-42c9-a316-7aff770b8772',
  '8f001e01-3ebc-4355-8c97-04c9bf34db3c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '804b3755-7629-4a9d-abb4-cce2d12dd155',
  '8f001e01-3ebc-4355-8c97-04c9bf34db3c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb0c379d-85a6-4ed9-a2cd-5b0e552a6d09',
  '8f001e01-3ebc-4355-8c97-04c9bf34db3c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dce61a71-f357-41e2-9ba4-bde606e92ca6',
  '345217fb-7981-45f9-b1cc-c0958f381890',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e8d8abb2-6324-4279-bcb4-bd0c266f3f6c',
  '345217fb-7981-45f9-b1cc-c0958f381890',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd6f8a4ad-6920-4d70-8257-5fcee968123d',
  'b61c0cc2-b140-430b-8850-c16f1ab12063',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f376bd7b-ffd7-4e06-b824-a5da926ad82c',
  'b61c0cc2-b140-430b-8850-c16f1ab12063',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'badc388e-17f5-4f51-b7a0-8fa407d5337b',
  'b61c0cc2-b140-430b-8850-c16f1ab12063',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  1,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd2783e48-55be-4e10-9959-86a941447861',
  '8c1d6e62-738b-4cb4-bc71-5a5fa459047f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7712ced5-dff6-47ce-b767-01b9a82d07ef',
  '8c1d6e62-738b-4cb4-bc71-5a5fa459047f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6bad3847-45bd-44c0-b795-c1990fc56c28',
  '0cbc88d3-d6bd-46a2-901a-9bb5d2fecb28',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  4,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5bedfd79-612f-46be-8ea6-0dafbe4ff221',
  '0cbc88d3-d6bd-46a2-901a-9bb5d2fecb28',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  4,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a8ce3c3e-aea0-4093-9b38-f4cefa49e16d',
  'd84ae450-f046-4f36-b175-bf6dffa88c7a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b8969dbb-6f60-4e89-9618-68132d81606e',
  'd84ae450-f046-4f36-b175-bf6dffa88c7a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ea7ab101-e48b-46d9-9aab-dbd6291c0406',
  '43619760-fecf-443d-b58a-3b0146af5356',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a6a68753-ca49-4215-a4eb-b64305ebbe81',
  '43619760-fecf-443d-b58a-3b0146af5356',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c486d174-909d-4065-b014-7648bd20054a',
  '93578452-d94f-47bf-9d09-c0e696bcd9b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ea02f039-a3e9-482a-9afe-fbc0706b0fb4',
  '93578452-d94f-47bf-9d09-c0e696bcd9b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd08bef72-8009-4bbb-9c0c-f962d8be8e4b',
  '93578452-d94f-47bf-9d09-c0e696bcd9b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bc657767-7265-4552-adc4-56e6d90c3f82',
  '7d1ca2b1-16f5-4938-8b22-3be6bc4ea104',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  79,
  79,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '63212be7-b90d-4521-93d6-301fa9a3adae',
  '5d652f7f-fe8e-40f3-9d9f-222507954021',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '670a101e-6195-4b79-88e6-c5cc94e2457b',
  '5d652f7f-fe8e-40f3-9d9f-222507954021',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '20e235ce-1e09-41b4-8e27-d50a9b0ccc56',
  'eef60fe9-857b-49b7-bf4c-1bd5d0aa90f4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  167,
  167,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8eb98b96-32e3-48b4-b3d1-c7b12652b7b2',
  'c654b518-6a2f-4661-a5a6-5e89ee63af21',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  35,
  35,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5fbee963-c19b-46ea-bb02-d27f78829eaf',
  'e7c9500e-f497-455f-b388-30f30826d48a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'af4fe1f3-44a4-4262-bc16-9ca2661f0af5',
  'e7c9500e-f497-455f-b388-30f30826d48a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2ff12f76-4e5a-4787-90d8-9dc44d110575',
  '50b07e32-2bfb-4b2f-94b3-bc584102faea',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '97d1877d-13df-4568-9da0-7fb17e318d5e',
  '50b07e32-2bfb-4b2f-94b3-bc584102faea',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cc010801-23ec-4f79-82db-7b4452f0f216',
  '325ee689-3860-45d9-8864-e2cd084c978d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '28f1b1e2-1420-452a-a5da-3c4643e9e9a6',
  '325ee689-3860-45d9-8864-e2cd084c978d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '41cfa8dc-493e-49f1-9651-d2485fd24a4e',
  '2c3367a1-bc4d-46cf-9cc0-ffa138387044',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4759bbb8-e261-4d09-a030-0a4e9f2dff5d',
  '2c3367a1-bc4d-46cf-9cc0-ffa138387044',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '454ed728-411c-4c7b-b5b7-da76ded6ae00',
  '2c3367a1-bc4d-46cf-9cc0-ffa138387044',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a764e9b-16f5-4e50-a6e4-3619426558cc',
  '316bbcc4-b250-43b4-b937-d9c2b207ed05',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  64,
  64,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3ddf6bd4-67f8-4500-9f11-dbc9aca645ff',
  'a35f630f-e361-4f8e-bedb-dbef63144f08',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '97351697-e15d-4a10-abb8-a1ce3ee30a70',
  'a35f630f-e361-4f8e-bedb-dbef63144f08',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ed71234a-a7f0-47b7-a8ad-ad5bdf38d55a',
  '836c7341-b62f-46fa-825c-4809efb86e00',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e006981b-5e9d-4998-b2bf-c02b9a38b951',
  '836c7341-b62f-46fa-825c-4809efb86e00',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b06bba56-ff20-4270-834f-5a468dd43e21',
  '312b8d7a-dea4-4914-9085-1d14034287fe',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  81,
  81,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b5833244-8f34-4631-895d-a35de8f8ef01',
  '40d26299-5c6a-42ef-8880-36e6a171f0bf',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  100,
  100,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd481707f-da08-449d-9bf9-fecdd3670d79',
  '5a924156-df4b-4182-b191-b6123e6630f6',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  100,
  100,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f5f9d1e5-55f3-4804-84a5-8fea94aa1e7c',
  'b341e154-0a3d-4b2c-b496-3a51fd42f840',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '18748bbb-8f94-4a26-9522-6afb5f1f5b8b',
  'b341e154-0a3d-4b2c-b496-3a51fd42f840',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b13d83a7-b7c4-4e76-a6c1-66dfbd9b9365',
  'b341e154-0a3d-4b2c-b496-3a51fd42f840',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '76bf6321-025f-4e8b-a0a0-9b0bed3ef37b',
  '7c9d83f7-26f8-416f-b5a9-1c78ea0a172e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8f1b4c8d-e07d-4307-8512-5556533b80ba',
  '7c9d83f7-26f8-416f-b5a9-1c78ea0a172e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '36608e8e-eb21-4a31-a724-4544898598fa',
  '7c9d83f7-26f8-416f-b5a9-1c78ea0a172e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ac62b515-535c-41e3-931c-5975ed7ba2a4',
  '9f07aac4-f334-49be-8e5f-8b6b036cff9b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '74d9dd4b-c752-4451-8ae8-2f2fd9faf12d',
  '6b0b2a30-c512-49dc-9730-8f26bfa13277',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  29,
  29,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a01517de-196e-4d25-82b1-f4bd14ee366d',
  '26c181f5-4110-40fa-a5d0-cb664bdd9fe4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  22,
  22,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3becac52-52ff-4e90-826d-c64aeb037243',
  '2672de2b-aa1b-483c-8611-eeca1b6cf223',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '50628a56-e855-4b3e-9509-1ce58eae3dec',
  '2672de2b-aa1b-483c-8611-eeca1b6cf223',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '795fb371-e0d8-4cc9-be41-20bb4d8c3b7c',
  '2672de2b-aa1b-483c-8611-eeca1b6cf223',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a300c8f-9ef7-45a8-97e8-0690c70bf915',
  'a5b634e7-2869-4d61-af00-55bf7986b365',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  13,
  13,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7615af3a-ce4a-44ab-b1f3-03c3cfd43917',
  'd74c83c3-4125-4e86-9d49-77492123d8bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5e6094fa-d420-47a5-a8b3-44622bed2fc1',
  'd74c83c3-4125-4e86-9d49-77492123d8bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '79148e2e-0e46-4483-9c2b-c09cc90ae776',
  'd74c83c3-4125-4e86-9d49-77492123d8bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9bb79224-d890-428a-b98e-30cfd389cc37',
  '36fa3b02-cc7c-4358-a180-8046cbfb12bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b89f7cfe-ae42-4a69-b036-5fc3cc46a7c5',
  '36fa3b02-cc7c-4358-a180-8046cbfb12bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6b3625bb-2f3d-4f41-b6d8-c9562b7afdbc',
  '210535ae-fb7c-4e45-bb52-ad9c0adf707c',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  13,
  13,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'baab5178-db68-40ee-8c5d-e9d4560c773a',
  '87a01a3c-f820-4ffd-a35f-03f391a86d9d',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4a4a8c46-cd8c-4edc-b57a-fd2bafddfab2',
  '59e6394b-c7d7-4b05-b349-f5d42e39c044',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9e7e17d-c26a-40a5-bb14-80d136ea9a84',
  '59e6394b-c7d7-4b05-b349-f5d42e39c044',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f34ae006-9342-4d63-9e87-071b7ceac577',
  'd1ea8548-3308-4a84-99f3-0e48f0e9bca3',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  33,
  33,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c4a7e7a3-3270-4175-b195-a9c6caa5c9e0',
  'c9ef1ac3-1c3d-48be-b7fd-ff2f1bcfbca6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2be0f0cd-bb1b-40c0-8dab-dd16ca3fd9f4',
  'c9ef1ac3-1c3d-48be-b7fd-ff2f1bcfbca6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '758c8c9f-f17c-4850-8e21-66bedad78bf2',
  'c9ef1ac3-1c3d-48be-b7fd-ff2f1bcfbca6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e587c421-03f6-43e3-9c6b-838f98bd35bd',
  '11f290ed-75a6-4f61-80f8-a0da8fd54614',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0c7dca0a-2f3b-48dc-a402-6ce25605e97d',
  '11f290ed-75a6-4f61-80f8-a0da8fd54614',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f7ca0192-59a1-436d-a33a-2eb862e00d1d',
  'c841c893-8b9a-42af-8c71-db506ea9710b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0bacc6dc-8fff-434f-bbd5-3af67e382ecd',
  'c841c893-8b9a-42af-8c71-db506ea9710b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b26712b2-a0a8-4e72-a053-b7dc506d71ef',
  '8f88590f-24e1-43e3-b4fd-2ad8ce1ce126',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  125,
  125,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e0a8bbe2-68a9-408b-b4e0-af54504bd901',
  'dc02b36a-5e20-4e97-8e0f-1c335cd0feeb',
  NULL,
  'Housekeeping',
  2,
  2,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ccdc6e8c-46a0-4235-9380-5d4bccaa91c7',
  '60e46caa-af6a-44cb-af2b-974e1b93a7b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd4357831-649e-4af6-9ccc-c4c391da0bb6',
  '60e46caa-af6a-44cb-af2b-974e1b93a7b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a5be4de8-fa32-41b6-af17-1ccf09737088',
  '60e46caa-af6a-44cb-af2b-974e1b93a7b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7885329d-a8b9-4caf-8a73-6148f8174481',
  '65cc57a1-82c4-4bbf-a954-a787a79560f8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4a8a1776-2835-4d77-aff8-74b3a4d1e87a',
  '65cc57a1-82c4-4bbf-a954-a787a79560f8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5e8fc155-4025-47ce-8e23-5dc6315918de',
  '4070d273-c157-4c79-9d6d-f4e500875481',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd9fced8f-ed8b-4c0d-ba21-c671a74b43bc',
  '244ffa6f-4877-4917-abb5-8a1f3241af84',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2dad1911-d905-452d-b717-f35e520ea2e2',
  '244ffa6f-4877-4917-abb5-8a1f3241af84',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '28860da2-ee16-4ad0-9d9c-b3d2bb4fdc2e',
  '35a4c4f0-054a-4790-bd3d-328903aff403',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f52e3dc9-2fea-4320-99c4-077265f71bbd',
  '35a4c4f0-054a-4790-bd3d-328903aff403',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  3,
  3,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8f39e5ce-115d-4671-b205-6f6bbe16cbc9',
  '02ef67e3-08e4-4cf5-a3f2-ab6edeed00ac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1319230-f17f-46f1-944e-0921e371d60f',
  '7b6f5f1c-0c0d-4094-a6fd-ab8c3a6d87a8',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  45,
  45,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2d73ed81-0251-44bc-a6b7-f8fb96a53d0b',
  '40a19d12-cf1c-41a0-ad85-42fa08def821',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  9,
  9,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '32e1efe6-4f53-4261-b01c-07d286d96dbf',
  '9687926f-a0c5-4084-90c1-025da2995d12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c37d6355-f2d2-4c85-b6d2-583cb9af6971',
  '9687926f-a0c5-4084-90c1-025da2995d12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8336ed46-6908-4be6-980c-3e382c04d8d0',
  '2b3d968a-450c-451c-9594-05b654fddc2d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0b3a4095-e4b0-4f04-8acc-0b8722e86380',
  '2b3d968a-450c-451c-9594-05b654fddc2d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd541a524-bfce-40f1-91eb-736ba5e76085',
  '967269e3-88a8-48ba-a8ed-8ab1b10df5dc',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  78,
  78,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '382ef53e-a98e-4b7f-95f4-c41dc648813f',
  '9098dcf2-aebb-4fd4-9e50-552c5b66fc92',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '67f3d1b2-118b-4564-b0d9-39cbe8977370',
  '55ac2536-af8f-47e3-ae0a-7038a1d9c831',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  3,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a30b700a-6cf5-41a1-b7b0-74491d48f7d5',
  '55ac2536-af8f-47e3-ae0a-7038a1d9c831',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  2,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c0c0c3fe-536d-45a9-a724-ede691e24382',
  'b2768f41-4a74-4c2c-99df-df82966cadfd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  4,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8726415c-88f0-4792-a114-7483060c1f69',
  'f9843921-bf56-44bd-8b4f-0e13fb93f1bf',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd38b533d-1055-4f43-a742-079feba4614d',
  '12c25677-8ffb-40eb-aa8f-04606dbdcdb5',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c320cda2-a424-49ee-93e4-1842b390be17',
  'f6c64962-052b-4dea-9cb6-9be4c267a276',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '76c27b7a-b895-477f-907a-12bd9b0d1a19',
  'f0abed9b-be4e-4668-bc39-3bfc5f2e1f49',
  NULL,
  'Housekeeping',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '89b30a2a-b524-4d5e-bdb9-f738d62a7296',
  'acba3694-2a08-4f93-bedf-bb6ce6d3e132',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3d799145-d247-4d25-9d5e-1a6442f381a9',
  '323cc584-5ad7-42bf-8fd0-c253fd4608ef',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  94,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4fe5b03b-7ee0-4fc5-bd61-fe1f5bb91e1b',
  'f08a90b4-acae-41ee-990a-b7f147213ecc',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ab7b9114-4004-4711-be49-e8e98d9127fa',
  '96bcd7a3-799f-4748-8676-641aeca9b156',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  4,
  4,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '20082f2b-36bc-4fd5-b072-a9e3a06fa164',
  '6b61e26f-6e4f-48ce-9535-b79876808507',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f2108c9-2685-4dbf-bd1c-9840f97af1ab',
  '6b61e26f-6e4f-48ce-9535-b79876808507',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04b2584d-d49f-43e7-b203-d03236d30a5a',
  '83813e93-cfad-48f5-bff9-642817a2fcf7',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  15,
  15,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '404c428a-80ff-47a5-8efd-53fe579d32d2',
  '2c530d1f-e5d3-4a3f-8002-3f9b0c9a6eac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1f4c7ce4-d4b6-46e0-9523-88cb862e7a03',
  '2c530d1f-e5d3-4a3f-8002-3f9b0c9a6eac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ea3409d2-9dbb-4b46-983e-72e404946b8b',
  '2c530d1f-e5d3-4a3f-8002-3f9b0c9a6eac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '39a929d6-61cd-4a1b-8453-dc1c0e2694ac',
  'da8843a3-5fc3-4997-b447-c3d1bbcbc327',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6882513a-2070-4ad9-af18-e996538934f3',
  'da8843a3-5fc3-4997-b447-c3d1bbcbc327',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1a3a5ae5-cb4e-45e5-89fa-2dd40730025b',
  '56575fe9-892c-419c-92d8-bd6b10593dc5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd46f66ad-7a74-4b51-9fe3-c3edc963593c',
  '56575fe9-892c-419c-92d8-bd6b10593dc5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0cc1a966-77f5-40ad-82bd-cdfdec2784a7',
  'cce79f84-2cb1-4758-8935-36e10ab105c1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3bde7ecc-e01d-4ec8-8960-264ef9b2cab9',
  'cce79f84-2cb1-4758-8935-36e10ab105c1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'be2a4960-e665-45f2-92b2-a399251826b5',
  '985b6dcb-1424-445d-9322-68ea4927e1df',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  35,
  35,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5564dade-c1fc-4d2a-8f22-5058f897b7a8',
  '194816f7-c874-4bf3-b208-351f84f00416',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ad0de25b-8936-422b-8d30-2a9158c02d60',
  '194816f7-c874-4bf3-b208-351f84f00416',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd1d75593-6fbb-4434-97d3-50075eff4236',
  'cd9a9d8e-63b9-47f3-8e9c-26181acc6b32',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  68,
  68,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5b83d9e5-3012-49ff-93c5-a7973fff3166',
  '535fccad-4e2d-4a89-8f4c-b7b5787d85b1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '34460f68-d9b3-43b8-a5b7-d0ff1ce98292',
  '8579f60f-237d-492a-a595-bda7a6c32e7b',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '48d11c40-2129-49c0-a2aa-792172ed46e9',
  '3eb5e3e8-816d-4785-8e68-2ddc156f1c74',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f7e47c3-3119-41bd-a216-2ff47c0e83cc',
  'af48878f-901b-4f3a-a534-a9f812dbe88c',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'db69d394-3448-46bb-842e-58ee15a2903e',
  '0359c2b8-34ba-4c50-a3f7-460f9c6783af',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0406b042-0879-4656-9fde-765b6b931232',
  '0359c2b8-34ba-4c50-a3f7-460f9c6783af',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  11,
  11,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a4455b8c-9fbd-4eb7-85df-6fda29e041d5',
  '0359c2b8-34ba-4c50-a3f7-460f9c6783af',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '81033f4f-cd68-42d7-8a71-164504c43f10',
  '2c0ab384-e11d-4eba-bca6-0b7d279d15e1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '50ce5a9c-658f-423e-9034-7347f49398ff',
  '2c0ab384-e11d-4eba-bca6-0b7d279d15e1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ac5f7e76-e919-4f91-96a1-d44664e7518c',
  '2c0ab384-e11d-4eba-bca6-0b7d279d15e1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3c766037-434a-4134-81d8-341fa584042e',
  '16d3b596-7cfb-4a31-a914-43af0ab17da6',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  95,
  95,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '449e38dd-4129-4770-935e-7164f7435a0a',
  '2fbd8fe3-69c6-41d0-bf73-d2f5d3bd32d9',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  10,
  10,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a904fb73-bc42-4e29-966b-27060ada62d4',
  '1d28cd31-8215-48fa-acaf-21135e20a49d',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c07f5d9b-e449-416d-8829-c12fd4176521',
  '360500d4-4e71-4eee-aa6a-b10806155f23',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3d2b74b8-ae27-4b6b-82b1-c01ddf2ddc9c',
  '360500d4-4e71-4eee-aa6a-b10806155f23',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7fe03ce8-985b-43c1-a148-911025b067c2',
  '9f44e53c-09db-44f8-822c-d3c39a539215',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '56ef14f2-34b2-426e-82b5-714ed53b5807',
  '9f44e53c-09db-44f8-822c-d3c39a539215',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ab007a70-fae0-4659-9c6c-ce1f893f138a',
  '9348f59a-c687-447b-884c-3ab2aa461dbb',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  34,
  34,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fa245ac6-032f-4785-a4b0-70f763992068',
  'b22cfe3d-0789-4d80-9ddf-1de8cd3e04de',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  74,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '49e7334e-f543-4bd4-9a31-6fb37c0231c1',
  'f72906ff-d4e7-4099-84d4-6b9873c5ddaf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '03579674-77fb-446e-bf9c-ad71e3a08d01',
  '1edb99e2-c82c-4ad1-a290-257179460d7e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-004'),
  'Dress',
  7,
  NULL,
  5.5
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dfc98133-9f61-47ab-b6f4-40b587b72a66',
  'f51982fe-7c41-4727-bc45-b9f126a717c3',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  56,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ea8d8ac7-fc47-44ac-b5a6-4472c9febb62',
  '78b41182-334e-4096-a982-23b573f126ab',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  22,
  22,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8ad7275a-c614-4f2d-b99f-eea08e56c2f1',
  'a6840986-7675-4460-bec5-a3a4a844a061',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd983a813-d432-42d4-ad06-c051dfee5be6',
  '0099503e-ad9f-434c-b58a-12d0406bb6a1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1bd57515-c0ea-4e6d-aa7f-5ece37f74276',
  '0099503e-ad9f-434c-b58a-12d0406bb6a1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ad2709f4-1f26-4192-9ef1-c8e707bd63bc',
  'da4d119d-9cd4-4807-977c-e9109d26dc49',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd26f01c3-1a33-4f4a-9d05-f7775710a196',
  'da4d119d-9cd4-4807-977c-e9109d26dc49',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7a4393d4-a483-4e56-9754-da221f94265f',
  '940fad38-9a73-4997-a0cc-15519d732d33',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a261121c-3db9-4abf-a7bd-be0f75dc8394',
  '940fad38-9a73-4997-a0cc-15519d732d33',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '713ad1f4-b384-4c5c-9a21-a44624e4525c',
  '39b5c550-1d1b-4b31-8988-4d1eb34cfb37',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bce6d9fa-a3ec-4de5-b2e5-41da88484f5d',
  '179226cc-281e-45e8-b872-49c8f2ec50b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '74b4f98f-1ab6-454e-963f-12d3f5c00bca',
  '179226cc-281e-45e8-b872-49c8f2ec50b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a09e51b4-4953-46da-b3f6-97e6457bf41e',
  '179226cc-281e-45e8-b872-49c8f2ec50b4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  4,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bf2489b0-4fc4-4cf7-8b9e-9842d54dad46',
  '08165fef-d75b-40da-be65-bd8f77c67f8b',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  67,
  67,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0603e1b4-1f76-451f-8a31-8a73c35c4401',
  'a46d424a-cf91-4233-89eb-5a8ad6d347ae',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  66,
  66,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6384c9fa-d384-4476-9fe5-811cb1951d8e',
  'b95b6e9d-d403-40ec-8c59-235ef0e47e3d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  68,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '36a04900-40fb-4b43-900a-32c92acbd5e0',
  '12164ff3-ac4e-4f4c-bb0f-dd244600a701',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '21789e87-6885-4ab6-83a5-854be878f330',
  '12164ff3-ac4e-4f4c-bb0f-dd244600a701',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9ef36993-8ae3-49e1-bfd7-ca6029a5d6d1',
  '12164ff3-ac4e-4f4c-bb0f-dd244600a701',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '92d33688-2d9b-4f8b-b59a-a80c2df3d60b',
  '63bd31b2-b0eb-4198-bd1e-25de8938b7ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1ea787f5-30b1-4985-9dde-468d52ff8f0f',
  '63bd31b2-b0eb-4198-bd1e-25de8938b7ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b050f3bc-2cfb-4dd7-9775-16b74904ec1b',
  '63bd31b2-b0eb-4198-bd1e-25de8938b7ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '43ebe255-c60f-4f21-a8a8-8f5fecdc14d1',
  'c8ec1d51-7add-43f0-bd2e-92bbc5ab1e44',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0d9f3e0a-e8ec-4b68-bb33-4259c702b067',
  'c8ec1d51-7add-43f0-bd2e-92bbc5ab1e44',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'af76d2ee-6eeb-4c9b-bffb-fa2a04540f88',
  'c8ec1d51-7add-43f0-bd2e-92bbc5ab1e44',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '013e1a2d-1db0-4f62-bb4f-400a310a7b28',
  '088de4c5-8511-410e-b30b-4d643b4b1a77',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  20,
  NULL,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '99f407af-d019-4b97-8127-92bcf1964a1e',
  '0d7e8220-c892-4552-b6d1-c78950aee187',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '819fb24b-d6fb-4489-921a-ae1ca3aa36f0',
  '0d7e8220-c892-4552-b6d1-c78950aee187',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ead3bc25-5880-470e-ba26-a2697297793e',
  '066f0233-16ed-4a3d-9091-25c5f72c2a4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '51a6079e-fa44-4501-b97b-c4a2c63b73c9',
  '066f0233-16ed-4a3d-9091-25c5f72c2a4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8c19ace4-1489-41c4-bcb7-c93dd3fa6061',
  '195ed83d-aa97-4dda-92e9-6a78519ab6f4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1e39a4ed-f6d9-468f-b183-98cf1208f878',
  '195ed83d-aa97-4dda-92e9-6a78519ab6f4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fe58bfe5-fc0e-4408-9772-2d6a0d2ca665',
  'd7e43856-90a9-4968-8363-6e8bad2f2421',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  48,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3085c505-c06d-4c87-95b0-e9583ee224bc',
  '0e582224-4aae-4f78-a80a-d9e654f36452',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '42dc166f-0930-47d2-b499-41898361b314',
  '0e582224-4aae-4f78-a80a-d9e654f36452',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '717827d5-c5eb-495f-942e-ff55e78c2798',
  '0e582224-4aae-4f78-a80a-d9e654f36452',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0d34e46e-c5e4-44fe-8aea-bf9ab473a6ed',
  '4f1c681e-59d6-4f28-a307-a4c329b0a344',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  27,
  NULL,
  0.22
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c01e108d-7147-4953-b7e8-97afe7de80ca',
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ca8dfdae-c597-4cf6-a5ad-a9dcda333f3a',
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '001646c1-b7a0-4b97-9e5a-4b447e57103f',
  '7495f6a9-5e04-4c3f-b015-5d6b636648e9',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '6969ec96-eb85-4640-8805-fa8460b492a9',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '0de13f53-da73-42d0-9a46-06acc46ec7e3',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'e562ead5-ac06-49fa-9a0c-0ffe0607443c',
  '0da46eef-a27c-4fdc-bddf-9815393329ed',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '2e02e613-e0d5-40ba-a3ff-b73f76c55f19',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '22ca061b-df65-4a30-9b39-02e93c4135ce',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'eb6e6399-1eeb-439e-a66b-0988640d07fe',
  '4f8f59c1-985b-4660-aeb0-ec886279750c',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '033523cb-f0a9-4faf-9d35-50e5d96c0e3b',
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '60e88a65-cc89-4d1c-833b-31a09df3b2ae',
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ad58cbef-ae42-477c-aece-c2ad5d6de8bd',
  'b36b3594-a2cd-458f-833b-cf9e3578eb35',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'b8e2c11b-7e6b-49b0-8eea-0376627b6178',
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'fb607e47-e57a-4313-833f-b7e0aef3d75e',
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '74f972d4-4368-4cc9-b3aa-62fecb98f1d0',
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'dcf08256-dd5b-4314-8098-a772f59775b7',
  'e896524c-9420-4f17-9122-bfbe510aafa4',
  'received',
  'Migration Import',
  NULL,
  '2026-01-03 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'e7b09fad-b0d7-45b5-88eb-db9d40775382',
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '1f061925-1780-4edf-a8b4-442732a3ee29',
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'e898fc49-5179-4b0a-be88-c78b16330c56',
  'f9f7d34f-9c4e-4901-a833-f73eba892121',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '80358ba9-17c6-40c8-a469-0890ac95ae11',
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'cba5ccdb-92f9-416d-bc85-fb93dc31bbf3',
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '94903e12-c5ec-4b9b-b26f-f8b18064bca3',
  'cdba7002-d7df-452a-99c8-1dda7e45b215',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'de15a1bd-9bbc-4b52-b6f0-9777c1f1def0',
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'b1b042c9-a460-405f-a6c9-17d47621397e',
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ffb9d0f1-188b-4fc3-b44d-9432f06215be',
  '2f9d1d46-6fa4-48fe-b0bc-d6d978184b39',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'dce87b73-a942-482c-a834-52525036bdb9',
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c5bed944-dde5-4c45-8882-4045f932d1db',
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '775e613a-49a4-4db1-8ac5-60fab14f0c87',
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'b1043249-b1f3-4900-9365-ba46c1e74004',
  'bc4be049-2612-4432-81df-bc33aad91ff7',
  'received',
  'Migration Import',
  NULL,
  '2026-01-03 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '1b5c31aa-e559-4d2f-ac4a-e585abf292d4',
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-03 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'a3c0059a-66ac-4b9b-9a80-251db975ffac',
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-03 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '89f31636-e601-4be2-8306-5fe3c831aa71',
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-03 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '782a712f-8eec-470d-94d3-a84ce0ec3e34',
  '95cbcfca-5c92-4c2f-b93f-4ba06138e14a',
  'received',
  'Migration Import',
  NULL,
  '2026-01-03 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '2afc839f-8d0c-4ba3-91b0-1e046b8e9db4',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '6d75c342-2b8e-4701-872e-a88f2a6eccd0',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '64ff856e-0fe1-4dd8-b1c2-99b84c3702d5',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '67e08f9d-8f16-4cd3-ad32-ec04bbbe90d3',
  '93032968-c3f1-4ecd-952c-d8bae61f0041',
  'received',
  'Migration Import',
  NULL,
  '2026-01-04 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'da10709f-d4a5-4f9f-b2b0-45f0e00a478a',
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '85e96ba4-1f1b-4936-b4a4-df1c46e229a5',
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '9c971a0a-bf9a-4cb9-ab4a-c0bdfc851dac',
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'b6fb707e-0774-4e79-acb6-53b179ecb341',
  '28c30430-efaf-4297-9ff8-d085d8809edd',
  'received',
  'Migration Import',
  NULL,
  '2026-01-04 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '221f972c-6afb-488e-8423-5c5c322ada3c',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '1a9ea8d8-1b45-4118-b4f6-6ab1b1d7d62b',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ff57c5fd-5da1-46f5-b876-a90bcef06136',
  '936c746f-c41e-40d8-962d-427a8b0905dc',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c798b6cf-80c6-4abc-8d53-2778b6441191',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '2d807925-0125-4a57-899d-f883eae1e0f0',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '4bc88219-5025-4380-ac9e-6859550a7465',
  '30bb3c54-9f95-42b5-bc7b-66b7923aa571',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '06cb3b04-9fde-4b5a-835b-3dd374a7169b',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'bcfe6ce7-fcae-4226-98f0-1e611a2052fa',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ce7bd0e4-d476-4124-9170-e9a7f14b3ca7',
  '37a5e027-1096-46fb-bb38-7639e879a699',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ebee1827-f09d-4851-8620-cbc9ce31d5ac',
  'fd9ea6d4-6f9d-4716-8eaf-73678de9749c',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '1cfcd4b6-5056-4fe4-b432-b03b08a395fc',
  'fd9ea6d4-6f9d-4716-8eaf-73678de9749c',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '85de0c36-61c5-44c3-bae2-12da1fd31581',
  'fd9ea6d4-6f9d-4716-8eaf-73678de9749c',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '6a2d90e6-2b72-4e2c-be1f-a7142980ba68',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'cfa0eb9a-59af-4bfa-9721-f7cc9de6e326',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '7f01c548-344c-4b15-8331-9ce816842253',
  'baf18642-8d39-4d24-a385-29f60afccebb',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '7e68dacc-a175-43e6-96cc-7c06c710bc19',
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '5efac942-1a2c-48c3-838c-d2284967e428',
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'efb1d660-991a-40f7-8e3d-e34bb608ea7d',
  'bfb09e06-c740-4e93-8e3a-7fc1c9b080b3',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'faaf226c-ae5a-4277-b889-782d12655fbb',
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '06835819-d0c8-4a0e-9d10-40d6cb352efd',
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '892de0e4-bf33-4ae8-88b0-491ed1096990',
  '098ec4e8-2214-4fda-b089-629ed0d28f72',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'cfbb7428-9002-47d2-9f4b-4942f99ce815',
  '7f30ca80-817b-4bd6-ba14-b7c4979e69fd',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c82a3df3-a338-47f4-a7cf-704b1b1949a3',
  '7f30ca80-817b-4bd6-ba14-b7c4979e69fd',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '2c3170c2-57b3-41e3-84c7-868698f3da44',
  '7f30ca80-817b-4bd6-ba14-b7c4979e69fd',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '28250f0f-6da7-4138-bd1e-88fe0197c916',
  '875b6d3e-23c4-494c-8909-1696080c5534',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '4d056abc-b1c8-4523-983a-8b64db3331ba',
  '875b6d3e-23c4-494c-8909-1696080c5534',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'fb2d7b75-f3cb-45fe-838b-c8c3c618d7d9',
  '875b6d3e-23c4-494c-8909-1696080c5534',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'a1f3478a-2c6e-46d1-9d4d-3d839e3425e6',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ec115493-c11f-4494-a8fd-1f32282aa6e3',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '65916111-9ed1-4923-9ac2-702c5d63a147',
  'bdd0e18b-5959-4f00-9990-f46ebc383430',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '6cc44123-73d9-48d2-b850-2e702a898177',
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'b922e98e-6b74-436a-b63c-a53aeb719f1b',
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'bb2fadaa-a504-4619-bff9-8c7b5978c0f0',
  '0f186813-675b-4286-9c3f-c15cb258a3e8',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ddeb920a-55a8-4bf2-93d7-b4d8e3cc6618',
  '6569e083-1a87-414a-bc45-63fbdb8276bc',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'a738368a-1425-455d-91a8-69637b15e308',
  '6569e083-1a87-414a-bc45-63fbdb8276bc',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'fa04d203-778d-4bd7-918f-0b976219bd7a',
  '6569e083-1a87-414a-bc45-63fbdb8276bc',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'ab3a1d0a-39eb-4ae8-b4c4-a233e4a2a3fb',
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '7a46faf8-b0a3-437a-ad20-fddd23b3472c',
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '9e935896-4c1c-4664-9653-84f0d1ca9e5f',
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '71b06132-6170-4bdc-b339-d6c1a735a7b2',
  '840dfcee-eb4c-45ff-83bc-c8a1d6330807',
  'received',
  'Migration Import',
  NULL,
  '2026-01-04 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '209de71a-f181-4599-9cb2-dc710feed327',
  '7a2cdc75-b35a-40e8-8110-039963d99857',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'e15a108a-cab5-4bba-9ad6-603f3bf8a280',
  '7a2cdc75-b35a-40e8-8110-039963d99857',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '43faf8c1-bf9f-4aed-a631-d638d99e39f5',
  '7a2cdc75-b35a-40e8-8110-039963d99857',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '38696d4f-bdb3-4c58-88d5-9c8d89fd1494',
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '3b4f0472-440f-4136-afca-f900ff53901b',
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'bd037c63-9220-4260-ac3a-8cd275ae9757',
  'abb77baa-76a3-43a3-ac1f-9c554e2839bf',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '4eaa3d2f-2949-47a4-8506-93cd029a4641',
  '60548ae5-82fc-41ed-92d9-f48fb8912977',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '4f47d8e9-8731-49e3-b05a-e4d62dabe9cd',
  '60548ae5-82fc-41ed-92d9-f48fb8912977',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'cc0a4a10-76a2-4a90-a569-88078b1d5f3b',
  '60548ae5-82fc-41ed-92d9-f48fb8912977',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '51376391-c924-4816-ae7d-d3f392b30685',
  '02e829f0-e607-47f7-8eb7-5cf1d93ab616',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '3cba90e0-57dd-4880-9629-343ef456e29d',
  '02e829f0-e607-47f7-8eb7-5cf1d93ab616',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '4c5b55e7-1633-431f-b7fb-96e9961047a2',
  '02e829f0-e607-47f7-8eb7-5cf1d93ab616',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'f54cb177-90aa-4d02-9649-35fc7e71a578',
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '478cdd54-bfaa-44f2-b923-d1a3ff3d760e',
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'dc2047d5-0634-4382-8dbc-d4820d99abcc',
  '9d9ef0a2-adc7-4b33-a11f-891b882d1412',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'cffe0271-a022-4b79-923e-666bf468b40c',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '3ad795cb-55e2-4070-bd3b-301dab99013a',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'd1b39474-e943-4844-aaa4-e26b08991b61',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c442f410-3ad1-4fb1-89dc-4e47485c0786',
  '9be6dc6f-f2af-4048-910e-5a37cba38af3',
  'received',
  'Migration Import',
  NULL,
  '2026-01-04 09:15:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '29d26feb-6a79-49ae-ab27-4e4496c994c1',
  '08b61ef7-5428-4670-afb8-905fb7ff9301',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '882a5688-46de-411a-82e0-064f356c1fb6',
  '08b61ef7-5428-4670-afb8-905fb7ff9301',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'fca7ada4-e6d0-48b2-a36e-ba289c588dab',
  '08b61ef7-5428-4670-afb8-905fb7ff9301',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '960fd22e-7b83-43fd-8edf-274d6c08daa3',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '591f9a4a-5df4-4b52-8569-0a0cca8ca2ad',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '56b96944-528e-41d7-96b6-5757e97aa931',
  '8f01a1ec-e222-4805-8695-e691ab60a7d2',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '71498a1f-204c-4862-82db-8d4c3bc459ae',
  'de9a3c5f-a818-419e-8506-544eb8d2867d',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '0f705570-35b3-46b2-8655-dc8e6f8ba42c',
  'de9a3c5f-a818-419e-8506-544eb8d2867d',
  'approved',
  'Migration Import',
  NULL,
  '2026-01-04 09:05:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  'c1432473-dda4-4de9-a682-690e06c2ea91',
  'de9a3c5f-a818-419e-8506-544eb8d2867d',
  'collected',
  'Migration Import',
  NULL,
  '2026-01-04 09:10:00+00'
);

INSERT INTO order_status_log (id, order_id, status, changed_by_name, reason, created_at)
VALUES (
  '75fc7d4c-9920-4a10-8c86-60e38dad2efd',
  'edc3c126-5e94-4baf-a27b-e7d0d5bf8b0e',
  'submitted',
  'Migration Import',
  'Migrated from external platform (batch 2)',
  '2026-01-04 09:00:00+00'
);

COMMIT;