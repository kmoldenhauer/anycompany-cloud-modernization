# terraform/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "configure_kubectl" {
  description = "Run this command in your terminal to connect kubectl to your new cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}