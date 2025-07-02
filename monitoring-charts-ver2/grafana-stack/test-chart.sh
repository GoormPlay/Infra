#!/bin/bash

# Grafana Stack Helm Chart Test Script

echo "=== Grafana Stack Helm Chart Validation ==="

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed"
    exit 1
fi

echo "✅ Helm is installed"

# Validate chart syntax
echo "🔍 Validating chart syntax..."
if helm lint .; then
    echo "✅ Chart syntax is valid"
else
    echo "❌ Chart syntax validation failed"
    exit 1
fi

# Test template rendering
echo "🔍 Testing template rendering..."
if helm template test-release . --namespace observability > /dev/null; then
    echo "✅ Template rendering successful"
else
    echo "❌ Template rendering failed"
    exit 1
fi

# Test with different configurations
echo "🔍 Testing with Ingress enabled..."
if helm template test-release . --namespace observability --set grafana.ingress.enabled=true > /dev/null; then
    echo "✅ Ingress configuration test passed"
else
    echo "❌ Ingress configuration test failed"
    exit 1
fi

echo "🔍 Testing with LoadBalancer enabled..."
if helm template test-release . --namespace observability --set grafana.loadBalancer.enabled=true > /dev/null; then
    echo "✅ LoadBalancer configuration test passed"
else
    echo "❌ LoadBalancer configuration test failed"
    exit 1
fi

echo "🔍 Testing with persistence disabled..."
if helm template test-release . --namespace observability --set grafana.persistence.enabled=false --set alertmanager.persistence.enabled=false > /dev/null; then
    echo "✅ Persistence disabled test passed"
else
    echo "❌ Persistence disabled test failed"
    exit 1
fi

echo "🔍 Testing with Alertmanager disabled..."
if helm template test-release . --namespace observability --set alertmanager.enabled=false > /dev/null; then
    echo "✅ Alertmanager disabled test passed"
else
    echo "❌ Alertmanager disabled test failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! The Grafana Stack Helm chart is ready for deployment."
echo ""
echo "To deploy the chart:"
echo "  helm install grafana-stack . -n observability --create-namespace"
echo ""
echo "To test deployment with dry-run:"
echo "  helm install grafana-stack . -n observability --create-namespace --dry-run"
