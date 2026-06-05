8byte.ai assigment:
->Submitted by :Vigneshwar Ravindran

# What exactly I  want:

A end to end devops project on aws : from infrastructure from terraform, CI/Cd pipeline via jenkins and monitoring via aws cloudwatch, vulnerability scanning by trivy

The idea was simple: we need to push code , test run , docker image will get created and scanned , deployment will automatically will go to staging and a manual approval before it go to prodiction

# Architecture:

internet -> ALB(public subnet , ap-south-1a and 1b) -> EC2(t3.small) -> rds(isolated db subnet no internet access)

Everything lives inside a single vpc ( (10.0.0.0/16) across 2 avaibility zones. the ec2 is in private subnet so it is not directly reachable to internet only the load balacer is public facing

The database is only reachable from ec2 security group

# Repository structure:

8byte-devops/               ← this repo (infrastructure)
└── infra/
    ├── main.tf             provider + S3 remote state
    ├── variables.tf        all configurable inputs
    ├── outputs.tf          ALB DNS, instance ID, RDS endpoint
    ├── vpc.tf              VPC, 6 subnets across 2 AZs, IGW, route tables
    ├── security_groups.tf  3-tier SG chain: ALB → EC2 → RDS
    ├── ec2.tf              instance, AMI lookup, IAM role, SSM access
    ├── rds.tf              PostgreSQL, subnet group, automated backups
    ├── alb.tf              ALB, target group, health check, listener
    ├── vpc_endpoints.tf    SSM/EC2Messages/S3 endpoints for private subnet
    └── monitoring.tf       CloudWatch dashboards, log groups, alarms

simple-node-app/            <- separate repo (application)
├── index.js                Node.js HTTP server with /health endpoint
├── index.test.js           Jest tests for all routes
├── package.json
├── Dockerfile
└── Jenkinsfile             full CI/CD pipeline definition

# Part 1 —Infrastructure(Terraform)
 # Prerequisites
- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- An S3 bucket for remote state

 # Deploy

# Create state bucket first (one time)
aws s3 mb s3://8byte-bucket --region ap-south-1

# Deploy everything

cd infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan 

# Infra created:
VPC with 6 subnets — 2 public(ALB), 2 private app(EC2), 2 private DB(RDS)
->Internet Gateway + route tables
->Security groups with proper chaining
->EC2 t3.small with IAM role for SSM + CloudWatch + ECR
->RDS PostgreSQL 15.16 in isolated subnets
->Application Load Balancer with health checks
->VPC Interface Endpoints for SSM (so EC2 in private subnet can be managed without SSH)

# After apply
alb_dns_name = "bytesapp-alb-xxxxxx.ap-south-1.elb.amazonaws.com"
instance_id  = "i-xxxxxxxxxxxxxxxxx"
rds_endpoint = <sensitive>

# Part 2 — CI/CD Pipeline(Jenkins)

stage                             what it does
Checkout                         Cleans workspace, pulls latest code 
Install Dependencies             npm install`
Run Tests                        3 tests covering all routes 
Vulnerability Scan               Trivy scan
Build Docker Image              Builds and tags with build number
Vulnerability Scan(container)   Trivy scans the built image
Push to ECR                     Pushes to AWS ECR with build number + latest tags
Deploy to Staging               SSM send-command pulls and runs latest image on EC2
Manual Approval                 Pipeline pauses — maually click to proceed 
Deploy to Production            Proceed after approval

# Accessing Jenkins

Jenkins is in a private subnet so port forwarding is needed:
aws ssm start-session --target <instance-id> --region ap-south-1 --document-name AWS-StartPortForwardingSession --parameters portNumber=8080,localPortNumber=8080

Then open http://localhost:8080

# Notifications
Pipeline sends an email on failure via Gmail SMTP. Configured in Jenkins system settings.

# Part 3 — Monitoring & Logging
# CloudWatch Dashboards

bytesapp-infrastructure — EC2 CPU, memory, disk usage + RDS connection count

bytesapp-application — ALB request count, 5XX error rate, target response time, RDS free storage

/bytesapp/system :EC2 system messages (/var/log/messages) 
/bytesapp/app :Docker container stdout/stderr
/bytesapp/jenkins :Jenkins build logs

Note: Logs retained for 7 days to keep costs low.

# Alarms:

CPU > 80% for 2 consecutive 2-minute periods  -> alarm
Memory > 85% for 2 consecutive 2-minute periods -> alarm
The CloudWatch agent is installed on EC2 and configured at /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`.

# Part 4 — Security & Best Practices
 # Security decision

 Private subnets for everything except ALB — EC2 and RDS have no public IPs. The only way in is through the ALB or SSM (for management).

Security group chaining — each layer only accepts traffic from the layer directly above it. RDS doesn't know the internet exists.

No SSH keys — access to EC2 is via SSM Session Manager. No port 22 open, no key files to manage or lose.

IAM least privilege — EC2 role has exactly three policies: SSM access, CloudWatch metrics, ECR pull/push. Nothing else.

Encrypted storage — EC2 root volume and RDS storage both encrypted at rest.

Sensitive variables — `db_password` is marked `sensitive = true` in Terraform so it never appears in logs or plan output. Passed via `TF_VAR_db_password` environment variable.

# Good practice note: Production should use AWS Secrets Manager for DB credentials and ACM + HTTPS on the ALB. Both are noted in the Terraform comments and can be added with minimal changes.

# Backup strategy
RDS automated backups are configured (7-day retention in production, 0 on free tier due to AWS restriction —see the challenges).Final snapshot taken on deletion.Terraform state is stored in S3 with encryption.

# Secret management
No credentials hardcoded anywhere. DB password passed as environment variable
export TF_VAR_db_password="our paswword"
terraform apply

production recommendation: migrate to `aws_secretsmanager and have the app fetch credentials at startup.

Cost optimization Note:The NAT Gateway is the biggest cost driver (38% of total). It was added to allow package installation from private subnets. In a production setup it could be replaced entirely with VPC endpoints for all required AWS services, bringing the cost down significantly. The EC2 and RDS are sized for the assignment — right-sizing for actual traffic would be the first production optimization.

# Known Limitations & Next Step:

GitHub webhook not configured** — Jenkins builds are triggered manually. In production, a webhook would trigger the pipeline on every push. Jenkins is in a private subnet so it needs either a public endpoint or a VPN for GitHub to reach it.
Single EC2 instance — no auto-scaling. Production would use an Auto Scaling Group behind the ALB.
- HTTP only — HTTPS requires an ACM certificate and a domain name. The ALB listener config supports this with minimal changes.
- Trivy found vulnerabilities— 17 HIGH/CRITICAL in the Alpine base image. These are in OpenSSL and musl libc. Production fix: update to latest Alpine patch release. See challenges doc for details.
























    



