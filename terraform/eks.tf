# terraform/eks.tf

# -------------------------------------------------------------
# 1. Fetch Current AWS Caller Identity
#    (Automatically gets your AWS user/role ID so you have admin access)
# -------------------------------------------------------------
data "aws_caller_identity" "current" {}

# -------------------------------------------------------------
# 2. EKS Cluster Security Group
# -------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS control plane communication"
  vpc_id      = aws_vpc.main.id

  # Outbound: Allow cluster to talk to worker nodes and AWS services
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

# -------------------------------------------------------------
# 3. The EKS Cluster with Auto Mode Enabled
# -------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31" # Latest standard EKS version supporting Auto Mode

  vpc_config {
    # Place cluster interfaces across private subnets and public subnets
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true # Allows you to run kubectl from your computer
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # --- EKS AUTO MODE CONFIGURATION BLOCKS ---

  # 1. Automatic compute (AWS provisions and scales worker nodes dynamically)
  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.eks_node.arn
  }

  # 2. Automatic block storage (EBS CSI driver handled natively)
  storage_config {
    block_storage {
      enabled = true
    }
  }

  # 3. Modern IAM Access Management (replaces legacy aws-auth ConfigMap)
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensure IAM role attachments exist before AWS creates the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_compute,
    aws_iam_role_policy_attachment.eks_cluster_block_storage,
    aws_iam_role_policy_attachment.eks_cluster_load_balancing,
    aws_iam_role_policy_attachment.eks_cluster_networking,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_ecr
  ]

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# -------------------------------------------------------------
# 4. Cluster Access Entry for your local AWS Identity
# -------------------------------------------------------------
resource "aws_eks_access_entry" "admin_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_user]
}