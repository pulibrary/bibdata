# Alma Events

## Bibdata events page

- Go to [Bibdata events page](https://bibdata.princeton.edu/events).
- Check the timestamps for specific dates that you suspect events are missing. 
1. Check if the IndexManager is stuck in an old event
- See [Dump fails to index](dump_fails_to_index.md)
- If the `last_dump_completed_id` is the latest dump_id the latest event is connected to in the [Bibdata events page](https://bibdata.princeton.edu/events) then move to step 

2. Check the Alma Publishing Jobs 

- Go to [Alma UI](https://princeton.alma.exlibrisgroup.com/) -> Resources -> Publishing Profiles -> Incremental Publishing -> (ellipsis button) History
- If there are no recent 'Publishing Platform Job Incremental Publishing', then Bibdata will not have any events.
    - Having in mind the schedule of the publishing jobs, if you expect to see 'Publishing Platform Job Incremental Publishing' and you don't let the Alma Tech team know. 
- If there are recent 'Publishing Platform Job Incremental Publishing' jobs that you would expect to see in the [Bibdata events page](https://bibdata.princeton.edu/events) then go to step 3.

3. Check the Cloud Watch Log Groups
- Go to [Cloud Watch Log Groups](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups)
- Search for `alma-webhook-monitor-production`
- Click on [webhook-monitor-production link](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Falma-webhook-monitor-production-WebhookReceiver-BW6nlZ7oExfC)
- Scroll down and click on 'Search all Log streams' button
- Set an absolute custom date search
- Search for the 'process id' of the Incremental Publishing job that is in ALma but not in bibdata. 
- If it can't find the message try in 5 mins. Sometimes there is a small delay. 
- If you can't find the message in the current search it means that either it is a very old message and not in the log or it was moved to the 'DeadLetterQueue'. If the message for any reason was deleted there is no way to recover it. 
   - Check the DeadLetterQueue. The messages are retained for a 14 days period.

        - Go to the [SQS simple Queue page](https://us-east-1.console.aws.amazon.com/sqs/v3/home)?region=us-east-1#/queues. 
        - Click on  [DeadLetterAlmaBibExportProduction.fifo](https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F080265008837%2FDeadLetterAlmaBibExportProduction.fifo). 
        - click on 'Send and Receive'
        - scroll down and Poll messages. The max count of messages that it will display is 10. If you search for a process id that is most recent and there are a lot of messages in the DLQ then it will not find it. In this case you should delete the older messages with an Alma process id that exists as an event in Bibdata so that you can retrieve the process id you're looking for. 
        - If you find the Id and you still want to redrive it to the production Queue then see more details in [configure-dead-letter-queue-redrive](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-dead-letter-queue-redrive.html).
        - If you are missing events it might be easier to schedule a Full reindex.
- If you are able to find the message in the the current search then probably it is 'in Flight' and blocked by a requeueing that is happening because of a bug in Bibdata see [Bibdata ticket#2462](https://github.com/pulibrary/bibdata/issues/2462).
- To confirm go to [SQS simple Queue page](https://us-east-1.console.aws.amazon.com/sqs/v3/home)
- Search for 'AlmaBibExportProduction.fifo'. Column 'Messages in flight' has 1 event. This is the event that is requeued as many times as the 'Maximum Receives' setting. Find the 'Maximum Receives' setting in [AlmaBibExportProduction.fifo/edit](https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F080265008837%2FAlmaBibExportProduction.fifo/edit). You can adjust the value in the UI but also remember to adjust it in the codebase [maxReceiveCount](https://github.com/pulibrary/bibdata/blob/300674aa0e6cbc3fa3e67b9e845075a202c69e0b/webhook_monitor/template.yml#L43)
    