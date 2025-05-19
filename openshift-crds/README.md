# OpenShift CRD stubs

These stub CustomResourceDefinitions exist **only** to make Helm-chart linting pass in CI.

They are applied to the Kind test cluster by the GitHub Actions workflow
[`lint-test.yml`](../.github/workflows/lint-test.yml).

Authoritative (and more complete) CRDs for some resources are available in the
OpenShift API repository: <https://github.com/openshift/api/>.

Add CRD stubs as needed.
