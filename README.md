## Reproducing Flink RocksDB leakage

This contains a docker-compose file for reproducing a somewhat obscure "bug" in Flink where a timeouted Flink checkpoint leaks files created by RocksDB's checkpoint mechanism.

Run it:
```
docker-compose kill; docker-compose rm -vfs; docker-compose up --build --abort-on-container-exit
```

Then, wait for at least one checkpoint to timeout (Checking the webinterface at :8081 or the output.)
and fire a
```
parallel -q --tag docker-compose exec -T 'taskmanager{}' find /tmp /media -name chk-\* ::: 1 2 3
```
which should give you something like
```
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__24_24__uuid_ba4b2cd0-2c23-4721-9a52-18c8aae12d8a/chk-19
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-9
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-15
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-16
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-17
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-18
1	/media/flink-io-4a899fcd-e624-4056-9160-b62f2a627843/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__18_24__uuid_62dfb6da-3fa4-49e9-b031-585e1de74b45/chk-19
3	/media/flink-io-ff889895-ce6d-4298-8ee8-8dd88f67eff5/job_ac7efce3457d9d73b0a4f775a6ef46f8_op_KeyedProcessOperator_20ba6b65f97481d5570070de90e4e791__15_24__uuid_8a1cd363-3bef-49f2-87e9-71d6486d16ec/chk-19
```
showing checkpoint 19 in progress and files from 9,15-18 being leaked in one subtask.

You may have to try several times to get an as-clear results as this one as the reproducibility is not particularly high.

