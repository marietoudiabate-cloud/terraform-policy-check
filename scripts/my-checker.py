import json
import sys

LABELS_OBLIGATOIRES = ["owner", "env", "managed_by"]

with open('terraform/plan.json', 'r', encoding='utf-8') as fichier:
    donnees = json.load(fichier)

erreurs = []

for element in donnees["resource_changes"]:
    # On ignore les data sources et les ressources qui vont être supprimées
    if element["mode"] != "managed" or element["change"]["actions"] == ["delete"]:
        continue

    adresse = element["address"]
    apres = element["change"]["after"]

    # Règle 1 : Flow Logs activés sur les sous-réseaux
    if element["type"] == "google_compute_subnetwork":
        if not apres.get("log_config"):
            erreurs.append(f"{adresse} : Flow Logs désactivés")

    # Règle 2 : labels obligatoires (seulement si la ressource supporte les labels)
    if "labels" in apres:
        labels = {}
        labels.update(apres.get("labels") or {})
        labels.update(apres.get("terraform_labels") or {})
        for cle in LABELS_OBLIGATOIRES:
            if cle not in labels:
                erreurs.append(f"{adresse} : label '{cle}' manquant")

if erreurs:
    print(f"ÉCHEC : {len(erreurs)} problème(s)")
    for erreur in erreurs:
        print("  -", erreur)
    sys.exit(1)

print("OK : plan conforme")
sys.exit(0)