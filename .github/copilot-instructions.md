# Copilot Instructions for Helm Charts Repository

## Repository Overview
This repository contains organization-wide Helm charts for deploying applications to Kubernetes clusters. All charts should follow industry-standard best practices for both Helm and Kubernetes deployments, with a strong emphasis on readability, maintainability, and security.

## Development Workflow and Tool Usage

### Required Tools and Setup
- **Helm 3.x**: Use `helm version` to verify installation
- **kubectl**: For Kubernetes cluster interaction
- **yq**: For YAML processing in CI/CD workflows
- **chart-testing (ct)**: For automated chart testing
- **helm-unittest**: For unit testing chart templates

### Preferred Development Commands
When working with charts, always use these commands:
```bash
# Install dependencies before testing
helm dependency update charts/[chart-name]/

# Lint YAML files for formatting issues (REQUIRED before committing)
yamllint charts/[chart-name]/

# Lint charts before committing
helm lint charts/[chart-name]/

# Test template rendering
helm template [release-name] charts/[chart-name]/ --debug

# Validate with dry-run
helm install [release-name] charts/[chart-name]/ --dry-run --debug

# Run unit tests (if helm-unittest is available)
helm unittest charts/[chart-name]/
```

### YAML Formatting Requirements
**CRITICAL:** All YAML files must pass yamllint validation before committing:
- **No trailing spaces**: Remove all trailing whitespace from lines
- **Consistent indentation**: Use 2 spaces for indentation
- **No tabs**: Only use spaces, never tabs
- **Line length**: Keep lines under 160 characters where possible

Always run `yamllint charts/[chart-name]/` to check for formatting issues before committing changes.

## Chart Development Guidelines

### Chart Structure Standards

#### Chart.yaml Requirements
- **API Version**: Always use `apiVersion: v2` for Helm 3 compatibility
- **Semantic Versioning**: Follow SemVer for both `version` (chart version) and `appVersion` (application version)
- **Descriptive Metadata**: Include meaningful `description`, `home`, `sources`, and `maintainers`
- **Keywords**: Add relevant keywords for discoverability
- **Dependencies**: Declare all chart dependencies with version constraints

Example:
```yaml
apiVersion: v2
name: my-application
description: A comprehensive Helm chart for My Application on Kubernetes
type: application
version: 1.0.0
appVersion: "2.1.0"
home: https://github.com/fmidev/my-application
sources:
  - https://github.com/fmidev/my-application
maintainers:
  - name: Team Name
    email: team@fmi.fi
keywords:
  - application
  - microservice
  - api
```

#### values.yaml Best Practices
- **Clear Documentation**: Comment all configuration options with examples
- **Sensible Defaults**: Provide production-ready defaults that work out-of-the-box
- **Hierarchical Structure**: Group related configurations logically
- **Security First**: Default to secure configurations (non-root users, read-only filesystems)
- **Resource Limits**: Always include default resource requests and limits

### Template Standards

#### Naming Conventions
- **Resource Names**: Use `{{ include "chart.fullname" . }}` for consistent naming
- **Labels**: Apply standard labels using `{{ include "chart.labels" . }}`
- **Selectors**: Use `{{ include "chart.selectorLabels" . }}` for consistency

#### Required Templates
Every chart should include:
- `_helpers.tpl` with standard helper functions
- `NOTES.txt` with post-installation instructions
- Proper resource templates (Deployment, Service, etc.)

#### Security Best Practices
- **Pod Security Standards**: Implement restrictive security contexts
- **Service Accounts**: Create dedicated service accounts with minimal permissions
- **Secrets Management**: Use proper secret handling with external secret operators when possible
- **Network Policies**: Include network policy templates when applicable

Example Security Context:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

### Resource Management

#### Deployment Standards
- **Rolling Updates**: Configure appropriate rolling update strategies
- **Health Checks**: Implement readiness and liveness probes
- **Resource Limits**: Always set CPU and memory limits/requests
- **Pod Disruption Budgets**: Include PDB templates for high-availability services

#### Configuration Management
- **ConfigMaps**: Use for non-sensitive configuration
- **Secrets**: Proper secret handling with rotation capabilities
- **Environment Variables**: Minimize direct env vars, prefer ConfigMap/Secret references

### Monitoring and Observability

#### Required Monitoring Elements
- **Service Monitors**: Include Prometheus ServiceMonitor templates
- **Dashboards**: Provide Grafana dashboard configurations
- **Alerts**: Define essential alerting rules
- **Logging**: Configure structured logging with proper log levels

#### Labels and Annotations
Apply comprehensive labeling:
```yaml
labels:
  app.kubernetes.io/name: {{ include "chart.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  app.kubernetes.io/component: backend
  app.kubernetes.io/part-of: {{ include "chart.name" . }}
```

### Development Workflow

#### Chart Testing
- **Template Validation**: Use `helm template` to validate rendered templates
- **Lint Checks**: Run `helm lint` for all charts
- **Unit Tests**: Implement helm-unittest for template logic
- **Integration Tests**: Test installations in development clusters

#### Documentation Requirements
- **README.md**: Comprehensive documentation with installation instructions
- **CHANGELOG.md**: Track version changes and breaking changes
- **values.yaml Comments**: Document every configuration option

#### Version Management
- **Chart Versioning**: Increment chart version for any template changes
- **App Versioning**: Update appVersion when deploying new application versions
- **Breaking Changes**: Follow semantic versioning for breaking changes

### Code Quality Standards

#### Template Quality
- **DRY Principle**: Use helpers and named templates to avoid repetition
- **Conditional Logic**: Keep template logic readable with proper indentation
- **Error Handling**: Include validation for required values
- **Comments**: Document complex template logic

