GET {{ host }}/api/v1/livez
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.status" == "OK"

GET {{ host }}/api/v1/tasks/scheduled
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.type" == "scheduled_task"
jsonpath "$.data" count == 0

POST {{ host }}/api/v1/tasks
Content-Type: application/json
{
    "task_id": "start-game",
    "scheduled_time": "* * * * *",
    "args": {
        "room_id": "1"
    }
}
HTTP 202
[Asserts]
jsonpath "$.type" == "scheduled_task"
jsonpath "$.data.command" == "cli start-game 1"
jsonpath "$.data.cron" == "* * * * *"
[Captures]
taskUuid: jsonpath "$.data.id"
 

DELETE {{ host }}/api/v1/tasks/{{taskUuid}}
Content-Type: application/json
HTTP 204

POST {{ host }}/api/v1/tasks
Content-Type: application/json
{
    "task_id": "start-game",
    "scheduled_time": "wrong-cron",
    "args": {
        "room_id": "1"
    }
}
HTTP 422
[Asserts]
jsonpath "$.type" == "error"
jsonpath "$.error" == "wrong-cron is not a valid input"

POST {{ host }}/api/v1/tasks
Content-Type: application/json
{
    "task_id": "9999999",
    "scheduled_time": "1 1 1 1 1",
    "args": {
        "room_id": "1"
    }
}
HTTP 422
[Asserts]
jsonpath "$.type" == "error"
jsonpath "$.error" == "command not found"


