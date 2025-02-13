# azure-terraform-infrastructure
Terraform-based Azure Infrastructure Automation Project

Terraform Azure Infrastructure

## Project Overview

This project demonstrates how to use Terraform to automate the deployment of a secure cloud infrastructure in Microsoft Azure. The setup includes networking, virtual   machines, databases, monitoring, and security best practices.

## Infrastructure Deployed

  The Terraform script provisions the following resources:

  Azure Resource Group (Terraform-RG)

  Virtual Network (VNet) with two subnets:

  VM-Subnet (For Virtual Machine)

  DB-Subnet (For SQL Database)

  Network Security Groups (NSG)

  Allows SSH & HTTP for VM-Subnet

  Blocks external access for DB-Subnet

  Azure Virtual Machine (Ubuntu)

  Public IP assigned

  SSH Key authentication enabled

  Azure SQL Server & Database

  Private Endpoint for secure access

  NSG rules applied for security

  Azure Monitor & Log Analytics

  VM Diagnostics enabled

  SQL Server logs sent to Log Analytics

  Terraform Remote Backend

  Stores Terraform state in Azure Storage



# Technologies Used

Terraform (Infrastructure as Code)

Microsoft Azure (Cloud Platform)

Azure CLI (Command Line Interface for Azure)

Log Analytics & Monitoring (For resource tracking)

# Key Features & Benefits

✅ Automated Infrastructure Deployment using Terraform✅ Secure Cloud Architecture with private networking & NSG rules✅ Infrastructure as Code (IaC) for easy scalability✅ Remote Terraform State Storage for collaboration✅ Cost-Efficient Resources using Free-tier & low-cost configurations