#### File Organization
```
chart-name/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml        # Environment-specific values
├── README.md
├── CHANGELOG.md
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── servicemonitor.yaml
│   ├── networkpolicy.yaml
│   ├── poddisruptionbudget.yaml
│   ├── hpa.yaml
│   └── NOTES.txt
└── tests/
    └── unit/
```

### OpenShift Compatibility

#### OpenShift-Specific Considerations
- **Security Context Constraints**: Support restricted SCCs
- **Routes vs Ingress**: Provide Route templates for OpenShift
- **ImageStreams**: Include ImageStream templates when using OpenShift builds
- **BuildConfigs**: Proper BuildConfig templates for S2I builds

### Environment-Specific Configurations

#### Multi-Environment Support
- **Environment Values**: Separate values files for dev/staging/prod
- **Cluster-Specific**: Support different cluster configurations
- **Feature Flags**: Use boolean flags for optional features

### Common Patterns

#### Helper Functions (_helpers.tpl)
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

**Note**: Many existing charts in this repository may not have `_helpers.tpl` files yet. When updating charts, gradually migrate to use these standard helper functions for consistency.

### Validation and Testing

#### Pre-commit Requirements
1. Run `helm lint` on all charts
2. Validate YAML syntax
3. Check for security best practices
4. Verify documentation is up-to-date
5. Run unit tests

#### Chart Testing Commands
```bash
# Lint all charts
helm lint charts/*/

# Test template rendering
helm template my-release charts/my-chart/

# Dry run installation
helm install my-release charts/my-chart/ --dry-run --debug

# Run unit tests
helm unittest charts/my-chart/
```

## Implementation Guidelines

When creating or modifying charts:

1. **Start with Security**: Design with security-first principles
2. **Follow Conventions**: Use established naming and labeling conventions
3. **Document Everything**: Ensure all options are documented
4. **Test Thoroughly**: Validate in multiple environments
5. **Monitor Impact**: Include observability from day one
6. **Plan for Scale**: Design for horizontal scaling and high availability
7. **Maintain Compatibility**: Ensure backward compatibility when possible

### Automation and Tool Integration

#### Scaffolding New Charts
When creating new charts, use Helm's scaffolding:
```bash
# Create new chart with standard structure
helm create charts/[chart-name]

# Remove example files and customize for FMI standards
rm charts/[chart-name]/templates/tests/test-connection.yaml
```

#### Dependency Management
Always use Helm's dependency management:
```bash
# Add dependencies to Chart.yaml, then run:
helm dependency update charts/[chart-name]/

# Lock specific versions in Chart.lock for reproducible builds
```

#### Validation Workflow
Before committing changes:
```bash
# 1. Lint the chart
helm lint charts/[chart-name]/

# 2. Test template rendering
helm template test-release charts/[chart-name]/ --debug

# 3. Validate with multiple value sets
helm template test-release charts/[chart-name]/ -f charts/[chart-name]/values.yaml
helm template test-release charts/[chart-name]/ -f charts/[chart-name]/values-prod.yaml

# 4. Check for security issues (if tools available)
# Use tools like kubesec, kube-score, or polaris for additional validation
```

## Common Anti-Patterns to Avoid

- Hard-coded values in templates
- Missing resource limits
- Overly permissive security contexts
- Inadequate health checks
- Missing documentation
- Inconsistent labeling
- Complex template logic without comments
- Missing validation for required values

## Review Checklist

Before submitting charts for review:

- [ ] Chart follows semantic versioning
- [ ] All templates are properly documented
- [ ] Security contexts are restrictive
- [ ] Resource limits are defined
- [ ] Health checks are implemented
- [ ] Standard labels are applied
- [ ] README.md is comprehensive
- [ ] values.yaml has sensible defaults
- [ ] Chart passes helm lint
- [ ] Templates render correctly
- [ ] NOTES.txt provides useful information

This repository aims to provide reliable, secure, and maintainable Helm charts that follow industry best practices and enable efficient application deployment across our Kubernetes infrastructure.

## Troubleshooting and Debugging

### Common Issues and Solutions

#### Template Rendering Problems
```bash
# Debug template issues with verbose output
helm template [release-name] charts/[chart-name]/ --debug --dry-run

# Check specific template files
helm template [release-name] charts/[chart-name]/ -s templates/deployment.yaml
```

#### Dependency Issues
```bash
# Clean and rebuild dependencies
rm charts/[chart-name]/Chart.lock
rm -rf charts/[chart-name]/charts/
helm dependency update charts/[chart-name]/
```

#### Value Validation
```bash
# Test with specific values
helm template [release-name] charts/[chart-name]/ --set key=value

# Validate values file syntax
yq eval '.' charts/[chart-name]/values.yaml
```

### Development Best Practices for Copilot

- **Always test changes incrementally**: Run `helm template` after each template modification
- **Use descriptive variable names**: Make template logic self-documenting
- **Validate YAML syntax**: Use `yq` or `yamllint` to catch syntax errors early
- **Check resource limits**: Ensure all containers have proper resource constraints
- **Test edge cases**: Validate behavior with minimal and maximal configurations
- **Document assumptions**: Add comments explaining complex template logic

### Repository-Specific Patterns

- **OpenShift Compatibility**: Many charts support both Kubernetes and OpenShift
- **FMI Standards**: Follow organization naming conventions and security policies
- **Environment Flexibility**: Support multiple deployment environments (dev/staging/prod)
- **Monitoring Integration**: Include ServiceMonitor templates for Prometheus
- **Security Context**: Always use restrictive security contexts with non-root users