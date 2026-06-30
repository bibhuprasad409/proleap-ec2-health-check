# ProLEAP EC2 Health Check Project

## Objective
This project performs automated health checks on an Ubuntu AWS EC2 web server.

## AWS Services Used
- EC2
- Security Groups
- IAM
- VPC networking

## Technologies Used
- Ubuntu Linux
- Bash
- Nginx
- Git
- GitHub

## Checks Performed
- Server identity
- Operating system information
- System uptime
- CPU load
- Memory usage
- Disk usage
- Top processes
- Nginx service status
- Port 80 status
- Localhost website test
- Public website test
- Internet connectivity
- DNS resolution

## How to Run

chmod +x scripts/ec2-health-check.sh
bash scripts/ec2-health-check.sh

## Save Output

bash scripts/ec2-health-check.sh > logs/ec2-health-report.txt 2>&1 || true

## Expected Status
- HEALTHY: No warnings were detected.
- ATTENTION REQUIRED: One or more warnings were detected.

## Author
Bibhu Prasad Panigrahy

## Batch
PLA - The One May 2026
