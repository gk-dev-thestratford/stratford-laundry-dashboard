BEGIN;

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '102dd343-a05e-431b-9f86-859634eee77c',
  '8f680c13-3ed2-4a97-bba0-163cc9fa78f3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5bfbb69c-b164-4dfd-8fd1-55de5a53d786',
  '307fa696-3438-40b6-8f5a-e10ffc7c1d61',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  94,
  94,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1f2ecd45-2d58-4773-8ee7-5ea445cae391',
  '70097900-b669-47dc-882d-72ca848b9d46',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  108,
  108,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7cad1611-f7ce-4f79-84e5-f27413feb72e',
  'efdaf5f6-3d84-40e0-9a1e-5b7d66fd94e2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5a2ce8fd-1dd7-4513-9745-b6f27552de1f',
  'bfdb7313-f425-4b81-81b5-1d4fbce7fcb1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b1f98f08-487c-48a8-83e8-8c0be613ea67',
  'bfdb7313-f425-4b81-81b5-1d4fbce7fcb1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ae157b70-411a-4da3-b76a-32d571b003ea',
  '13f11513-9de2-4fc0-976b-96df0c4a4f66',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '44cc9f73-3a13-42b6-af08-17aa621b7436',
  '13f11513-9de2-4fc0-976b-96df0c4a4f66',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '670420a6-76b5-41eb-9ebf-6000ad7a7055',
  '0bfdcc9c-8e67-4abc-b601-9aa6d2362f79',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  8,
  8,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '079ae032-48e6-49cd-9653-6136ae03f577',
  '00b85dfd-7041-40d3-9ee0-8b59ef384fbb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e2a1b9f3-c766-4cbe-a9fd-2d2d34aae659',
  '00b85dfd-7041-40d3-9ee0-8b59ef384fbb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb7e4453-ce06-40c2-b6d0-a3e107433680',
  'a4a11a01-7bb5-4128-8769-a0b74953f06a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f0ba12e-9e0b-4333-a6a3-e51412c24276',
  'a4a11a01-7bb5-4128-8769-a0b74953f06a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ae32019e-cdd6-4800-b349-f9fdc8cf7b25',
  '7b27c509-c392-411d-a21f-91bfcbdbb3ea',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  46,
  46,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd5430b79-1fb0-4e1b-88ac-7b111077371b',
  '15d750ed-f089-4a55-afb3-a7adcc7a4013',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'accffdc4-c446-49a0-93b5-552443c0ad27',
  '15d750ed-f089-4a55-afb3-a7adcc7a4013',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4300b6f8-22ac-4fc3-81f4-15d6064fec25',
  '15d750ed-f089-4a55-afb3-a7adcc7a4013',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '477391a6-16db-42d4-a080-135d53f5c5a7',
  'fb013187-95c1-4945-adc8-20a3151ccecb',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  64,
  64,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '963418aa-af95-45bc-8849-d244acfde794',
  'f9afb3cf-348e-4936-8ca3-a400c8b460ee',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd465c932-7862-49d6-b230-622bf731ee10',
  '4ca6b4c2-d25b-4e3c-83ed-9593d5946406',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '79c99fe6-7862-43c5-bd72-5c81dc35f919',
  '4ca6b4c2-d25b-4e3c-83ed-9593d5946406',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '587abf66-699a-435c-8910-b900ae40414c',
  'f6b5443f-5eae-4704-8f9d-36c1bb2f01ec',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '88a7c5aa-8a36-40a8-a3be-9567e4f7b75c',
  'f6b5443f-5eae-4704-8f9d-36c1bb2f01ec',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'add851c6-3fd5-4b0c-a198-55ebcef815c5',
  'f6b5443f-5eae-4704-8f9d-36c1bb2f01ec',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fbd23b17-2944-489e-af43-028b9b63ab35',
  '628b8395-d324-4950-9acd-1f364eac5af5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '09fcdb65-b47b-49b0-a513-c7064ec4f1d5',
  '628b8395-d324-4950-9acd-1f364eac5af5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c05fd6ce-f1d4-4a2a-ac60-003349e9c156',
  'e58adc67-3dcd-4b73-b5e5-9dc599c1968e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fb1f88f5-ed14-42bc-89d5-8544d97ddc43',
  'e58adc67-3dcd-4b73-b5e5-9dc599c1968e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ed27edc4-3efa-4130-8db1-117f794036a8',
  '1b97f69b-fd05-42a0-8778-8a4c36e5d7b2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ba7ea879-1b7e-49b1-97b8-471e0a3e7b7e',
  '1b97f69b-fd05-42a0-8778-8a4c36e5d7b2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fad019be-e810-4647-98b6-d83b86533b3f',
  '1b97f69b-fd05-42a0-8778-8a4c36e5d7b2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a862d359-5581-40d1-96e6-32272ceb632e',
  'addff0f8-768f-4b47-b436-2c51f5c35c3d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eeff4815-e3fb-4235-8224-42c9477060cd',
  'addff0f8-768f-4b47-b436-2c51f5c35c3d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a5e84121-f863-475d-9ebf-9a894d45e027',
  'addff0f8-768f-4b47-b436-2c51f5c35c3d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5cbd4e69-c615-4627-846c-434b31ff96e4',
  '1516c5ca-3507-42fe-96e7-c2eb3d211f3c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '38c91553-ab44-4702-acec-76724471e057',
  '1516c5ca-3507-42fe-96e7-c2eb3d211f3c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '57eee3e4-a15d-4f18-9206-f3fda6d3ea7a',
  'c0a98779-c59e-4198-ba59-c06eff5ff9b6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c2f3c0a7-e1be-4465-b7fb-6c1c032eb803',
  '8d73bced-1bd7-4258-a0e5-e57b8aa82d2f',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  7,
  7,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e8b1696b-b849-4a4b-bc43-5c7d1656b7ce',
  '1911c51d-f062-4329-9696-10748193f63f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '89294037-2c74-428f-94cb-6b68fcb4ac6c',
  '1911c51d-f062-4329-9696-10748193f63f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1dc6dc97-bbe3-4378-a27a-3c8b23a7db8a',
  '591beda2-0796-4145-a512-1e1915d26805',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8c549af7-49a1-4042-8eca-1d324efd4dd8',
  '591beda2-0796-4145-a512-1e1915d26805',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a9d08d97-2989-4eee-9ad3-9b266776308a',
  '8610b155-b355-4607-8315-f0bb3a2f9788',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  3,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '80b4f339-5bbd-4fc7-9db9-156180b0abee',
  '8610b155-b355-4607-8315-f0bb3a2f9788',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  3,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ba1af052-6cbe-4ad1-a4dd-4561a4f30dba',
  '9d1f57eb-c4cb-473b-a329-3a15643e07e0',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  75,
  75,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3f1e2b87-b5ad-49f5-8775-95e1ad0eea79',
  'ab174232-2993-42ea-97f3-b79ea5e75ba4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  155,
  155,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'acb7d5b1-1233-4a59-b9a9-30cb588923e1',
  'e2e56841-d11d-4f97-a46f-d2a215b02e36',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5562964f-e50c-4130-9d6d-3dbb0a95cd46',
  'c4656d0c-53b3-4cbe-8b5c-89171df99eeb',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3932d16b-9e1e-4c51-84f6-714895ce3e7e',
  '2fe85571-05fb-4db1-923a-aaf9362568ed',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  72,
  72,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3247d2c8-5dd4-47c8-a7c7-6a7cbc64319e',
  '0aac4863-87b3-4d18-b1c9-cf3a74ba3651',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1c6aee6d-1de1-4c8b-b42b-d35354173327',
  '0aac4863-87b3-4d18-b1c9-cf3a74ba3651',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ef02596d-1dfd-4644-ade9-3cb33b3d3bd6',
  'd3b4629b-8bbb-4ff6-8d7f-bdfaa81ea77d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  2,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '28e36122-87e2-4b2f-b423-bdc995b75456',
  '01e6b29c-bf6d-40ea-9894-1b931cc5fceb',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b92f652-061b-487b-99f8-2c4d9404fde6',
  'f728fb0c-d15e-45b3-9ee7-2babea5ef32b',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  43,
  43,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f9b39ab5-6ec8-4e97-9063-e4e3860847a2',
  '568d9b19-b019-4b26-b147-cf6b46cafcc4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4352f9c5-ede7-4fe6-8b66-94a8313b9241',
  '568d9b19-b019-4b26-b147-cf6b46cafcc4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9dd15b0-1dda-45a0-abb6-d1584c120144',
  '7b5494ba-fdfa-4383-8a9b-ad88131c7b99',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dd804b4f-0a8c-44a7-8289-0e157831aebc',
  '7b5494ba-fdfa-4383-8a9b-ad88131c7b99',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'db242b7a-46da-41c4-8b6a-9801a6794345',
  '7b5494ba-fdfa-4383-8a9b-ad88131c7b99',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4115c51a-27ab-4adb-a37d-91d7655b986d',
  '737d257e-7990-41e2-bcb3-f7b7c92a6e59',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '731a9035-9d63-47a4-978d-3a9197593c68',
  '737d257e-7990-41e2-bcb3-f7b7c92a6e59',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bd73345b-3de2-4238-ad12-6ac5ac9d1c68',
  '9d0b6d70-9258-4115-ae86-73b007c112ae',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  1,
  1,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7c56d757-7b72-4f47-8dbd-93064302f0e7',
  '7441afb8-f6bb-4d40-92ff-03d8a15fa733',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  50,
  50,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f1517400-068f-4938-9cc4-1d347094c467',
  '8a30c456-d943-4d3e-8d55-2e0675ae9130',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd1c2f6d2-707a-4a39-bb62-b79ef3752409',
  '281e69b8-d44c-44b4-8594-db26dbd09286',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '47e06b53-3418-4492-bc1d-653a4a6577ca',
  '281e69b8-d44c-44b4-8594-db26dbd09286',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '81d1ed0c-4aa6-40ff-a2eb-5d3d0ac455c3',
  '281e69b8-d44c-44b4-8594-db26dbd09286',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  3,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7abb20e2-d3d7-4ca2-8885-92ce6491d8e8',
  'acebc1bf-9b74-4194-9f0b-5ad730612682',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '00afd90c-4cb6-49ba-aae0-2b75c2025ebb',
  '1904b7cf-fa6f-47e6-a903-4e109433d4ed',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ed4d60e7-97c8-4bd2-97c3-fb44366b6199',
  'e10b25da-5a07-4fe2-948d-7a3a0418e1c0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a785acc-8552-4484-ad92-c6986e2b8c78',
  'e10b25da-5a07-4fe2-948d-7a3a0418e1c0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '03cf12b5-5ed1-4f07-afde-5b0ecf635d6b',
  '525f28e6-cf9b-445d-8919-83b25bc54d19',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '07ad57a5-0ebf-4ab4-bf7a-43fb563b5c08',
  '525f28e6-cf9b-445d-8919-83b25bc54d19',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e6213daa-31cf-413a-887a-c3105025d66c',
  'b80bc694-548d-44f9-85bd-83735259ad43',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '26d105ca-b347-429d-beeb-e2e2b3baccb6',
  'b80bc694-548d-44f9-85bd-83735259ad43',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd32c87e9-e467-4ec1-bb8b-b391207f0836',
  'b80bc694-548d-44f9-85bd-83735259ad43',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2a977fd8-dd30-4060-b73a-1214eb69e035',
  '2603afbb-e6ae-48e8-940b-4b7ec04aa8e4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '00edde4c-187a-42d5-95f9-592647360d2e',
  '2603afbb-e6ae-48e8-940b-4b7ec04aa8e4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ee058cd8-5d54-4334-8f90-bbdfdbdacb92',
  'd1545539-eaf5-4933-8954-2268874e120d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '438a22fe-5fb0-4640-98c4-2629586b0772',
  '4ca1c41a-ba14-4876-99f9-76946619b9ef',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  7,
  7,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f31319b5-a48e-4919-add4-31807cb4c61b',
  'ed0765a7-0a8f-4619-bb19-3bc1fb6543cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2e0c09ed-a1bb-4781-84dd-c6a469058797',
  'ed0765a7-0a8f-4619-bb19-3bc1fb6543cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f5f9da0f-0541-4d5d-a902-c4ee0d382ca5',
  'ed0765a7-0a8f-4619-bb19-3bc1fb6543cc',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  2,
  NULL,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '65ad212d-b506-445f-8d03-8d3df8af5e93',
  'e6ae8e06-77b5-4eca-893d-a18549cf97d3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9d8a4154-47ca-4bca-8851-67bcf7852e57',
  'e6ae8e06-77b5-4eca-893d-a18549cf97d3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4bd188fc-8e9f-46ec-968e-c16d18b642f6',
  '0dd667c0-6881-486c-9039-55f3256bba97',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  60,
  60,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f6d90b72-0e97-4382-b1ff-9839171825cd',
  '73403f52-545e-4821-95ca-ec89f8b03aad',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  80,
  80,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dfbb650a-d53c-49c5-bd33-6d632ed4a7a7',
  'd2555f02-9be5-416c-9385-c05ec8a969af',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1ed1efa5-ba53-437f-977f-5c5f71a75ced',
  '6520a462-9032-4859-9ac5-d972acbc3e73',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7d431d5b-4402-47bd-972d-ba50bafb7be3',
  '6520a462-9032-4859-9ac5-d972acbc3e73',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b47bdd7c-5939-4707-a461-36df544b57dc',
  '6520a462-9032-4859-9ac5-d972acbc3e73',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eda6bf04-9634-407c-a887-a557c61ff7b0',
  '7d1a5616-8e8c-4e0c-a96d-b75b1506b5cf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '737cba75-7f2f-4029-8313-e514bbd074c5',
  '7d1a5616-8e8c-4e0c-a96d-b75b1506b5cf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'da4b2842-7d0f-4b2c-ac3a-9280b958488a',
  '7d1a5616-8e8c-4e0c-a96d-b75b1506b5cf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ffc9042e-f7b1-4990-b251-d8feba192357',
  '5425f741-aad5-4b4f-8433-ef901f21bc5c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ca6e1f57-5a9b-4adf-8618-e80d2a053eaa',
  '85295bb7-9b21-46d8-9217-15c65f68fd96',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  2,
  2,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c4045810-1843-4da3-8e0c-122fadb098dd',
  'ce2c9d30-8caf-4153-ac86-d4038042ea98',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  3,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e3a604c9-855e-4d2a-ab74-b3ca0fa01a99',
  'ce2c9d30-8caf-4153-ac86-d4038042ea98',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ec5c8d2c-2251-4b5e-8ed1-d70a1c996d64',
  'ce2c9d30-8caf-4153-ac86-d4038042ea98',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '65a82945-92ed-4031-b8b7-7e4645494b7b',
  'f9179897-526c-4542-aa5f-a7b602077a1a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f069a837-6439-4cee-8e0f-a91e75844316',
  'f9179897-526c-4542-aa5f-a7b602077a1a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5d86efe0-cfef-48d8-b971-f3640edf9739',
  '8c771f29-cb2e-4cb8-bb3c-1817c0ee2cfe',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '984fd69d-acd8-4f52-8648-32583b07f35f',
  'b3a38e4c-0665-4add-9055-cfc2cc07dcee',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '891d3a8d-6e83-4e07-b719-6fb76e7158a5',
  'b3a38e4c-0665-4add-9055-cfc2cc07dcee',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '465d0b50-2c0d-494e-8d00-77a92e9dde1d',
  'b3a38e4c-0665-4add-9055-cfc2cc07dcee',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a1183fb8-8b02-476e-bf9f-25f2d7a58f3b',
  '5a849b95-4b70-435d-97bb-4e5513550c93',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  66,
  66,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7eeb9c0e-8df3-445a-a2ce-d067860d57d1',
  '1ed2fc30-1786-4395-8449-b133b83be456',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  110,
  110,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '51b064c5-be42-44de-ad92-b4b10409eea0',
  'bef4ffaf-4c81-408a-9f8d-f8331a9f0add',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-004'),
  'Dress',
  1,
  NULL,
  5.5
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '955e0402-e141-4f2e-bc40-6edc49e1971d',
  'bef4ffaf-4c81-408a-9f8d-f8331a9f0add',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '48c61d94-7cd8-42fc-972b-524ed9d9bc27',
  'bef4ffaf-4c81-408a-9f8d-f8331a9f0add',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2ba39dd5-ac73-4a3c-ba8f-e3fdb8168ac7',
  '884672b3-6779-4173-a462-b2b179bad68b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0caba825-4434-488e-853f-0799608eb4e8',
  '272860b2-03b8-4945-a3de-833fbca8d6c5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3adb219e-d275-4fb1-b766-5a93c8b11ce2',
  '272860b2-03b8-4945-a3de-833fbca8d6c5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c06a43b5-4eb0-433e-87d6-62a0ba33e4fc',
  '272860b2-03b8-4945-a3de-833fbca8d6c5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1b18f380-b707-4acc-aae2-4ebb4e43de38',
  '770656b5-b1c8-45cc-85b3-38b21a55e679',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '31730b60-9a8e-46cb-9bc7-39638b169f2d',
  '770656b5-b1c8-45cc-85b3-38b21a55e679',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '083bb090-f662-4752-b699-ce7a99c8e905',
  '770656b5-b1c8-45cc-85b3-38b21a55e679',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a5236b0b-4a10-47d4-a6b4-9f1cda862bbf',
  '1d3dcd24-38c3-4ad4-ae0b-a4e9eea77053',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd5c10249-b334-4055-8126-407707fc0333',
  '1d3dcd24-38c3-4ad4-ae0b-a4e9eea77053',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1841a0e-6b46-4195-9613-c52bbb3f5eb5',
  'f4bc525b-6609-434b-abd0-ff8d41bba031',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  95,
  95,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd35fcfe9-e2b5-4c54-823f-2d48e1fb3846',
  '82658737-8136-470f-b236-a927c851b6af',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '97e97274-3d30-4714-8b04-8ae7dc250b2a',
  '82658737-8136-470f-b236-a927c851b6af',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fbcc05af-071d-45e7-9970-5c6cb3d0c1ef',
  'c3f68dfb-3d8a-49e0-9744-530b990e428a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '780f062f-20f4-49a6-af37-3ea00405384d',
  'c3f68dfb-3d8a-49e0-9744-530b990e428a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  3,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b4b6d514-0b2e-4810-a186-8681928a02cf',
  'c3f68dfb-3d8a-49e0-9744-530b990e428a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b8281e35-63a2-45c9-894c-af002b48ac05',
  'c57a1a45-3b02-4bdb-92d7-f5049abb505e',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  4,
  4,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0c2108ad-c433-4cbd-b000-a8d0513902b2',
  'c9e5d618-f4cf-44cc-8884-7d6ed549c182',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e821dc1b-14d2-4052-92c9-88fcf7f6bfef',
  'c9e5d618-f4cf-44cc-8884-7d6ed549c182',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '85859d72-4f8c-4711-8045-df431d9b19ee',
  '25c2516e-d992-41b1-aece-92cc333c6714',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  36,
  36,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4736b511-f999-4c2c-8a84-058a4d3f2e99',
  '62a2b4c6-997a-4762-929a-309fc6f23061',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0cc58197-02c0-460d-96ac-a4257efce2dc',
  '62a2b4c6-997a-4762-929a-309fc6f23061',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ace37e34-a865-4605-8c1a-7534fd8d7e3a',
  '62a2b4c6-997a-4762-929a-309fc6f23061',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7584dc35-998c-4dbb-8589-42875b7e35b1',
  '34a620fd-d20c-4bbd-a031-e252b426abd8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  24,
  24,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '778ee25e-391a-41a2-a8e3-8056ebd6fa24',
  '34a620fd-d20c-4bbd-a031-e252b426abd8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '712414ed-088d-4c3a-a16d-5e75a8515954',
  '34a620fd-d20c-4bbd-a031-e252b426abd8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  3,
  3,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '40133b8d-e1e2-46de-9c5c-af8f86dc32cb',
  '008ee3d9-7691-49fd-8a16-bc7815d353e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '089fe97e-20c1-477b-acb9-078b87bd1eaa',
  'eef12bb2-82c1-4b20-991e-667f52e76b02',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  79,
  79,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '61a51deb-c925-4b9c-9c7e-7bd9cc2dc810',
  'd729a1f6-721d-4e0a-a777-97201d28ac82',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1ff240b3-3fae-407f-b54c-d255d18a87bf',
  'd729a1f6-721d-4e0a-a777-97201d28ac82',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4d5f205d-15d1-4a2e-8925-8f9e809a8118',
  'd0ef4358-0dcd-4a32-9ef3-54fb25712f81',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0ec7a1b6-8c23-45b4-a2dd-d73817ac1a6f',
  'd0ef4358-0dcd-4a32-9ef3-54fb25712f81',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b1234da0-c88d-422d-879e-7a5f0d5ea31b',
  '27fac6ca-cea0-407f-88b8-5b337b4aecc7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'afa4b55c-0b37-4fa7-9a9b-5d06486620d4',
  '8277a628-2749-4dd4-9fb7-744d769b8e23',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '688cceef-10d5-49ee-b3de-a8a3c7994461',
  '8277a628-2749-4dd4-9fb7-744d769b8e23',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e01eb195-5075-434a-a8b9-7ce9f21523cb',
  'c2512381-1db2-4aca-8da5-12b684a261e2',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  6,
  6,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a833b327-e6fb-410d-b5ef-64870961dec0',
  '34f34676-4bab-48c2-8030-149ba7b65e2a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dce06327-901c-4fb8-a970-17acdd2b62b6',
  '34f34676-4bab-48c2-8030-149ba7b65e2a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6af2d445-6586-4df5-8a57-14e7ac2ec6ed',
  'f967790e-5d97-4a5b-acca-266eaa280f12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8d6097a5-d949-4f97-9ca7-d0b96b4ced20',
  'f967790e-5d97-4a5b-acca-266eaa280f12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4405cb40-8eb0-4508-8632-d2a0ed74116b',
  '21bd48a2-9e0b-42d0-b03d-10f26dbc1440',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd3450297-69cd-4e71-a626-7531126c288b',
  '21bd48a2-9e0b-42d0-b03d-10f26dbc1440',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4fc52a2a-4e8d-4bd6-821b-65da5097ac21',
  '4f36ec2c-ba0e-4026-a1ca-c7b94d37c0d5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4fb70716-8b91-47c1-8d34-e75c7bb491ab',
  '4f36ec2c-ba0e-4026-a1ca-c7b94d37c0d5',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6c03cf10-4996-4f79-bbf1-b4e1877b3a05',
  '61f1ffa7-da96-4ada-b60e-2a35fc0d32a3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ce8326a8-230e-440f-8a91-d2727effc2cb',
  'e4018529-d879-4107-9d22-d82a36d4fb09',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  34,
  34,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a6e5495b-27b1-43b2-ab38-e08112332ab0',
  '41b5e489-3124-4850-b4f3-66483a64c92f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '44b1bcd7-e64c-4871-b011-1e97fc517b87',
  '41b5e489-3124-4850-b4f3-66483a64c92f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9063165-2b80-4f02-9ae5-ec891a439617',
  '9b9e029f-61d5-41f0-9b1f-c6dba3909aac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'af2be7a2-78d0-46d0-bc65-caf0c2266926',
  '9b9e029f-61d5-41f0-9b1f-c6dba3909aac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8409207b-0433-4239-841a-4de4ea90932e',
  '9b9e029f-61d5-41f0-9b1f-c6dba3909aac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '105e7641-8539-47cc-98fc-1802e42dc846',
  '5e746359-708b-46b6-aa6c-6f742745449b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9b2f01dd-9302-4646-8652-f2203c2f12e4',
  '5e746359-708b-46b6-aa6c-6f742745449b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2731c393-967b-4e9b-b09c-89935fd73e2f',
  '5e746359-708b-46b6-aa6c-6f742745449b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'aee15027-186f-4664-9047-550ef4cba2ff',
  '9f2974be-d42f-485f-bed6-315545c5a590',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  25,
  25,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '910c3af7-ec44-4982-8c91-2ccba6e18afe',
  '22dc5515-e738-4a2d-adfe-5abf7ac3a016',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  71,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a77e8b7f-8a61-4408-9ad7-4b9579213147',
  'b211720a-bc37-466e-afa9-d112de2d0a11',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  132,
  132,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a0ea2fb2-94db-4f60-adcf-d994942aec26',
  '37b6edba-5fd6-4c55-a3ad-9642ef4e9f2c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  10,
  10,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '98f0b784-769f-4659-96ee-ef4a54f9d939',
  '93318d52-ddfb-433e-b8a8-e2deb82cff68',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  6,
  6,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '912b19db-ff9a-46ec-a1f8-3b7a3940cbd6',
  'cdec3e87-1e37-47f5-b621-ed4373b54d4f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '074029e6-d5f6-4310-887c-d4bfdcddb58a',
  'cdec3e87-1e37-47f5-b621-ed4373b54d4f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c7f6a7ea-dc9a-4d16-8662-aafc6d98eff2',
  '9066c278-b87b-49d4-beb9-45710d441faa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  6,
  6,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '36a4bd2a-66f8-4b45-9674-08949e89bbe3',
  '9307e4ee-87f9-4c67-aafb-ec4f6654685b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd8c13d4c-9a9c-4316-8b86-a86ba31129f1',
  '9307e4ee-87f9-4c67-aafb-ec4f6654685b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6aa5661b-76fb-4da4-967e-89217811d0e0',
  '9bc804b2-448d-4e35-870b-11ae9f43ccd6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1e1020cb-73cd-47ed-9330-fc9a182fcafe',
  '9bc804b2-448d-4e35-870b-11ae9f43ccd6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3f01a3ca-0460-4e1d-9ff5-96ac8b42e49c',
  'a8f58bed-634a-421d-89a4-8606473aca70',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5789a5be-611e-44a6-92ee-05b7eb5b74ed',
  '0f272cca-0737-4f94-938f-12b5c03f22bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '13bf6a48-65e5-4865-bd79-a231200064a2',
  '0f272cca-0737-4f94-938f-12b5c03f22bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ca78f2ec-0512-446e-8888-68e421ef72e7',
  '0f272cca-0737-4f94-938f-12b5c03f22bb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '224afc7e-3fa4-497b-a267-68013366c3cb',
  'e4b08853-e737-48ba-bba3-cc2623560e31',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0a650a3c-9fab-4257-a929-0ffa85871007',
  'f1eb4ba3-9f41-4cfd-9870-4e2bcaa264f5',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  9,
  9,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1608c67-667e-48a6-8f55-054f40a1194c',
  'f8559b53-727b-4efb-bd27-1133f3f555b0',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  67,
  67,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '099a01c4-4738-403f-960f-4c71cd54dbde',
  'e44c34a1-dc8a-44bb-a2d6-84bd86307874',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  104,
  104,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3e5c8bf0-2477-4ea2-bf24-6e2afea62aef',
  'bc6c5187-4004-4bcb-bd86-5c787d840b20',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  2,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ac43bab9-4d9a-49c6-9cdc-0fb6322c20af',
  'bc6c5187-4004-4bcb-bd86-5c787d840b20',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f7c600e1-f70e-44a1-aec1-b07f9be96766',
  '886bebcf-552a-42b7-96f7-d7c16d4f865c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2042e248-f0d0-43e1-b0b0-cd2ffb2bb6b6',
  '886bebcf-552a-42b7-96f7-d7c16d4f865c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4c83a5ac-6975-4ae0-89d0-29e94da4243f',
  'cb38c97f-de4e-47de-a8b5-d7e52670a0ac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e2495e83-4913-497e-960e-f00396df6ec5',
  'cb38c97f-de4e-47de-a8b5-d7e52670a0ac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6da026ad-bfe6-4705-aa28-00484d5ad55a',
  'cb38c97f-de4e-47de-a8b5-d7e52670a0ac',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5f5c0ee7-1350-48d8-99c1-fb2d98867984',
  'b492540d-8258-40db-93b1-7d0e70b9fcb1',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  122,
  122,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3c116dc8-a691-4e45-8967-93b7a4f77d50',
  '5a462bf4-d18a-4232-9afd-d9f819f8ed24',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1b99637f-1354-42fc-9f6c-c40a7e32fb67',
  '24f4bdfe-143f-4618-93f2-366981e8ab1a',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  24,
  24,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b19a7f2-51a0-4495-a005-ac5480fe6a87',
  '7ee6a0f1-a947-45ef-a3fa-2e28e18857cb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e2bceeca-8de8-46f0-9497-b02219a66d76',
  '7ee6a0f1-a947-45ef-a3fa-2e28e18857cb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '57529c46-e5bb-4899-861a-96dda97c623b',
  'e9672670-bac9-4192-8c75-16c88afd25fb',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '65d6d2f1-21d2-458e-b038-0739b1e751e0',
  'cf9b0842-01f4-4d95-a284-7245b7139c53',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  11,
  11,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '88b11359-4aa3-438b-b0b5-edc05cb83adc',
  'b5558d15-e61c-4fab-929f-248f520af625',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9d0f95d2-bb8d-46a9-924c-3f99239d0fec',
  'b5558d15-e61c-4fab-929f-248f520af625',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '32032a6d-e4ea-44c8-bf38-c96bcb824dfa',
  'bd355676-7049-4e12-bbca-5dc08595f954',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  47,
  47,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04c9d785-9d5b-425b-9038-44bd25a13861',
  '891af782-a045-4f99-97e5-5dea9776e753',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b20f6368-3aa3-4fbc-8f6d-f3c21e485579',
  '891af782-a045-4f99-97e5-5dea9776e753',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '19dab694-1b05-4f11-9719-a6333a23f870',
  '2e388104-b8ec-4ce9-8365-956cde79e282',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  44,
  44,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '707f7380-86dc-4638-a60e-191c0d37ebfe',
  'cac60ce1-baf4-42b8-81b5-185f5c2bd0c2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04ef6fea-54e6-4900-a7b3-51a8af1a90d2',
  'cac60ce1-baf4-42b8-81b5-185f5c2bd0c2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6bbb012c-586a-4548-8929-9599d366a3aa',
  'c7bda7da-08ae-47fe-ac0b-7701c57655c8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '45b5bb52-7a84-43a0-8aca-3080fc3cbb42',
  'c7bda7da-08ae-47fe-ac0b-7701c57655c8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b046f666-e902-4e58-beb0-80b6dc5abec0',
  'c7331ba8-7972-4065-acb2-f73563e37717',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fb7d3b49-1f93-459f-b52d-35aeb9386bef',
  'c7331ba8-7972-4065-acb2-f73563e37717',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f0508efb-ab44-4f6d-bd56-92a32eea8554',
  '32bf9265-26bb-40e6-baeb-ec8a555a8f38',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3605fabd-c7a2-423b-816f-3eb538033ddb',
  '76440663-d981-48aa-be2c-e586c9d66951',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd51edb10-eb7c-493e-8346-b4368a9146a6',
  '76440663-d981-48aa-be2c-e586c9d66951',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '19a88c5b-4d02-43ff-a28e-9a3c1f82cb85',
  '76440663-d981-48aa-be2c-e586c9d66951',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b3cf76d0-d260-4abf-8bb4-19df4ca4a12f',
  '00d4653f-4269-4ff6-b1ef-702c4c2d2e5a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '445379df-7a4d-4e80-9a21-f86304046000',
  '00d4653f-4269-4ff6-b1ef-702c4c2d2e5a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '438668bc-7417-46b8-867a-09fd5662cf66',
  '449c92bf-40d5-4f2e-aeb2-f8a78f0301d4',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  11,
  11,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a9ee85ac-8feb-4b6d-a51d-d92fea101708',
  'af82f79d-ead9-4849-950d-3848ecb32ab2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b627134-b368-4c60-920d-fc21054ae385',
  'af82f79d-ead9-4849-950d-3848ecb32ab2',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '768b7239-9300-41f0-874d-44c37fe36d16',
  'd0b248db-4dba-424a-93e6-1cda5360c70f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  3,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5001097f-52f7-4191-acf4-7dd2df1d8dd1',
  'd0b248db-4dba-424a-93e6-1cda5360c70f',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  3,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f322fca1-faed-43e9-8950-84704759ec5d',
  '2b65f36a-1250-43f2-afe8-e50636c21107',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '39bff8af-8957-4fdf-8b7d-73b575acf9de',
  '2b65f36a-1250-43f2-afe8-e50636c21107',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0eacf19e-9345-45db-a305-04a9d0790d4c',
  '2b65f36a-1250-43f2-afe8-e50636c21107',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '24a3bc81-f393-47c8-a986-f37f22fa8457',
  '8542de6e-b503-44fa-8dd0-fea042c10df6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '53688578-0708-475a-8961-f4a67931a327',
  '8542de6e-b503-44fa-8dd0-fea042c10df6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5c3cf21f-a290-4d3d-bb2c-c15f3d5219fd',
  '13785446-e432-4c8d-8d4c-95d302d524b1',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  76,
  76,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4060ed33-2e1c-4781-9154-eb051934c073',
  'f8f48095-5d1c-402d-9bf7-87622d8c4ee6',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  77,
  77,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '66fecda7-aa98-445c-918a-8a42d6d428d1',
  'dfa999fc-12e2-48e5-ba3d-85a2544b98d9',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a23de49b-24f8-406a-aa05-93163c451499',
  '15d93eed-7acc-4c8a-981d-cee5d3016525',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  4,
  4,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04c5e4b6-a371-4f3c-a10a-9d2d08e069f1',
  '7eb82445-2ee6-4588-bd9f-fa405e6251d0',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ffa4a923-56cb-4dd1-b213-f8fe77c13a11',
  '90d59488-4964-4fe5-b57a-b6da6c0ebcb7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '110d56f1-1964-4e88-8916-62c590e10fcd',
  '90d59488-4964-4fe5-b57a-b6da6c0ebcb7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f6dfdaa2-17a3-4c71-a1ea-ee17e83ec308',
  '90d59488-4964-4fe5-b57a-b6da6c0ebcb7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4e441e34-c691-4b90-88e5-da936aa4e31b',
  '428b1eb6-abd2-4743-941a-e73005e30e13',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '52d20594-5e32-400b-9428-4a337d9bc207',
  'c989a9c1-7c81-41e4-b27c-8f46d00b7cf8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8adaf111-b647-47a0-a2d0-29b09cfd5beb',
  'c989a9c1-7c81-41e4-b27c-8f46d00b7cf8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4c35fef6-5bed-496f-bb80-f93e1b4dbdec',
  'd3ac0cb4-5896-4dd8-82a9-88757c7c3452',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  4,
  4,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '044e30c3-4a2f-4ada-b4de-554db3ff6078',
  'cc33b37e-59cd-4812-b554-e8fc0b589268',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f2a4c37-4147-4a4c-87e3-ac3f4dc2a644',
  'cc33b37e-59cd-4812-b554-e8fc0b589268',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  2,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c59362a1-93c3-4cda-a06f-90501e5ab282',
  '0295d7d9-110d-4ca5-b8b9-30a0c1911512',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  8,
  8,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2516c33d-d31c-48bf-a74d-6c74b8d67ef3',
  '43e6d94c-2c71-4f4d-8d32-2e0057a79429',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7b736295-5cc1-4ef6-b821-6898c2969938',
  '43e6d94c-2c71-4f4d-8d32-2e0057a79429',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c935e6f1-d098-4e62-8dcd-99638672a767',
  '43e6d94c-2c71-4f4d-8d32-2e0057a79429',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '27c7952d-8f1b-4660-a3a4-8d8dfeecbdb2',
  'da6dd082-8cee-4292-8cf7-b99bb84eeac6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '96d0260c-8e84-4429-97f2-91e067764cf4',
  'da6dd082-8cee-4292-8cf7-b99bb84eeac6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3a101124-b3b6-44b3-82b2-e0533418608c',
  'de232720-6b96-4808-8a70-388ca6c8a178',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '531a9c35-4aeb-4d5d-b08b-cf093182f7fc',
  'de232720-6b96-4808-8a70-388ca6c8a178',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b0956c68-8690-4dcf-84a5-3a0847ec7bda',
  'bead61eb-acf4-44f8-b4f9-e42e113551dc',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  140,
  140,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '84baeeb7-c234-4316-be6e-ddff5078042d',
  'bdb7d9bc-d639-43ea-8d26-3ba5ef01202c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  38,
  38,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '02d8afe8-9314-4ccf-a0c9-84e36bc414f2',
  '2849f82e-39ad-4246-8ac2-60a2fa280035',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c4644db4-a450-45c4-8e6b-5071e3f411de',
  '7fb317e7-458a-4bdb-9892-d026097321a0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e0bc4d17-6b7d-4eea-90f2-51fe3b82d91e',
  '7fb317e7-458a-4bdb-9892-d026097321a0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fb6cf851-efc9-45bf-b5fa-8fd0abe59b84',
  '7fb317e7-458a-4bdb-9892-d026097321a0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1180379c-8a61-4ddb-ad35-8a16ca6e244b',
  '5186fa2e-0306-4b27-8b93-89676fec5536',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '03725378-c086-4d56-8897-6d143b9e1b9f',
  '5186fa2e-0306-4b27-8b93-89676fec5536',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e4d0ee60-1c32-492c-a36b-1a6690a09917',
  '838e95a0-af2b-4335-9308-3b00b33fc31f',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  112,
  112,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1d2b29f6-f31f-4c8c-af39-80f278f4cd40',
  '7ff6d31e-4d4b-4411-afd2-e2fd78f3f8b7',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  77,
  77,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f364172-1ab4-4d9e-a99a-2c01ad5698ec',
  '7cf53e98-eacd-4b5d-b05f-8825094d96d1',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  7,
  7,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '905c8d50-63e1-486a-b352-fec6d0ddc002',
  'a6c9455f-025a-42b9-a9d7-34dc17525e8d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '996f5086-67a3-4593-8b13-391fcec23d98',
  'a6c9455f-025a-42b9-a9d7-34dc17525e8d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '38bcaf15-0700-43e2-9ef2-a0d33605592a',
  'a6c9455f-025a-42b9-a9d7-34dc17525e8d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  2,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '825c0a4c-5444-4788-b60e-738abdee5365',
  '48771923-0b19-4dfe-ad35-d7f475354081',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0e4ca135-0401-4eac-9b01-f2108c856b13',
  '48771923-0b19-4dfe-ad35-d7f475354081',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ad0a1db5-37c1-43fc-9c02-3d8379f81b35',
  '26217fa4-a862-4087-856a-6da74ecc2ca6',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  37,
  37,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'da392ba8-b94a-4f6a-b8c7-0a4baa3f6b8f',
  'a7dc9333-4360-4cea-a647-92758a3956c8',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  50,
  50,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '94c78603-0f8f-4bcc-974e-8b508b49742a',
  'f8868ee5-fdab-4eba-a808-c016e93c4176',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a8640164-165b-4a9e-93f6-e1f46abd9dcf',
  'e9066e9f-fbc8-410f-9b71-e51323d58f60',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  105,
  105,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a809a8a9-e43c-4245-82ba-27348f0403e8',
  '8fa53821-4a70-4e66-98ab-e611f954a893',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '30309b5b-039c-4847-a0c2-cdebc4efe356',
  '8fa53821-4a70-4e66-98ab-e611f954a893',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2c891a41-af0a-4956-ad58-231de159fc29',
  '8fa53821-4a70-4e66-98ab-e611f954a893',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '61925bb8-9ff2-4710-9c4b-28b86cb55c25',
  '26b06005-e7de-4c85-96f5-0abfeb769d64',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0ca9bdf7-2663-435c-bfa1-068aafb0e9ae',
  '26b06005-e7de-4c85-96f5-0abfeb769d64',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8e52f996-478b-43e3-bb13-adcbff71413e',
  'f0548853-5b0a-46b0-9bf2-633fcb6465c6',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  10,
  10,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c6e5fe0f-9404-408e-b321-6bff32605815',
  '96b90d7d-fed7-45ae-9066-666fb719a651',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'db6ea835-43df-4bd9-a660-2dccae76cc21',
  '96b90d7d-fed7-45ae-9066-666fb719a651',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8589b73e-8146-41ac-acec-e9448646882f',
  '635df0b1-220c-446a-ac33-5db11ffdd748',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fdf05878-f745-41b5-aa0f-9eed97a3694c',
  '635df0b1-220c-446a-ac33-5db11ffdd748',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '94dc6376-74ef-47b1-90fe-f3bea1490023',
  '635df0b1-220c-446a-ac33-5db11ffdd748',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f932745f-bcf3-4ff5-bede-d006aa94dc52',
  '78be4c62-f475-4119-9969-ae38cd87fb8d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  52,
  52,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ec512057-33eb-457a-a699-154d2f43568f',
  '2c680076-6bd3-4b67-9ad9-9ec1ae3faaf8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0a624f99-e01a-4b89-87b4-eb3ba41fc38a',
  '2c680076-6bd3-4b67-9ad9-9ec1ae3faaf8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd33783de-1432-4b38-ac80-c879c65682e7',
  '5d0631e1-acda-4b2a-954e-944bb1ce0b04',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  57,
  57,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '46dbf776-6843-4166-a496-e4618e20b41e',
  '1bfffd22-4ec3-441f-95a0-bd723ae814e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3ec39d2d-c305-4768-850f-dcf9cba8d48f',
  '1bfffd22-4ec3-441f-95a0-bd723ae814e8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-012'),
  'Hoody/Jumper',
  1,
  1,
  3.0
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '30d061ae-2175-4780-be56-54d6e4df1b87',
  'e18dd17a-0842-4e1c-b214-7583b243bcc0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '698d6830-d073-46f7-b390-6388ee2bf7b8',
  'e18dd17a-0842-4e1c-b214-7583b243bcc0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e18df174-e75d-460d-bc97-3d91884c54aa',
  'e18dd17a-0842-4e1c-b214-7583b243bcc0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '94ed2b64-25e7-48e9-a9bc-bdd01f872818',
  '19e62d62-a67f-4cba-9585-57096ddf9867',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '781a9b8c-644f-46aa-a6c7-3b5f40c4f118',
  '19e62d62-a67f-4cba-9585-57096ddf9867',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cfb79956-7bed-4aca-9008-d29d2fa62cce',
  '8544c622-d60c-44da-8a15-5313f7bc32c4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  92,
  92,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '44d0fa1a-cbcc-4669-b953-a11152d60762',
  '7586d0b2-24db-4671-9e58-4d8d2901be6d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd8c7d2b1-694d-42ae-9b22-910acc3ae1a1',
  '7586d0b2-24db-4671-9e58-4d8d2901be6d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '120dd18b-e75f-4ff6-8d04-5b16d95f1b58',
  '7586d0b2-24db-4671-9e58-4d8d2901be6d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd3745f2a-6eb4-4f2b-b842-fc10308cafe5',
  '09962f0f-c05c-4816-850d-4675915bb68f',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  38,
  38,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '77085a96-f928-44cb-9e2e-f1ec285a0968',
  '701697b0-3230-4319-ad35-24f24a426695',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8a7aafe2-dbf7-468f-8957-8a88f2d43177',
  'd45ae464-b642-4569-8ba0-ff7b967f6efa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f7a31f8a-a63f-40ca-a90d-087e647f6eb0',
  'd45ae464-b642-4569-8ba0-ff7b967f6efa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bd4bfcd7-b999-4aef-9834-79fdb9c98519',
  '7f91a1e7-9f43-4164-ad50-2c5fa4ea3b31',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  17,
  17,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c0c72afa-5b3a-41fa-9283-0fe80839b03e',
  '74adcdb3-1066-4320-b1b6-fc9be3481a68',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1f000cb-678a-49db-8718-bd00a89a256a',
  'd679ec25-9d72-42b5-849c-232919d93b37',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e4078d75-702f-4b07-be43-54094d4e5859',
  'd679ec25-9d72-42b5-849c-232919d93b37',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1b82f7d4-6a12-4971-adff-9c5fd36e6b46',
  '22cfe02a-689a-4844-bfa9-eee02ed15c30',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8655764d-81d6-4f5b-94c7-13f5a4897570',
  '22cfe02a-689a-4844-bfa9-eee02ed15c30',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '24ddd407-8e48-49fd-a74d-23c3740f7bc8',
  '8c48ee2a-d078-468f-8a01-9bd3818535f4',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  108,
  108,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3cf1bd6d-7ea5-49c6-8324-f257178341f3',
  '3ceea1d6-837e-47e2-a13b-02b484a1c082',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '989d76ba-35f9-4cf7-a234-bd0a4aebc767',
  '3ceea1d6-837e-47e2-a13b-02b484a1c082',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f1efad97-22f6-495f-bd06-92aeb9e35b78',
  '3ceea1d6-837e-47e2-a13b-02b484a1c082',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fee84dcd-df91-4f7b-a4c0-5017d018ffa7',
  '91586a95-5145-4261-92ad-5bd855d1ca29',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eed2cd52-c9fb-4656-acb5-ed8c738a6303',
  '91586a95-5145-4261-92ad-5bd855d1ca29',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f8440486-b554-4bf0-896f-733f9c43d538',
  '91586a95-5145-4261-92ad-5bd855d1ca29',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  2,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fe77f9ac-a14b-454f-9e17-5ca11ec6c9cc',
  'c1d96b2c-6c0f-4f47-ab79-8c0723abbfe7',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f0f7e857-f571-4532-917b-ed6b260c9084',
  '6c85411b-4fa8-4683-a027-067b403b227f',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  93,
  93,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5cc2e87c-772a-4d64-bbde-b15672f0e5e5',
  'e2293ad7-a86d-45ed-951e-20386b46ddde',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  10,
  10,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd6517827-7bdc-42eb-b31e-dbd1764a5aa4',
  '3cc48915-1442-451a-8f24-25c7d3d76daa',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  5,
  5,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b9ecb047-b640-4d6c-ae71-69f918868650',
  'cbc63a08-2f4b-4b12-af86-5e94fe8ed649',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-002'),
  'Table Cloth',
  5,
  5,
  3.25
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1643106d-466d-4fe3-8592-27d3f5989815',
  '1055ee74-3e06-4b32-9a6a-059bb99a8e9c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '71e0cefc-daa8-402c-b344-1ea86cf6dc78',
  '1055ee74-3e06-4b32-9a6a-059bb99a8e9c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd767ae55-ba65-4344-90b3-78c4a61d3ee6',
  'bd8cf061-476a-4ca0-b82e-7618a874b153',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  311,
  311,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6f669b9d-db79-44e8-b6c2-dde8dd20e0ce',
  'eb067871-5236-4097-831e-372b1849c1b1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2e670d32-b102-42f8-8d2a-017228c771fd',
  'eb067871-5236-4097-831e-372b1849c1b1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  2,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8b3f1da6-cceb-4516-bbc5-ce077554284d',
  'f4672b2a-12d0-4dba-b0bd-cacef36a0192',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2154dca2-d44e-4450-bff8-b3ca36a5d7ae',
  'f4672b2a-12d0-4dba-b0bd-cacef36a0192',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1840f6e2-2bba-41f8-8d2c-9419aaae3d50',
  'b87eff9a-7e25-4a11-9b77-22b15ca6583b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4f347402-8ace-4128-948e-53517057a18d',
  '334a3d43-4c1d-4437-afb5-645863ae92ff',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c396f32c-888f-465d-942d-8edcbe352c3f',
  '334a3d43-4c1d-4437-afb5-645863ae92ff',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b37618f-0899-4105-accf-02ca59a913f2',
  '5860763b-7fc0-483a-952a-cc6b6bb5c489',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9e685abe-9a0f-4958-870c-aa826baac22b',
  '5860763b-7fc0-483a-952a-cc6b6bb5c489',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd6c583db-217c-4960-9f74-a80fc5cc0e16',
  'fce3d54a-6992-4b9c-9872-3f20d16f69e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b8d6bd5b-897d-4f03-a565-7628b3edf8cd',
  'fce3d54a-6992-4b9c-9872-3f20d16f69e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5574eba7-bd4d-49fd-81c5-122033a9d575',
  'fce3d54a-6992-4b9c-9872-3f20d16f69e6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a57ff196-3b02-4723-ad41-07aae6c5eae9',
  '618f6c98-147b-4eb2-affc-7424b13886b0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '98df04d3-e524-4044-95e2-2159d8e59ada',
  '618f6c98-147b-4eb2-affc-7424b13886b0',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b2715770-0a81-4052-9f02-9eb41b53c67f',
  '09a3a6f8-8525-4924-9c6a-2e472a3dee9a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '381bb4a7-79ef-4c5c-84aa-f7cc6f81b296',
  '09a3a6f8-8525-4924-9c6a-2e472a3dee9a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bacdfa4a-ad3c-45a1-a32c-706cc8457a52',
  '2947d836-4b8d-4dac-8544-53fa7c3027f6',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  3,
  3,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bd2d3d1d-3bd1-4d8a-b8ba-48bff7a6dbd2',
  '769a4583-3d7a-413f-8843-42e97fd4041a',
  NULL,
  'Housekeeping',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '571d7b64-4f50-4e05-bbd5-b9386b5dcafa',
  'ac3b86c3-6599-44c7-8327-59f55c83d861',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2b86d5d1-29c4-41e0-aca2-1433750397c5',
  'ac3b86c3-6599-44c7-8327-59f55c83d861',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd8441708-ceb5-44a9-b418-985bf5292528',
  'ac3b86c3-6599-44c7-8327-59f55c83d861',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f525dd22-ab27-490a-8c67-2d5fac92e743',
  'cf5a86ca-b089-47d8-ba1f-0822b7787c33',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  78,
  78,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5fd716f0-a410-4680-a30c-f37e1216a8aa',
  '64edfc5f-61cb-49da-9abc-f2ed754d9542',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4a2c91bb-01ed-4bf2-966b-6f22fe696010',
  '64edfc5f-61cb-49da-9abc-f2ed754d9542',
  NULL,
  'Guest Laundry',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cfb63edb-ea06-4ef9-8fa9-3dbbd59ac2f4',
  '64edfc5f-61cb-49da-9abc-f2ed754d9542',
  NULL,
  'Housekeeping',
  1,
  NULL,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c648901d-5f2b-4cd1-be4e-b3e684aac3d4',
  'cf8aa9dd-6450-483e-840c-d5c281d5d4b9',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  56,
  56,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9f32bd00-6f75-40f6-b2f6-9608625d1ef0',
  'f548e063-3f43-4d67-b572-1233d73d3187',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  1,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb519a64-f482-4714-9dc8-aed078f390fd',
  'f548e063-3f43-4d67-b572-1233d73d3187',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd4b99588-155f-43aa-91fb-580c4357d32f',
  '0cc51c16-e86c-46a3-b2ab-5ceaed55c46c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  98,
  98,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2ecfc0e3-9657-4a12-b359-b5495c855751',
  'a1b1a576-de18-4a52-95fe-1b5486b36220',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fe9083e6-046d-40ac-b1de-2480f4689167',
  'a1b1a576-de18-4a52-95fe-1b5486b36220',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fa9e62da-1bc6-4a3d-b00a-a623c7ccacc8',
  '3d68be3a-0263-43bc-a763-4ad300309573',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1abd7ffd-6b8e-4ed7-8388-8a39a121e4af',
  '3d68be3a-0263-43bc-a763-4ad300309573',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '456905f0-8051-451a-82c3-02f07ec0770e',
  '3d68be3a-0263-43bc-a763-4ad300309573',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd360c63e-d3d2-41d8-9417-9e47f7c10a8f',
  '87ce60bb-4500-4a3f-aa46-eadde404ccdb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '789fa46e-d772-42bf-8248-986695352e09',
  '7366e1de-d1e8-473c-a087-f60596765ed4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '47858266-2842-4f43-954e-e1cbc8302ef1',
  '702d1640-ca55-49f5-b3e1-e505aa35d919',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1a026782-7496-4ddc-8df2-663dce678794',
  '702d1640-ca55-49f5-b3e1-e505aa35d919',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b12deb7b-b573-41e1-9343-01c3fef696b1',
  '502cba1c-7740-4473-9a82-cf5a7166969e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b1d1496b-8c03-42a0-8077-d61225cde9b2',
  '502cba1c-7740-4473-9a82-cf5a7166969e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '58d2f272-1ab4-4faf-8119-ece64f4e33ef',
  '77075a93-333e-4996-a3b3-5abf201f860e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b0c0ed66-cdc6-4495-8723-fd3f3ceb260d',
  '77075a93-333e-4996-a3b3-5abf201f860e',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6dc8bd40-4cb7-4c25-8f34-f8d7481c4c92',
  '5353d11a-a8d3-4e68-8ed7-1eb4b80cabbd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e8dae1c1-a74e-4e6b-80b8-59ab0d21a9c8',
  '5353d11a-a8d3-4e68-8ed7-1eb4b80cabbd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7dc68850-035b-4bc6-9960-f7e77c8d6757',
  'f6430bb3-cd21-44c8-b251-c7c3ab685239',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '081176e5-08f4-4ff8-b371-40c85903d41e',
  'f6430bb3-cd21-44c8-b251-c7c3ab685239',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9b6218c5-442a-4428-9381-ab6db2067ec8',
  'f3ddc398-2aad-4c46-9bb2-70b6cd152672',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  43,
  43,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0acfb455-73b2-442d-9697-d1a931b0a74b',
  'a8d0141e-0272-44f0-92ba-144f32d4dd21',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  61,
  61,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c3534b50-7999-4b2f-ba22-1fb716d33ddc',
  'c29c9ac1-ca8b-4573-ac5a-8e3ca084097c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  5,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '89b34c1f-1f2c-4256-83d7-ac42647bf63d',
  '0b440d63-3261-428f-a12e-7cc0f47b7d40',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1ded1233-df8b-4408-8c85-ac0796ddf790',
  '0b440d63-3261-428f-a12e-7cc0f47b7d40',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'bded6da0-0322-4468-8183-ea45b3976ddf',
  '299c0040-e749-48a7-8d7b-9f9a6708a805',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  3,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2f710372-87f8-4e69-8637-86b08c3ad1e1',
  '299c0040-e749-48a7-8d7b-9f9a6708a805',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  3,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c435d905-1d65-4403-945e-688c5d8659f9',
  'bd36c0d4-a27e-4742-a043-e7c23a80e961',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  59,
  59,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5debfccd-a8a4-49a5-9927-b72866a17406',
  '09eaf51d-059c-46d9-8664-53cf26b68a29',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'edbf4271-773f-4ffc-be4a-1638c37ec2a8',
  '09eaf51d-059c-46d9-8664-53cf26b68a29',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '48043cf8-7aa1-4146-ba7e-630ef8191cf8',
  '43684422-9435-4e56-bc5a-b3f124a84178',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6ba45f00-ecd9-4f0c-b16c-e356d5f69b83',
  '43684422-9435-4e56-bc5a-b3f124a84178',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6957a59b-992a-4d83-ac86-1a56b2a7dde5',
  '43684422-9435-4e56-bc5a-b3f124a84178',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7367f4d7-d240-4789-acea-16ec0e69ef20',
  'd1f742ab-4162-47e5-ac68-cf75b0e0cb68',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7484e241-7ddc-458d-adaa-6d393e2c8ab6',
  'c8ecb035-6dce-43d2-ae57-22210b5bb0ab',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  14,
  NULL,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '57232d97-a644-4f9b-b945-1d4dff3e3238',
  '6f3872c6-b6d7-4769-ac33-3c2b8a452721',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6020277d-c07e-4e38-97dc-df4be9548dbd',
  '6f3872c6-b6d7-4769-ac33-3c2b8a452721',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '615058f8-9104-42cb-80e6-ab1f1320524e',
  'eb6330f3-c295-433c-af41-3af74b227ea5',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  55,
  55,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0a2f9ef0-0b1f-4fe5-ace0-15edc03ab726',
  'a7194e1b-d27c-4a20-896d-e806e0caa44a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4568c632-b9fa-4c33-bd10-e727b24b3e86',
  'a7194e1b-d27c-4a20-896d-e806e0caa44a',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3af0f7b7-3703-47dd-a189-e40d0327bce1',
  '6841d8d7-584f-44ed-aa1f-61c3118f2451',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  56,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1dc38c47-2509-47fc-91a0-1c0c7da7ef46',
  '1c9c4a47-a050-4e99-be07-1be6d20deddf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e398e48b-7b78-41e1-ae5b-ba82295a14cd',
  '1c9c4a47-a050-4e99-be07-1be6d20deddf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '61b13254-d0f7-46f6-8e4b-4919b0728a46',
  '1c9c4a47-a050-4e99-be07-1be6d20deddf',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '85a4f03c-e05a-487d-aa60-1073c399d937',
  '153fe917-00d1-41dd-aa34-90db8f059ac7',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  68,
  68,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '842058ac-be7f-4457-b52c-cad5939e14f3',
  '1adc8691-a534-404a-8ff0-d910afef4bdb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8eff78f7-f2c7-42b0-864e-7dc13e0850dc',
  '1adc8691-a534-404a-8ff0-d910afef4bdb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f4e6ac45-125b-4c39-bc8e-aeece3eb6ec9',
  'ab87c471-dc23-4c4b-a1c4-3b6934a76d16',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b47f78b2-ebda-4cc0-8794-73b88a713a08',
  '7254b071-1aad-4143-9971-ec80e7523670',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '069ed367-9470-4ca1-bb1e-427d865e7edb',
  '7254b071-1aad-4143-9971-ec80e7523670',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b2908b4-f944-4f47-91f8-72b3733239fb',
  'dba171b6-0684-4503-b74e-212b6afce43d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ffee99cd-88dc-404f-9936-887059158563',
  'dba171b6-0684-4503-b74e-212b6afce43d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '02d7c794-d0a1-4b1a-84b0-b34a841f6b1e',
  '195107fa-8a0a-4485-a9bc-65ee5aacc233',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  10,
  10,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '198654f1-659c-405a-a26c-a17f25951811',
  'bb2f46cf-bbb5-4372-8cde-08e8382a2072',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  1,
  1,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e6ad1c44-2815-45fd-b3cc-75d62eee3775',
  '786df39a-d0c8-4eb4-a835-fefdd4157c34',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b91f451e-2406-4738-b82b-0590ee650d88',
  '786df39a-d0c8-4eb4-a835-fefdd4157c34',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  2,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'db2ce14b-0b6b-43e0-9ad6-3d9f4f0ade96',
  '786df39a-d0c8-4eb4-a835-fefdd4157c34',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4b38f874-7d2c-4112-a2cc-5a365c00b240',
  'f731c167-8f79-4043-9f0c-6183ef808fb1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '599828f2-246c-4870-a4ec-fecdcf70df8f',
  'f731c167-8f79-4043-9f0c-6183ef808fb1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd685084b-d0a8-46ee-a85e-a7c7c2e79521',
  'f731c167-8f79-4043-9f0c-6183ef808fb1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e4765317-f1d1-42ef-8773-d260032a7cbe',
  '4d3af652-2bad-4588-b55b-6b9b571adbb2',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  33,
  33,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7f9ae81c-8587-40f3-9222-c8392842ac25',
  '1f54f5d7-f192-4da3-8677-d850f742ca8d',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  59,
  59,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2d1c7ffa-8720-4bd4-9c91-9772705d5e3e',
  '828aad05-4b88-4025-8e70-5e37abb5634b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '54870c6e-3499-4641-95ae-ea2da2c38d43',
  '828aad05-4b88-4025-8e70-5e37abb5634b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3360036f-e6f9-475a-96f7-b3a202d12fa1',
  '983014f0-665c-4481-bb17-6a06e59f3b82',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f6571423-38fd-479a-a541-3407cf0ba104',
  '0a101622-e2b9-4bfb-8268-5f3ec60d302c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eb541078-f84d-46d4-870d-585ce3daf056',
  '0a101622-e2b9-4bfb-8268-5f3ec60d302c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7143f4e1-96d6-495f-a74f-7b3778ff6a3b',
  '0a101622-e2b9-4bfb-8268-5f3ec60d302c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '99a538ce-b804-47c5-9909-b1424ff61084',
  'f2bab28a-37e5-489c-be14-eb549e0ec471',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04db2aae-70c2-4064-939a-8b4ab2b4f6ca',
  'f2bab28a-37e5-489c-be14-eb549e0ec471',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e684ccb9-d7c3-4642-b9ac-bc93fa91b9fb',
  'f2bab28a-37e5-489c-be14-eb549e0ec471',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e0f9c974-f28f-4514-a062-1209979a90a2',
  '6531c406-8ea8-41dc-af91-b8fa450224ac',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  80,
  80,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ef56e6c0-96f2-4ed9-bf41-4e70e5dc6032',
  '9838c77b-b1d2-4840-8aec-d437066359e4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8d37fc12-8a49-4d8b-bc01-12aae5e69e58',
  '9838c77b-b1d2-4840-8aec-d437066359e4',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2a599ad6-1d2e-4c66-a584-23038354050f',
  '7b3ac88c-8d58-41a6-8fe4-1102b817765e',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  6,
  6,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '058c1cc1-e83f-4d59-940b-fcba92781874',
  '57b7ad77-5b86-4f57-a4ea-8e5b1991ce12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  2,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1414894e-a165-432d-8308-abc5cb34e7c6',
  '57b7ad77-5b86-4f57-a4ea-8e5b1991ce12',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  2,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ff9acc15-5771-4cfe-9259-7f4a513bf339',
  'b9b7e45d-5589-4b9c-8bc1-a57158cc26ca',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9907b42f-5971-4561-a1e1-a08a4e3c2f1a',
  'b9b7e45d-5589-4b9c-8bc1-a57158cc26ca',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '21b4a66c-c5c7-4abe-9c65-1818783e003d',
  'b9b7e45d-5589-4b9c-8bc1-a57158cc26ca',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '57e549d3-837e-40de-950c-8ef53fcac3b8',
  '968fb31e-a131-4400-962f-862314f76468',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  40,
  40,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'eefbef91-4590-4a22-a32c-4743bd7d403b',
  'e44a531f-7349-48ef-837a-f2dbf597efbd',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  46,
  46,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b0b2b5db-570e-482d-95db-817943749f99',
  '176f31e2-a44c-487c-8fc4-b81af2b222be',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  3,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2320f186-55ed-4fdc-a07a-609cce34480c',
  '176f31e2-a44c-487c-8fc4-b81af2b222be',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-005'),
  'Jacket/Blazer',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5c901f1b-aa5f-4676-8875-9ba89aa9989d',
  '15074563-fd7d-4547-9ae7-7b5f806fc646',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ff70f72d-abd7-487a-b601-cf03eca48161',
  '15074563-fd7d-4547-9ae7-7b5f806fc646',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f8d1005a-cdb0-48f2-a179-6e15e8533d18',
  '15074563-fd7d-4547-9ae7-7b5f806fc646',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '55033150-a600-4487-aa1e-1fa56721cb5f',
  '560f7500-4739-48a3-bdf3-0ae6feba74cd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b55d81ea-aded-46d6-9c12-0507c4884ce4',
  '560f7500-4739-48a3-bdf3-0ae6feba74cd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '43b2fa76-9014-49e7-8028-8452a2a64f01',
  '560f7500-4739-48a3-bdf3-0ae6feba74cd',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '97182d9f-169d-4efd-8497-e50b2a35c3da',
  '02674c3d-756b-422c-8944-bc93e34170ba',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '657d6086-97b8-44f4-b87b-7e3e3495ff94',
  '02674c3d-756b-422c-8944-bc93e34170ba',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9c26386e-5149-44d8-9e42-1688d8927741',
  'd52ff063-3f49-47e7-adcc-62f6df6640e7',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  8,
  8,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ac030e38-3a69-452e-8062-a02850379011',
  'c6187d2e-a5a9-429e-b334-32b9e76e74de',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  65,
  65,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3e6858c3-021e-4991-936d-8b724ff8ced3',
  '004d68d8-ddf5-496b-8878-65091112aeef',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  42,
  42,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b999617e-9dd8-4247-b73c-3a2a7c844938',
  'ebe93862-3b8b-43a4-a549-790e014fcb1c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd6361e33-e866-40bf-9656-c961fba85597',
  'ebe93862-3b8b-43a4-a549-790e014fcb1c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1934eb22-9796-4b31-9332-8a5c5324198d',
  '5e4c7d84-46c2-4216-81d0-1943c60e6434',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '47c4a46b-7a1d-4eed-8508-a78f6d7780ae',
  '5e4c7d84-46c2-4216-81d0-1943c60e6434',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  4,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '38dfd106-38b0-4758-bfac-ab1b55414e17',
  '5e4c7d84-46c2-4216-81d0-1943c60e6434',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fff021e9-5d5b-4cd6-9db4-1c600bbb45d5',
  '2f73df4f-9fbc-4cec-bd32-00991fa4866a',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  24,
  24,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9ef127e1-28c7-481d-885e-c959881b034a',
  '5fa5babe-9738-40fa-ad27-3b7837d7bd4b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5b1d8b9f-5120-4027-8728-81a1197aae7a',
  'bde843eb-4d54-4c22-8517-02e92271e83b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  1,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '45a13c0f-20a5-4343-9ca0-f6d312c0b4ba',
  'bde843eb-4d54-4c22-8517-02e92271e83b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c7bea9d9-8fd8-4b76-91ac-d2c49233c14f',
  '22de7f8e-e4d6-404d-9b88-b07a99706d94',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  68,
  68,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b4d0e593-6498-45fb-84c2-77931bfaea33',
  '482a04c7-e6dd-486a-b620-b4a7ef05c588',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  1,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'fb47a930-10fe-4f36-93d5-07887f3c59b3',
  '93f7ea26-cd74-459c-af0d-1df6e27bb154',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  1,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ded75d91-8a2b-456d-9538-cd1c67afa0d7',
  '93f7ea26-cd74-459c-af0d-1df6e27bb154',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  1,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '631c0f8b-e195-433c-8ad8-3260276b95e2',
  '93f7ea26-cd74-459c-af0d-1df6e27bb154',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  1,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9faf4b09-f26e-40e7-9070-e6245116d8ce',
  '29650e0a-15d9-48f1-a261-edfb8529ce29',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  21,
  21,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '578f1a4a-9cf4-4fa4-895b-0a5db89bebe4',
  '7d4d18da-da2a-4043-a7f6-8927de526e70',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7a4abc74-7702-425e-a429-5e24ec249eda',
  '7d4d18da-da2a-4043-a7f6-8927de526e70',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '75626e32-2b90-49bf-99c3-b7c09c1681e9',
  '9f88f4fe-ecec-4c91-add0-563d9bf57727',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  5,
  5,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '83f567f5-be38-4052-8d2c-eeafea6a2209',
  '7ca4faf9-70df-4594-aff3-45ac149166ad',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '7a3b9ce5-b14e-4374-9f27-dd2edfcdd078',
  '014966d1-4c46-4181-912f-14e84898f949',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dc0227b9-813b-4548-ab76-8aa46dccb0c3',
  '014966d1-4c46-4181-912f-14e84898f949',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1800adef-534e-40b2-8736-22bef49cd21e',
  '6f82d311-4293-4dbc-853b-602aceb4b14d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '92cc0a0b-e69c-4c73-8582-c32a4adb4df9',
  '6f82d311-4293-4dbc-853b-602aceb4b14d',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '27671336-7729-4ba1-ac66-c7cf1f365d05',
  '450dd920-1fe3-4ab4-87e7-7d31fea860fe',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ca6e4405-b94d-42bc-b1fe-db60790fc323',
  '450dd920-1fe3-4ab4-87e7-7d31fea860fe',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e36a981a-1b8b-441c-b6b3-ba93bab1e437',
  '1a432d36-12a0-4654-bdaa-dd496c343eb6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6f09a56a-e192-433f-baa0-8652a7a21dfb',
  '1a432d36-12a0-4654-bdaa-dd496c343eb6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '073e6275-3da3-4d31-ad16-4489d5c887d5',
  'c4be13d2-61e8-459b-948d-086489dc3cc9',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  46,
  46,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ef26fe58-561b-4764-8031-e530e793e276',
  '885c484e-2ac9-46e5-abde-cdf19ce60460',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  43,
  43,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '49d5982b-108c-46b3-b1bd-3531f4e4d85f',
  'b6459b54-137a-4899-86f1-890156b00385',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  81,
  81,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '60bf3320-f6ed-4c74-8fab-afa46ff245eb',
  '3beae2d1-73b1-4af2-b1ac-5346f916c3b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dd4c2f15-25c5-4b4d-b285-9006a13cf8cb',
  '3beae2d1-73b1-4af2-b1ac-5346f916c3b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'e46a38e7-fdd6-4bab-807a-28fd53e6d2a9',
  '3beae2d1-73b1-4af2-b1ac-5346f916c3b8',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '44065e35-2d7b-4bbc-adfd-b33b1aaea0e6',
  '742eaf82-bd09-4537-a5b3-315e15d90974',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8148c226-824a-447d-9a87-fc13909ee0a4',
  '742eaf82-bd09-4537-a5b3-315e15d90974',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  2,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '88a0e381-e52c-4b65-b662-724cd9a93e47',
  '742eaf82-bd09-4537-a5b3-315e15d90974',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '6bb594df-2d8c-4ffa-985d-0d42782ea806',
  'ce65eff6-0a49-4927-8394-3532fb176870',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '829454a6-3368-4042-89b5-9308c65a2b65',
  'ce65eff6-0a49-4927-8394-3532fb176870',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8b4550b5-f9e4-4b2e-addb-86995ff783b3',
  'ce65eff6-0a49-4927-8394-3532fb176870',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '1f4de3ed-7d16-4924-ba49-eb147e7138c0',
  'cfd8d50a-c5c3-4572-a30c-7ed652639481',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4edf906b-fd69-4590-844f-26fc22664adb',
  'cfd8d50a-c5c3-4572-a30c-7ed652639481',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '63c2050c-d028-4495-bc2b-1e1e7ea0c695',
  'cfd8d50a-c5c3-4572-a30c-7ed652639481',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'dff3fd7c-85cf-4590-8e68-3f3c0d3aa9a2',
  'f3250bfa-567e-4f16-b612-28145b2b0427',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  2,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c550577b-e65d-479d-be7e-e917c649b7b4',
  'f3250bfa-567e-4f16-b612-28145b2b0427',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8938990b-ccd1-4969-86df-c917fb63b080',
  '2a7120a1-67e0-4856-9173-932a1de1c32b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b8be50bb-34f8-43c8-b9f3-703dd1a90571',
  '2a7120a1-67e0-4856-9173-932a1de1c32b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '71c0cde4-51b1-4e04-a865-8ad4884571e5',
  'dd8cbb2f-eeb7-46ad-ac70-05b9a554a88d',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  12,
  12,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cbe90378-86ac-4f49-937e-bd4066e98ef5',
  '5bedc885-349a-479b-9f75-afc797e3f092',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  164,
  164,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '31da6b3a-f54a-44e7-9b0d-c26666843f04',
  '9a358ade-4bc9-4a2b-91d6-c2a7c5d879ff',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  120,
  120,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '95b705ba-82e2-45aa-acec-4034e373fee1',
  'cecf2b96-cb2d-4bf2-b9c4-58c5209867e6',
  NULL,
  'Guest Laundry',
  1,
  1,
  NULL
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '86f9176a-7de2-4e54-aac7-fbda936b5bea',
  'a9f383a9-0bef-4fa3-93e0-6a6097f6ab38',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '07d52f77-2db0-4da5-9bf3-bc9b3a2e5dcc',
  'a9f383a9-0bef-4fa3-93e0-6a6097f6ab38',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b68f444f-79f4-4eb3-84a0-eadcf657e227',
  'a5ade450-16ce-4918-ab11-10756e3a5c91',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9a96cfa8-2370-48d4-8d8d-a8e776341415',
  '7c8ae02a-833e-4fef-aef8-74595470052a',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  210,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '13d7e404-c7b5-4920-9aec-dde1b4c3d72b',
  'ce059717-3302-41a1-acfc-24a9a496d8d6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '37751422-655e-4cb7-9e23-c0ba94d87a07',
  'ce059717-3302-41a1-acfc-24a9a496d8d6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3531d89a-a2a4-4304-9797-5ccfba12f803',
  '2ecf25df-12dd-4380-ae88-c35efaf43fe3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-010'),
  'Chef Trouser',
  1,
  NULL,
  1.48
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '91f0c990-142e-45fb-9103-64ae23435c8f',
  '2ecf25df-12dd-4380-ae88-c35efaf43fe3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cf8e87ab-bbfc-47ed-bb14-b84f842391f2',
  '2ecf25df-12dd-4380-ae88-c35efaf43fe3',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '3e8f8e45-af35-45a8-93ec-9e47ba734567',
  'a6067397-8260-46d1-906d-04ad0754b61e',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  22,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a1950479-d643-4e4d-85de-18a6f4b6f47e',
  '8d8849a9-060d-4f3f-9193-90dc34e4d8eb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ed4c7ed2-274d-47b2-ab70-c7e140b179cc',
  '8d8849a9-060d-4f3f-9193-90dc34e4d8eb',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5407ecf5-b589-4cff-90b8-ac5bc0b86f20',
  '080a97e5-629e-4c97-838f-f1f95650faf7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c15ec9db-90f3-4ee4-9b60-d677708474cb',
  '080a97e5-629e-4c97-838f-f1f95650faf7',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0f825f5e-3aa6-4a69-a0b3-009cdb8a4a17',
  'cfb99149-632b-4871-b58a-c2eb93c5bdaa',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '97e1347a-122e-49e6-9c48-fcd6bfd16115',
  'b9329171-6203-4786-bb96-b79fd74704a3',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  14,
  NULL,
  2.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '934e8b16-93ef-4745-aa41-9534adf23bcc',
  'c0a17e4e-46d0-40b9-962b-72364f4702b6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'a32b3f89-f975-429f-a6d5-e5abe7b7ddf2',
  'c0a17e4e-46d0-40b9-962b-72364f4702b6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'd90ebb1a-109f-4572-a9c7-1db964537d99',
  'c0a17e4e-46d0-40b9-962b-72364f4702b6',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  2,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8f2a67d5-7840-46c6-8e83-19695f002eb3',
  'ae2877b9-348a-48ca-b0bd-3cad0393ff96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1dcd5e1-28b6-4e2d-8c7b-7ed6be563712',
  'ae2877b9-348a-48ca-b0bd-3cad0393ff96',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '04a78cd9-a4a0-4284-895a-42cea71f2b0c',
  '2bb456d7-c1ce-4cd0-a110-d135e1c3e7c2',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  50,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'b436c795-af3d-4530-978f-ec692c57da57',
  '77b3065e-1364-4fed-af25-d7bb8480ca13',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  76,
  NULL,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8fafb4b5-405b-448b-a81a-ea12c0307a18',
  'fbf93c27-2c19-4865-bfec-047b54c96e6b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '19c05c00-b375-426a-9a0d-1494a75e2098',
  '2d77a386-cd06-416e-b59d-be05e2a00344',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '0639c2cd-0054-4d44-b2d0-2a53b4edf8ac',
  '2be1d72c-d7a5-4705-9354-1386a96bf42c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '8407783a-1a0c-4c42-afe7-a343c67fe7d4',
  '2be1d72c-d7a5-4705-9354-1386a96bf42c',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '4e437160-06c5-425d-bba4-23a07a3760db',
  '93c3f525-795e-42af-af0b-ead02062014c',
  (SELECT id FROM item_catalogue WHERE code = 'FNB-003'),
  'Linen Napkins',
  48,
  48,
  0.22
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '9d11774a-c05d-4561-94a1-080905c365fa',
  '3b988a88-6e49-4a7e-aa3f-a7ac0e64234b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  1,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '5cf6b276-8fbb-4349-9c23-489c64b3c2db',
  '3b988a88-6e49-4a7e-aa3f-a7ac0e64234b',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  1,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'cea25d58-0863-4106-82d9-7a2b8932d274',
  'c5a2eeb3-7f95-4377-a93e-e3b834e070e1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  1,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c0a784ff-cad7-4f2e-b3fd-806f5f440066',
  'c5a2eeb3-7f95-4377-a93e-e3b834e070e1',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  1,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'f58e220a-2f45-4354-8821-b77e88cbce80',
  '16070ba9-d5d6-42d0-a3a7-294dec95eead',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-006'),
  'Apron',
  3,
  NULL,
  0.99
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '38e7f8e5-3b13-4e41-87a2-f051cea67099',
  '16070ba9-d5d6-42d0-a3a7-294dec95eead',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-009'),
  'Chef Jacket',
  3,
  NULL,
  1.34
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'ee4d2f97-6c8b-468a-87b4-b69f22547e46',
  'cffbb268-7774-40da-9b34-1ac501c7e938',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-003'),
  'Trouser/Jeans',
  2,
  NULL,
  2.75
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '2c799a2b-8882-4f12-8999-6a88a7eec1cd',
  'cffbb268-7774-40da-9b34-1ac501c7e938',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-001'),
  'Shirt',
  2,
  NULL,
  1.1
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  'c1bc60a8-62a8-47aa-aac4-5c2a0b039501',
  'cffbb268-7774-40da-9b34-1ac501c7e938',
  (SELECT id FROM item_catalogue WHERE code = 'UNI-015'),
  'T-Shirt/Polo Shirt',
  2,
  NULL,
  1.74
);

INSERT INTO order_items (id, order_id, item_id, item_name, quantity_sent, quantity_received, price_at_time)
VALUES (
  '18f26854-be77-46d8-90a6-840f37962117',
  '7f2d21f3-2636-46eb-9e66-5f8d90ea9d74',
  (SELECT id FROM item_catalogue WHERE code = 'HSK-004'),
  'Bathrobes',
  7,
  7,
  2.99
);

COMMIT;