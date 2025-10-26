# ChatOps with Security Alarms Example

This example demonstrates how to deploy ChatOps infrastructure with **enterprise-grade security monitoring** enabled.

## 🔒 Security Features

When `enable_security_alarms = true`, this example includes:

### **CloudWatch Security Alarms**
- **High request rate** - DDoS detection (50+ requests/5min)
- **High error rate** - Attack detection (10+ 4XX errors/5min)
- **Lambda errors** - Function failure monitoring (5+ errors/5min)
- **Lambda duration** - Timeout attack detection (25+ seconds)
- **Large payloads** - Oversized request detection (5+ sec latency)
- **API throttling** - Rate limit violation monitoring (5+ throttles/5min)

### **Enhanced Logging**
- **Security-focused log groups** - 7-day retention
- **Enhanced API Gateway logging** - Includes user agent, error details
- **Custom security metrics** - Authentication failures, validation failures

### **SNS Notifications**
- **Real-time alerts** - Immediate notification of security events
- **Configurable thresholds** - Adjustable alarm sensitivity

## 💰 Cost Impact

### **Security Disabled (Default)**
- **Additional cost**: $0
- **Request validation**: Free
- **Basic logging**: 7 days

### **Security Enabled**
- **SNS notifications**: ~$1/month
- **Security log retention**: ~$1/month
- **CloudWatch alarms**: ~$1/month
- **Total additional cost**: ~$3/month

## 🚀 Usage

### **1. Basic Deployment (No Security)**
```hcl
module "chatops" {
  source = "../../"
  
  # ... other variables
  enable_security_alarms = false  # Default
}
```

### **2. Enterprise Deployment (With Security)**
```hcl
module "chatops" {
  source = "../../"
  
  # ... other variables
  enable_security_alarms = true   # Enable security monitoring
}
```

## 📊 Security Monitoring

### **Alarm Thresholds**
- **Request rate**: 50 requests in 5 minutes
- **Error rate**: 10 4XX errors in 5 minutes
- **Lambda errors**: 5 errors in 5 minutes
- **Lambda duration**: 25 seconds average
- **Large payloads**: 5 seconds integration latency
- **API throttling**: 5 throttled requests in 5 minutes

### **Log Retention**
- **Security logs**: 7 days
- **Enhanced API logs**: 7 days
- **Regular logs**: 7 days (configurable)

## 🛡️ Security Benefits

1. **DDoS Protection** - High request rate detection
2. **Attack Prevention** - Error rate monitoring
3. **Cost Control** - AI processing abuse prevention
4. **Performance Monitoring** - Lambda duration tracking
5. **Audit Trail** - Comprehensive security logging
6. **Real-time Alerts** - Immediate notification of security events

## 📋 Prerequisites

- AWS CLI configured
- Terraform installed
- Lambda ZIP files ready
- GitHub token and Telegram bot token

## 🚀 Deployment

```bash
# 1. Initialize Terraform
terraform init

# 2. Create terraform.tfvars
cat > terraform.tfvars << EOF
github_owner = "your-org"
github_repo = "your-repo"
github_token = "ghp_..."
telegram_bot_token = "123456:ABC-DEF-..."
authorized_chat_id = "123456789"
s3_bucket_arn = "arn:aws:s3:::your-bucket"
EOF

# 3. Plan deployment
terraform plan

# 4. Deploy with security
terraform apply
```

## 📈 Monitoring

After deployment, monitor security events in:

- **CloudWatch Console** - View alarms and metrics
- **SNS Console** - Configure alert destinations
- **CloudWatch Logs** - Review security logs
- **Lambda Console** - Monitor function performance

## 🔧 Customization

### **Adjust Alarm Thresholds**
Modify the security module to change alarm sensitivity:

```hcl
# In modules/core/security/main.tf
threshold = "100"  # Increase from 50 to 100 requests
```

### **Add Email Notifications**
```hcl
# Add to terraform.tfvars
notification_email = "security@yourcompany.com"
```

### **Extend Log Retention**
```hcl
# In main.tf
log_retention_days = 30  # Increase from 7 to 30 days
```

## 🎯 Best Practices

1. **Start with security disabled** - Deploy basic version first
2. **Enable security gradually** - Test alarms in staging
3. **Monitor costs** - Security adds ~$3/month
4. **Configure notifications** - Set up SNS endpoints
5. **Review logs regularly** - Check security events weekly

## 🆚 Comparison

| Feature | Basic | With Security |
|---------|-------|---------------|
| **Cost** | $6.80/month | $9.80/month |
| **Monitoring** | Basic logs | Full security suite |
| **Alerts** | None | Real-time notifications |
| **Protection** | Basic | Enterprise-grade |
| **Compliance** | Basic | Enterprise-ready |

Choose based on your security requirements and budget! 🛡️
