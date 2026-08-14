# helm-invidious

[![release][badge-gh-actions-release]][link-gh-actions-release]

Deploy [Invidious] to Kubernetes with PostgreSQL and Invidious companion.

## Quick Start

Create a local file containing the required Secret values:

```sh
install -m 600 /dev/null invidious-secret.env
${EDITOR:-vi} invidious-secret.env
```

Add the following keys:

```dotenv
db_user=invidious
db_password=REPLACE_WITH_A_RANDOM_DATABASE_PASSWORD
hmac_key=REPLACE_WITH_A_RANDOM_HMAC_KEY
po_token=REPLACE_WITH_YOUR_PO_TOKEN
visitor_data=REPLACE_WITH_YOUR_VISITOR_DATA
invidious_companion_key=REPLACE_WITH_EXACTLY_16_RANDOM_CHARACTERS
```

Install the chart:

```sh
kubectl create namespace invidious
kubectl create secret generic invidious-secrets \
  --namespace invidious \
  --from-env-file=invidious-secret.env

helm upgrade --install invidious \
  oci://ghcr.io/g3rhard/charts/invidious \
  --namespace invidious
```

Open the local instance:

```sh
kubectl port-forward \
  --namespace invidious \
  service/invidious-invidious-invidious 3000:3000
```

Visit <http://localhost:3000>, then remove the plaintext Secret file:

```sh
rm invidious-secret.env
```

## Configuration

Copy [values-example.yaml](values-example.yaml), adjust it for your cluster, and
pass it during installation:

```sh
helm upgrade --install invidious \
  oci://ghcr.io/g3rhard/charts/invidious \
  --namespace invidious \
  --values values.yaml
```

The chart can deploy:

- Invidious companion;
- an internal PostgreSQL database with persistent storage;
- the optional Materialious frontend;
- Ingress resources and a HorizontalPodAutoscaler.

The chart runs the upstream `invidious --migrate` command before starting the
application. PostgreSQL schema files remain available for bootstrapping a new
internal database.

## Secret Management

The chart does not create or encrypt secrets. The workloads consume an existing
Kubernetes Secret directly through `secretKeyRef`. Its name and key mappings are
configured under `secret.name` and `secret.keys`.

Generate independent random values:

```sh
# Database password; hexadecimal avoids YAML quoting problems
openssl rand -hex 32

# Invidious HMAC key
pwgen 16 1

# Companion key; exactly 16 characters and different from the HMAC key
pwgen 16 1
```

`po_token` and `visitor_data` form a related pair and must not be generated as
independent random strings. Obtain them together using the current
[Invidious installation instructions][invidious-installation] or your companion
setup workflow.

For GitOps installations, create the same Kubernetes Secret through your
preferred secret-management workflow. SOPS, Sealed Secrets, and external secret
operators are intentionally outside the scope of this chart.

## Upgrade

```sh
helm upgrade invidious \
  oci://ghcr.io/g3rhard/charts/invidious \
  --namespace invidious \
  --values values.yaml
```

## Uninstall

```sh
helm uninstall invidious --namespace invidious
```

The PostgreSQL PVC is retained. Delete it explicitly only when the stored data
is no longer needed.

## Development

```sh
helm lint charts/invidious
helm template invidious charts/invidious \
  --namespace invidious \
  --values values-example.yaml
```

[badge-gh-actions-release]: https://github.com/g3rhard/helm-invidious/actions/workflows/release.yml/badge.svg?branch=production
[invidious]: https://github.com/iv-org/invidious
[invidious-installation]: https://docs.invidious.io/installation/
[link-gh-actions-release]: https://github.com/g3rhard/helm-invidious/actions?query=workflow%3Arelease
