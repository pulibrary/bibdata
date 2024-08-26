# Alma Events

## Bibdata events page

### Production environment

- Go to [Bibdata events page](https://bibdata.princeton.edu/events).
- Check the timestamps for specific dates that you suspect events are missing. 
1. Check if the IndexManager is stuck in an old event
- See [Dump fails to index](dump_fails_to_index.md)
- If the `last_dump_completed_id` is the latest dump_id the latest event is connected to, then move to step 2.

2. Check the Alma Publishing Jobs: 

- Go to [Alma UI](https://princeton.alma.exlibrisgroup.com/) -> Resources -> Publishing Profiles -> Incremental Publishing -> (ellipsis button) History
- If there are no recent 'Publishing Platform Job Incremental Publishing' jobs, then Bibdata will not have any events.
    - Having in mind the [schedule of the publishing jobs](alma_publishing_jobs_schedule.md), if you expect to see 'Publishing Platform Job Incremental Publishing' but you don't, then let the Alma Tech team know. 
- If there are recent 'Publishing Platform Job Incremental Publishing' jobs that you expect to see in the [Bibdata events page](https://bibdata.princeton.edu/events) then go to step 3.

3. Check the Cloud Watch Log Groups:

- Go to [Cloud Watch Log Groups](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups)
- Search for `alma-webhook-monitor-production`
- Click on [webhook-monitor-production link](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Falma-webhook-monitor-production-WebhookReceiver-BW6nlZ7oExfC)
- Scroll down and click on 'Search all Log streams' button.
- Set an absolute custom date search.
- Search for the 'process id' of the Incremental Publishing job that exists in Alma but not in bibdata. 
- If the search results do not return the message then try in 2 mins. Sometimes there is a small delay. 
- If you can't find the message in the current search it means that either it is a very old message and purged from the log or it was moved to the 'DeadLetterQueue'. If the message for any reason was deleted there is no way to recover it. 
   - Check the DeadLetterQueue. [The messages are retained for 14 days](https://github.com/pulibrary/bibdata/blob/main/webhook_monitor/template.yml#L32)].

        - Go to the [SQS simple Queue page](https://us-east-1.console.aws.amazon.com/sqs/v3/home)?region=us-east-1#/queues. 
        - Click on the [DeadLetterAlmaBibExportProduction.fifo](https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws.com%2F080265008837%2FDeadLetterAlmaBibExportProduction.fifo). 
        - Click on 'Send and Receive'
        - Scroll down and Poll messages. The max count of messages that can display is 10. If you search for a process id that was created most recently and there are a lot of older messages in the DLQ then it will not find it. In this case you should delete the older messages that already exist as event in Bibdata so that you can retrieve the most recent messages. 
        - If you find the message and you still want to 'redrive' it to the production Queue then see more details in [configure-dead-letter-queue-redrive](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-configure-dead-letter-queue-redrive.html).
        - If you are missing events it might be easier to schedule a [Full reindex](indexing.md).
- If you are able to find the message in the current search then probably it is 'in Flight' and blocked by a requeueing that is happening because of a bug in Bibdata see [Bibdata ticket#2462](https://github.com/pulibrary/bibdata/issues/2462).
- To confirm go to [SQS simple Queue page](https://us-east-1.console.aws.amazon.com/sqs/v3/home)
- Search for 'AlmaBibExportProduction.fifo'. Column 'Messages in flight' has 1 event. This is the event that is requeued as many times as the [AlmaBibExportProduction.fifo/edit -> Maximum Receives]((https://us-east-1.console.aws.amazon.com/sqs/v3/home?region=us-east-1#/queues/https%3A%2F%2Fsqs.us-east-1.amazonaws) setting.
You can adjust the value in the UI but also remember to adjust it in the codebase [maxReceiveCount](https://github.com/pulibrary/bibdata/blob/main/webhook_monitor/template.yml#L43)
    