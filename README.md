## Contexte

Dans une équipe cloud, chaque `terraform apply` peut créer des ressources non conformes :
labels manquants (impossible d'attribuer les coûts ou d'identifier un propriétaire),
VPC Flow Logs désactivés (aucune visibilité réseau en cas d'incident de sécurité).
Ces écarts sont souvent découverts après le déploiement.

## Solution

Un script Python (`scripts/my-checker.py`, bibliothèque standard uniquement) lit le plan
Terraform au format JSON **avant l'apply** et vérifie :

| Règle | Ressources | Bloque si |
|---|---|---|
| Labels obligatoires | ressources qui supportent les labels (VM, buckets…) | `owner`, `env` ou `managed_by` absent |
| VPC Flow Logs | `google_compute_subnetwork` | pas de bloc `log_config` |

Sur GCP, les Flow Logs se configurent par sous-réseau : le script contrôle donc chaque
sous-réseau pour garantir que tout le VPC est couvert.

Le script renvoie le code `1` en cas de violation, ce qui arrête le pipeline avant l'apply.

## Utilisation

```bash
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform show -json tfplan > terraform/plan.json
python3 scripts/my-checker.py; echo "code = $?"
```

## Résultat

Lancé sur ma propre infrastructure, le script a détecté 3 écarts réels :
- une convention de nommage incohérente (`managed-by` / `managed_by`) sur la VM et un bucket ;
- un sous-réseau sans VPC Flow Logs.

| Avant correction | Après correction |
|---|---|
| ![échec](docs/check-echec.png) | ![ok](docs/check-ok.png) |