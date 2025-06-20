# Simple UX targets
# -----------------

up: tfinit tfapply

tfinit:
	@cd terraform && terraform init -input=false

tfapply:
	@cd terraform && terraform apply -auto-approve

down:
	@cd terraform && terraform destroy -auto-approve

.PHONY: up tfinit tfapply down
