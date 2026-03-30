This directory provisions K3s worker nodes that join the existing server created in `../xmaxx-infra`.

Typical flow:

1. Get the server token:

   `terraform -chdir=../xmaxx-infra output -raw k3s_join_token_command`

   Then run the printed SSH command to read the token.

2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in:

   - `vpc_id`
   - `subnet_id`
   - `k3s_url`
   - `k3s_token`

   Keep this file local until `git-crypt` is bootstrapped for the repo. After that, the exact path `xmaxx-infra-workers/terraform.tfvars` may be committed in encrypted form. See `../documentation/git-crypt.md`.

3. Apply:

   `terraform -chdir=xmaxx-infra-workers init`

   `terraform -chdir=xmaxx-infra-workers apply`
