# SwasthyaAI Monitoring Setup

## ✅ CloudWatch Dashboard

**Dashboard Name:** SwasthyaAI-Dashboard

**Dashboard URL:** https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=SwasthyaAI-Dashboard

### Dashboard Widgets

1. **Lambda Invocations** - Track all Lambda function calls
2. **Lambda Errors & Throttles** - Monitor error rates and throttling
3. **Lambda Duration** - Average and maximum execution times
4. **API Gateway Requests** - Total requests, 4XX and 5XX errors
5. **API Gateway Latency** - Average and p99 latency
6. **Recent Errors** - Log insights showing recent error messages

## ✅ CloudWatch Alarms

### Lambda Alarms

| Alarm Name | Metric | Threshold | Status |
|------------|--------|-----------|--------|
| swasthyaai-patient-chatbot-high-errors | Errors | > 5 in 10 min | ✓ OK |
| swasthyaai-clinical-summarizer-high-errors | Errors | > 5 in 10 min | ⚠️ Insufficient Data |
| swasthyaai-bedrock-throttle-dev | Throttles | > 3 in 5 min | ⚠️ Insufficient Data |

### API Gateway Alarms

| Alarm Name | Metric | Threshold | Status |
|------------|--------|-----------|--------|
| swasthyaai-api-high-5xx-errors | 5XXError | > 10 in 10 min | ⚠️ Insufficient Data |
| swasthyaai-api-high-latency | Latency | > 5000ms avg | ⚠️ Insufficient Data |

**Note:** "Insufficient Data" means the alarm hasn't collected enough metrics yet. This is normal for newly created alarms.

## Alarm Actions

All alarms are configured to send notifications to:
- **SNS Topic:** arn:aws:sns:us-east-1:348103269436:swasthyaai-alerts-dev

### Subscribe to Alerts

To receive email notifications when alarms trigger:

```powershell
aws sns subscribe `
  --topic-arn arn:aws:sns:us-east-1:348103269436:swasthyaai-alerts-dev `
  --protocol email `
  --notification-endpoint your-email@example.com `
  --region us-east-1
```

Then confirm the subscription via the email you receive.

## Monitoring Best Practices

### 1. Regular Dashboard Review
- Check dashboard daily for anomalies
- Review error trends weekly
- Analyze latency patterns

### 2. Alarm Thresholds
Current thresholds are conservative. Adjust based on:
- Normal traffic patterns
- Business requirements
- Cost considerations

### 3. Log Retention
- Lambda logs: Retained in CloudWatch
- API Gateway logs: Enabled with 14-day retention
- Consider archiving to S3 for long-term storage

### 4. Cost Optimization
- Use CloudWatch Logs Insights for ad-hoc queries
- Set up log retention policies
- Archive old logs to S3 Glacier

## Additional Monitoring Commands

### View Recent Lambda Errors
```powershell
aws logs filter-log-events `
  --log-group-name /aws/lambda/swasthyaai-patient-chatbot-dev `
  --filter-pattern "ERROR" `
  --max-items 10 `
  --region us-east-1
```

### Check Lambda Metrics
```powershell
aws cloudwatch get-metric-statistics `
  --namespace AWS/Lambda `
  --metric-name Invocations `
  --dimensions Name=FunctionName,Value=swasthyaai-patient-chatbot-dev `
  --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss") `
  --end-time (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss") `
  --period 300 `
  --statistics Sum `
  --region us-east-1
```

### List All Alarms
```powershell
aws cloudwatch describe-alarms `
  --alarm-name-prefix "swasthyaai" `
  --region us-east-1 `
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]' `
  --output table
```

## X-Ray Tracing

X-Ray tracing is enabled for:
- API Gateway stage
- Lambda functions (via environment variables)

### View X-Ray Service Map
https://console.aws.amazon.com/xray/home?region=us-east-1#/service-map

### Analyze Traces
```powershell
aws xray get-trace-summaries `
  --start-time (Get-Date).AddHours(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --end-time (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --region us-east-1
```

## Cost Monitoring

### Set Up Budget Alert
```powershell
# Create a budget for SwasthyaAI resources
aws budgets create-budget `
  --account-id 348103269436 `
  --budget file://budget-config.json
```

### Monitor Daily Costs
Check AWS Cost Explorer:
https://console.aws.amazon.com/cost-management/home?region=us-east-1#/dashboard

Filter by tag: `Project=SwasthyaAI`

## Troubleshooting

### High Error Rate
1. Check CloudWatch Logs for error details
2. Review recent code deployments
3. Check Bedrock service limits
4. Verify IAM permissions

### High Latency
1. Check Lambda cold start times
2. Review Bedrock model response times
3. Analyze API Gateway integration latency
4. Consider increasing Lambda memory

### Throttling
1. Check Lambda concurrent execution limits
2. Review Bedrock quota limits
3. Consider requesting limit increases
4. Implement exponential backoff

## Next Steps

1. ✅ Subscribe to SNS topic for email alerts
2. ✅ Review dashboard daily for first week
3. ✅ Adjust alarm thresholds based on traffic
4. ⬜ Set up custom metrics for business KPIs
5. ⬜ Create runbooks for common issues
6. ⬜ Implement automated remediation with Lambda

## Summary

✅ CloudWatch Dashboard created with 6 widgets
✅ 5 CloudWatch Alarms configured
✅ SNS notifications enabled
✅ X-Ray tracing active
✅ Log retention configured

Your SwasthyaAI application now has comprehensive monitoring in place!
