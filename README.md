# 🚀 CloudStruct: Serverless Backend with AWS Fargate, Aurora and Event-Driven Lambda CI/CD Automation (Dev Branch)

![Architecture Diagram](AWS-ECS-Fargates.png)

This repository contains Terraform Infrastructure as Code (IaC) for a serverless application platform deployed on AWS. The `Dev-ECS-Fargate` branch provides a development environment configuration leveraging cloud services including ECS Fargate, Lambda functions, Aurora Serverless v2, and EventBridge to create a fully managed, auto-scaling infrastructure with zero server maintenance.

## 🎬 Demo

Watch the complete demo of this architecture on YouTube:
[CloudStruct Enterprise Architecture Demo](https://youtu.be/sUY1-sckJwY?si=bQfHPIHI66gKs0cp)

## ⚡ Quick Start

Want to deploy this infrastructure quickly? Follow these steps:

1. **Clone the repository (development branch)**
   ```bash
   git clone -b Dev-ECS-Fargate https://github.com/CaringalML/CloudStruct-Serverless-Backend-with-AWS-Fargate-Aurora-and-Event-Driven-Lambda-CI-CD-Automation.git
   cd CloudStruct-Serverless-Backend-with-AWS-Fargate-Aurora-and-Event-Driven-Lambda-CI-CD-Automation
   ```

2. **Configure AWS CLI**
   First, create IAM access keys in the AWS console (IAM → Users → Your User → Security credentials → Create access key).
   Then configure your AWS CLI:
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your preferred region (e.g., ap-southeast-2)
   # Enter your preferred output format (e.g., json)
   ```

3. **Create terraform.tfvars file**
   Create a file named `terraform.tfvars` with the following content:
   ```
   # Required database variables
   db_name     = "mydb"
   db_username = "admin"
   db_password = "your-secure-password"
   ```

4. **Deploy with Terraform**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Set up GitHub Actions for CI/CD**
   After deployment, add these secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `DB_SERVER` (from terraform output: `terraform output rds_endpoint`)
   - `DB_NAME`, `DB_USER`, `DB_PASSWORD` (from your terraform.tfvars)
   - `ECR_REPOSITORY` (default: "my-api")

6. **Push code to trigger deployment**
   Push to the `Dev-ECS-Fargate` branch or manually trigger the GitHub Action

**⚠️ Important Notes**:
- Make sure your app has a health check endpoint at `/api/health` (configurable in variables.tf)
- To destroy the infrastructure, simply run `terraform destroy`
- Container images use the tag "jellybean" by default (configurable in variables.tf)
- **Cost optimization**: No NAT gateways are deployed in this configuration, significantly reducing costs
- The infrastructure includes an S3 Gateway Endpoint which optimizes costs
- **Before deployment**: You must register your domain in Route 53 and create a hosted zone for it, then update the `domain_name` variable in `variables.tf` to match your registered domain (current default: "artisantiling.co.nz")

## ⚙️ Default Configuration

The infrastructure is preconfigured with development-friendly defaults:

- Environment is set to "development" by default
- 1 ECS task running by default (`desired_count = 1`)
- Auto-scaling configured to scale up to 20 tasks and down to 2 tasks
- Container resources: 0.25 vCPU (256 units) and 0.5GB RAM (512 MiB)
- Aurora database in private subnets for security
- **No NAT gateways** are deployed, reducing costs significantly
- Tasks in public subnets have public IPs for internet access

## 🔧 Key Configuration Variables

The infrastructure is customizable through variables defined in `variables.tf`. Here are the key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name | `"development"` |
| `project_name` | Base name for resources | `"CloudStruct"` |
| `aws_region` | AWS region | `"ap-southeast-2"` |
| `domain_name` | Primary domain name | `"artisantiling.co.nz"` |
| `desired_count` | Desired number of ECS tasks | `1` |
| `container_cpu` | CPU units for container (1024 = 1 vCPU) | `256` |
| `container_memory` | Memory for container in MiB | `512` |
| `max_capacity` | Maximum tasks for auto-scaling | `20` |
| `min_capacity` | Minimum tasks for auto-scaling | `2` |
| `health_check.path` | Health check path | `"/api/health"` |
| `image_tag` | Docker image tag to deploy | `"jellybean"` |

For a complete list of variables and their descriptions, refer to the variables.tf file.

## 📦 Why Containerized Deployment?

This infrastructure uses containerized deployments on ECS Fargate, providing numerous advantages over traditional deployment methods:

### 🔄 Flexibility and Consistency
- **Environment Consistency**: Containers ensure the application runs the same way in all environments—development, testing, and production
- **Technology Agnostic**: Package any application stack in containers regardless of language or framework
- **Microservices Architecture**: Enables breaking down complex applications into smaller, independent services

### 🚄 Operational Benefits
- **Simplified Deployments**: Push container images to ECR, and the automated pipeline handles the rest
- **Rapid Scaling**: Containers start in seconds, allowing rapid scaling to handle traffic spikes
- **Resource Efficiency**: Only pay for the exact CPU and memory resources your containers use
- **Isolation**: Application dependencies are encapsulated within containers, preventing conflicts

### 🔄 DevOps Integration
- **CI/CD Friendly**: Containerization fits perfectly into automated deployment pipelines
- **Infrastructure as Code**: All container configurations are defined in Terraform
- **Immutable Infrastructure**: Each deployment creates fresh container instances, eliminating configuration drift

## 🏗️ Architecture Overview

The infrastructure implements a modern, scalable architecture with the following components:

- VPC with public and private subnets across two availability zones
- ECS Fargate for container orchestration
- Aurora MySQL Serverless v2 for database
- Application Load Balancer for traffic distribution
- ACM for SSL/TLS certificate management
- Route 53 for DNS management
- ECR for container image storage
- Auto-scaling based on CPU, memory, and request count
- Automated deployment pipeline via EventBridge and Lambda

## 🧩 Infrastructure Components

### 🌐 Networking (vpc.tf)

- **VPC**: Large IP address space (10.0.0.0/16) with 65,536 available IP addresses
- **Subnets**: 
  - 2 public subnets (10.0.0.0/20, 10.0.16.0/20) with 4,096 IPs each
  - 2 private subnets (10.0.32.0/20, 10.0.48.0/20) with 4,096 IPs each
- **Internet Gateway**: For public subnet internet access
- **No NAT Gateways**: Cost optimization for development - tasks run in public subnets with public IPs
- **S3 VPC Endpoint**: For secure access to S3 without traversing the internet

### 🗄️ Container Registry (ecr.tf)

- Amazon ECR repository for storing container images
- Image scanning on push for security vulnerability detection
- Lifecycle policy to limit repository to the latest 3 images

### 🐳 Container Orchestration (cluster.tf, task-definition.tf, ecs-fargate-service.tf)

- ECS cluster with FARGATE and FARGATE_SPOT capacity providers
- Task definition with resource allocation (256 CPU units, 512MB memory)
- Service configuration with capacity provider strategy
- Auto-scaling policies based on:
  - CPU utilization (70%)
  - Memory utilization (80%)
  - Request count per target (1000)

### ⚖️ Load Balancing (alb.tf)

- Application Load Balancer for traffic distribution
- Target group with health checks at `/api/health`
- HTTP to HTTPS redirect
- Sticky sessions for maintaining user state

### 💾 Database (aurora-mysql.tf)

- Aurora MySQL Serverless v2 cluster
- Database in private subnets for security
- Autoscaling from 0.5 to 1 ACU in development (Aurora Capacity Units)

### 🔒 Security (security-group.tf, iam.tf)

- Security groups with least privilege access:
  - ALB: Accept HTTP/HTTPS from internet
  - Fargate: Accept traffic only from ALB
  - Database: Accept traffic only from Fargate tasks
- IAM roles for:
  - ECS task execution
  - ECS task (application permissions)
  - Lambda execution

### 🔐 SSL/TLS and DNS (acm.tf, route53-dns-record.tf)

- ACM certificate for domain with DNS validation
- Route 53 A record for `server.example.com` pointing to ALB
- Optional wildcard certificate for subdomains
- Requires an existing Route 53 hosted zone for your domain

### 📊 Monitoring and Logging (cloudwatch.tf)

- CloudWatch Log Groups for ECS services with 30-day retention
- Container Insights enabled for enhanced monitoring

### 🔄 Continuous Deployment (ecs-update-service.tf)

- EventBridge rule to monitor ECR image pushes with tag "jellybean"
- Lambda function to trigger ECS service updates automatically
- **Python Lambda Packaging**: Automatic code generation and ZIP packaging during `terraform apply`

## 🔄 CI/CD Workflow

This project includes a GitHub Actions workflow for continuous integration and deployment, which automatically:

1. Builds the application container image
2. Creates an `appsettings.json` with database connection strings using GitHub secrets 
3. Pushes the image to Amazon ECR with the tag "jellybean"
4. Triggers automatic deployment via the EventBridge and Lambda function

## 🔍 Monitoring the Database Configuration

You can view the VPC configuration of your Aurora database using this AWS CLI command:

```bash
aws rds describe-db-subnet-groups --db-subnet-group-name cloudstructdevelopmentaurora
```

This will display the VPC ID and subnet IDs used by your Aurora database.

To check the database instances and other configuration details:

```bash
aws rds describe-db-clusters --db-cluster-identifier cloudstructdevelopmentaurora
```

## 🔒 Security Considerations

- The `terraform.tfvars` file is included in `.gitignore` to prevent committing sensitive information
- You must create your own `terraform.tfvars` file locally with database credentials
- Database credentials are securely stored as GitHub Actions secrets and injected during deployment
- Database has `skip_final_snapshot` set to true by default
- For additional security, consider using AWS Secrets Manager for runtime credential access

## 🔧 Maintenance and Operations

### 📈 Scaling

The infrastructure automatically scales based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Request count per target (target: 1000)

You can adjust these values in `variables.tf`.

### 🔄 Updating the Application

The application updates automatically through the CI/CD pipeline:

1. Make changes to your application code
2. Commit and push to the `Dev-ECS-Fargate` branch
3. GitHub Actions will build a new container image with the "jellybean" tag
4. The image is pushed to ECR, triggering the EventBridge rule
5. The Lambda function detects the new image and updates the ECS service
6. The ECS service performs a rolling deployment of the new version

You can also manually trigger the workflow using GitHub Actions' workflow_dispatch event.

## Cost Optimization Recommendations

The following optimization strategies could significantly reduce your infrastructure costs:

### Development Environment Optimizations

1. **NAT Gateway Elimination** (-$127.50/month)
   - The development environment completely removes NAT Gateways
   - Tasks run in public subnets with public IPs for internet access
   - Savings: 100% of NAT Gateway costs ($127.50/month)
   - Trade-off: Slightly different network architecture than production

2. **Aurora Single Instance** (-$86.40/month)
   - Development uses only one Aurora instance instead of two
   - Eliminates Multi-AZ redundancy for development purposes
   - Savings: 50% of database instance costs
   - Trade-off: No automatic failover in development

3. **Reduced Task Count** (-$70-140/month)
   - Development runs with a default desired count of 1 task (vs. 2+ in production)
   - Minimum auto-scaling capacity reduced to match
   - Savings: 50% or more of baseline Fargate costs
   - Trade-off: Less capacity to handle sudden traffic spikes

### Additional Cost-Saving Opportunities

4. **Fargate Spot Optimization** (-$130/month)
   - Modify capacity provider strategy:
     ```hcl
     capacity_provider_strategy {
       capacity_provider = "FARGATE"
       base              = 1     # Reduced from 2
       weight            = 1
     }
     capacity_provider_strategy {
       capacity_provider = "FARGATE_SPOT"
       base              = 0
       weight            = 9     # Increased from 3
     }
     ```
   - Increase Fargate Spot usage from 60% to 90%
   - Estimated savings: 20-25% of Fargate costs ($130-165/month at average load)
   - Trade-off: Slight increase in potential workload interruptions

5. **Aurora Serverless Minimum Capacity** (-$25/month)
   - Reduce minimum capacity from 0.5 ACU to 0.1 ACU (minimum allowed)
   - Update `serverlessv2_scaling_configuration` block:
     ```hcl
     serverlessv2_scaling_configuration {
       min_capacity = 0.1
       max_capacity = 4
     }
     ```
   - Savings: ~$25/month during low usage periods
   - Trade-off: Slightly longer cold start times

6. **CloudWatch Log Optimization** (-$15/month)
   - Reduce log retention from 30 days to 7 days:
     ```hcl
     variable "log_retention_days" {
       default = 7  # Changed from 30
     }
     ```
   - Implement log filtering in task definition to reduce volume:
     ```hcl
     logConfiguration = {
       logDriver = "awslogs"
       options = {
         # Existing options...
         "awslogs-attributes" = "logFilters=[{name=exclude,pattern=\"DEBUG\"}]"
       }
     }
     ```
   - Estimated savings: $15-30/month

### Medium-Term Optimizations

7. **Right-Size Container Resources** (-$90/month)
   - After 2-3 weeks of monitoring, adjust container CPU/memory based on actual usage
   - If containers show <50% CPU utilization consistently, reduce from 256 to 128 CPU units
   - Potential savings: ~15% of Fargate costs ($90/month at average load)

8. **Load Balancer Optimization** (-$10/month)
   - Review if HTTP-to-HTTPS redirect rule is necessary
   - Consider using a Network Load Balancer instead of Application Load Balancer for simple use cases
   - Potential savings: $10-15/month

9. **Auto-Scaling Tuning** (-$30/month)
   - Review and adjust your scaling thresholds:
     ```hcl
     target_tracking_scaling_policy_configuration {
       # Current configuration:
       # cpu_target_value = 70
       # memory_target_value = 80
       # request_count_target = 1000
       
       # More aggressive scaling:
       cpu_target_value = 80
       memory_target_value = 85
       request_count_target = 1200
     }
     ```
   - Increase `scale_in_cooldown` to prevent thrashing
   - Estimated savings: 5-10% of Fargate costs ($30-66/month at average load)

### Long-Term Strategic Optimizations

10. **Reserved Compute Pricing** (-$200/month)
    - For long-term workloads, consider Compute Savings Plans for a 1-year commitment
    - Apply to baseline Fargate capacity (not Spot instances)
    - Potential savings: Up to 30% on committed compute usage ($200/month)

11. **Container Image Optimization** (-$40/month)
    - Minimize container image size with multi-stage builds
    - Implement application-level caching to reduce compute needs
    - Potential resource reduction: 5-10% of compute costs ($40-65/month)

12. **Aurora Read Replicas Optimization** (-$45/month)
    - Consider using a single instance during development/staging
    - For production, use second replica only for critical periods
    - When using two instances, leverage reader endpoint for appropriate queries
    - Potential savings: ~$45/month if one instance is scaled down during low traffic

### Simple Cost Savings Summary

Here's a straightforward breakdown of potential monthly savings from each optimization:

**Development Environment Savings (Already Implemented)**
- **Elimination of NAT Gateways**: Save $127.50/month
- **Single Aurora Instance**: Save $86.40/month
- **Reduced Task Count**: Save $70-140/month
- **Development Savings Total**: Save $283.90-353.90/month

**Quick Wins (Implement in 1-2 days)**
- **Increase Fargate Spot usage to 90%**: Save $130/month
- **Reduce Aurora minimum capacity**: Save $25/month
- **Set CloudWatch log retention to 7 days**: Save $15/month
- **Quick Wins Total**: Save $170/month

**Medium Effort (Implement in 1-2 weeks)**
- **Right-size container CPU and memory**: Save $90/month
- **Optimize Load Balancer settings**: Save $10/month
- **Tune auto-scaling thresholds**: Save $30/month
- **Medium Effort Total**: Save $130/month

**Strategic Changes (Implement in 1-2 months)**
- **Purchase Compute Savings Plans**: Save $200/month
- **Optimize container images**: Save $40/month
- **Optimize Aurora read replicas**: Save $45/month
- **Strategic Changes Total**: Save $285/month

**GRAND TOTAL SAVINGS: $868.90-938.90/month ($10,426.80-11,266.80/year)**

This represents a 74-80% reduction from the average monthly cost of $1,164.

**Bottom Line**: Your optimized infrastructure could cost as little as $225-295/month while maintaining the same capabilities.

## Assumptions and Notes

- All prices are based on AWS Sydney (ap-southeast-2) region pricing as of March 2025.
- The actual costs will vary based on usage patterns, data transfer, and scaling activities.
- This estimate does not include potential AWS Free Tier benefits.
- Data transfer costs between services within the same region are minimal and not fully itemized.
- Costs for AWS support plans are not included.

## Monitoring Actual Costs

To monitor and manage your actual AWS costs:

1. Set up AWS Budgets and Cost Anomaly Detection
2. Review the AWS Cost Explorer regularly
3. Tag resources appropriately for cost allocation
4. Consider using AWS Cost and Usage Reports for detailed analysis

---

*This cost estimation is provided as guidance only. Actual costs may vary based on usage patterns and AWS pricing changes.*


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Contributor

- Martin Lawrence M. Caringal
  - Email: lawrencecaringal5@gmail.com
  - Phone: 0221248553