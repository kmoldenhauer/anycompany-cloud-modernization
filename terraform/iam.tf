# terraform/iam.tf

# -------------------------------------------------------------
# 1. EKS Cluster Control Plane IAM Role
# -------------------------------------------------------------

# Trust policy: Allows the AWS EKS service to assume this role
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

# Attach standard Amazon EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Attach Block Storage policy (needed by EKS Auto Mode for automated volume provisioning)
resource "aws_iam_role_policy_attachment" "eks_cluster_block_storage" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Attach Compute policy (needed by EKS Auto Mode to manage EC2 nodes)
resource "aws_iam_role_policy_attachment" "eks_cluster_compute" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Attach Load Balancing policy (needed by EKS Auto Mode to manage ALBs/NLBs automatically)
resource "aws_iam_role_policy_attachment" "eks_cluster_load_balancing" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Attach Networking policy (needed by EKS Auto Mode to configure VPC CNI IPs)
resource "aws_iam_role_policy_attachment" "eks_cluster_networking" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# -------------------------------------------------------------
# 2. EKS Auto Mode Worker Node IAM Role
# -------------------------------------------------------------

# Trust policy: Allows EC2 worker instances to assume this role
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The IAM Role referencing the exact same name
resource "aws_iam_role" "eks_node" {
  name               = "${var.project_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = {
    Name = "${var.project_name}-eks-node-role"
  }
}
# Minimal Worker Node Policy
resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.eks_node.name
}

# Container Registry Pull Policy
resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_node.name
}

# VPC CNI Policy (allows pods to get real private VPC IP addresses)
resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# Standard Worker Node Policy
resource "aws_iam_role_policy_attachment" "node_general" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

# Explicit Instance Profile attached to the Node Role
resource "aws_iam_instance_profile" "eks_node" {
  name = "${var.project_name}-eks-node-profile"
  role = aws_iam_role.eks_node.name
}