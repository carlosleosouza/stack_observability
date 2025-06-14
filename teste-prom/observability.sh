#!/usr/bin/env bash
set -e

#source $SNAP/actions/common/utils.sh
CURRENT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

"$SNAP/microk8s-enable.wrapper" core/dns
"$SNAP/microk8s-enable.wrapper" core/helm3
"$SNAP/microk8s-enable.wrapper" core/hostpath-storage

NAMESPACE="observability"
KUBECTL="$SNAP/microk8s-kubectl.wrapper"

echo "Enabling observability"

KUBE_PROM_STACK_VALUES=./stack-values.yaml
KUBE_PROM_STACK_VERSION=70.4.1
LOKI_STACK_VALUES=
LOKI_STACK_VERSION=2.10.2
TEMPO_VALUES=
TEMPO_VERSION=1.20.0
WITHOUT_TEMPO=
while [ $# -ge 1 ]; do
  case $1 in
    --kube-prometheus-stack-values=*)
      KUBE_PROM_STACK_VALUES="${1#*=}"
      shift
      ;;
    --kube-prometheus-stack-version=*)
      KUBE_PROM_STACK_VERSION="${1#*=}"
      shift
      ;;
    --loki-stack-values=*)
      LOKI_STACK_VALUES="${1#*=}"
      shift
      ;;
    --loki-stack-version=*)
      LOKI_STACK_VERSION="${1#*=}"
      shift
      ;;
    --tempo-values=*)
      TEMPO_VALUES="${1#*=}"
      shift
      ;;
    --tempo-version=*)
      TEMPO_VERSION="${1#*=}"
      shift
      ;;
    --without-tempo)
      WITHOUT_TEMPO=1
      shift
      ;;
    *)
      echo "Unknown option ${1}" >&2
      exit 1
      ;;
  esac
done

# get addresses of all nodes to configure kubeControllerManager and kubeScheduler endpoints
NODE_ENDPOINTS=$($KUBECTL get nodes -o jsonpath={.items[*].status.addresses[?\(@.type==\"InternalIP\"\)].address} | sed 's/\s\+/,/g')
HELM="${SNAP}/microk8s-helm3.wrapper"

HELM_OPTS=
if [ -n "${KUBE_PROM_STACK_VALUES}" ]; then
  HELM_OPTS+="--values ${KUBE_PROM_STACK_VALUES} "
fi
if [ -n "${KUBE_PROM_STACK_VERSION}" ]; then
  HELM_OPTS+="--version ${KUBE_PROM_STACK_VERSION} "
fi
HELM_OPTS+="--set grafana.additionalDataSources[0].name=loki,grafana.additionalDataSources[0].type=loki,grafana.additionalDataSources[0].url=http://loki.observability.svc.cluster.local:3100 "
if [ -z "${WITHOUT_TEMPO}" ]; then
  HELM_OPTS+="--set grafana.additionalDataSources[1].name=tempo,grafana.additionalDataSources[1].type=tempo,grafana.additionalDataSources[1].url=http://tempo.observability.svc.cluster.local:3100 "
fi

$HELM upgrade --install kube-prom-stack kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --create-namespace --namespace $NAMESPACE \
  --set kubeControllerManager.endpoints={$NODE_ENDPOINTS} \
  --set kubeScheduler.endpoints={$NODE_ENDPOINTS} \
  ${HELM_OPTS}

HELM_OPTS=
if [ -n "${LOKI_STACK_VALUES}" ]; then
  HELM_OPTS+="--values ${LOKI_STACK_VALUES} "
fi
if [ -n "${LOKI_STACK_VERSION}" ]; then
  HELM_OPTS+="--version ${LOKI_STACK_VERSION} "
fi
$HELM upgrade --install loki loki-stack \
  --repo https://grafana.github.io/helm-charts \
  --create-namespace --namespace $NAMESPACE \
  --set="grafana.sidecar.datasources.enabled=false" \
  ${HELM_OPTS}

if [ -z "${WITHOUT_TEMPO}" ]; then
  HELM_OPTS=
  if [ -n "${TEMPO_VALUES}" ]; then
    HELM_OPTS+="--values ${TEMPO_VALUES} "
  fi
  if [ -n "${TEMPO_VERSION}" ]; then
    HELM_OPTS+="--version ${TEMPO_VERSION} "
  fi
  $HELM upgrade --install tempo tempo --repo https://grafana.github.io/helm-charts --create-namespace --namespace $NAMESPACE ${HELM_OPTS}
fi

refresh_opt_in_config "authentication-kubeconfig" "\${SNAP_DATA}/credentials/scheduler.config" kube-scheduler
refresh_opt_in_config "authorization-kubeconfig" "\${SNAP_DATA}/credentials/scheduler.config" kube-scheduler
restart_service scheduler
refresh_opt_in_config "authentication-kubeconfig" "\${SNAP_DATA}/credentials/controller.config" kube-controller-manager
refresh_opt_in_config "authorization-kubeconfig" "\${SNAP_DATA}/credentials/controller.config" kube-controller-manager
restart_service controller-manager
refresh_opt_in_config "metrics-bind-address" "0.0.0.0:10249" kube-proxy
restart_service proxy

echo ""
echo "Note: the observability stack is setup to monitor only the current nodes of the MicroK8s cluster."
echo "For any nodes joining the cluster at a later stage this addon will need to be set up again."
echo ""
echo "Observability has been enabled (user/pass: admin/prom-operator)"
