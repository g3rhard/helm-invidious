# helm-invidious

[![Helm](https://img.shields.io/badge/Helm-Chart-0F1689?style=for-the-badge&logo=helm&color=333333)](https://helm.sh/)
[![Release](https://img.shields.io/github/actions/workflow/status/g3rhard/helm-invidious/release.yml?style=for-the-badge&logo=githubactions&label=Release)](https://github.com/g3rhard/helm-invidious/actions/workflows/release.yml)
[![GitHub Pages](https://img.shields.io/badge/GitHub_Pages-Helm_Repository-222222?style=for-the-badge&logo=githubpages)](https://g3rhard.cc/helm-invidious/index.yaml)
[![Version](https://img.shields.io/github/v/release/g3rhard/helm-invidious?style=for-the-badge&logo=github&color=333333)](https://github.com/g3rhard/helm-invidious/releases/latest)

Deploy [Invidious] to Kubernetes with PostgreSQL and Invidious companion.

## Quick Start

Generate a local env file containing the random Secret values:

```sh
umask 077
cat >invidious-secret.env <<EOF
db_user=invidious
db_password=$(openssl rand -hex 32)
hmac_key=$(pwgen 20 1)
po_token=REPLACE_WITH_YOUR_PO_TOKEN
visitor_data=REPLACE_WITH_YOUR_VISITOR_DATA
invidious_companion_key=$(pwgen 16 1)
EOF

${EDITOR:-vi} invidious-secret.env
```

Replace the `po_token` and `visitor_data` placeholders with a matching pair
before creating the Secret.

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

Container images use separate `registry`, `repository`, `tag`, and optional
`digest` values, as shown in the chart's `values.yaml`. Leave `digest` empty to
render `registry/repository:tag`, or set it to `sha256:...` to render the
immutable `registry/repository:tag@sha256:...` form. Chart 3.0.0 no longer
accepts the former combined `image: repository:tag` value.

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

The Quick Start heredoc generates independent random values for the database
password, the exactly 20-character HMAC key, and the exactly 16-character
companion key. To regenerate them individually:

```sh
# Database password; hexadecimal avoids YAML quoting problems
openssl rand -hex 32

# Invidious HMAC key; exactly 20 characters
pwgen 20 1

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

[invidious]: https://github.com/iv-org/invidious
[invidious-installation]: https://docs.invidious.io/installation/
