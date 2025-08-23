# 📦 Pedido App -- Helm + PostgreSQL + Backend + Frontend + ArgoCD

Este proyecto implementa la aplicación **Pedido App** utilizando
Kubernetes, Helm y ArgoCD.\
Incluye el despliegue de **PostgreSQL** con persistencia, integración
con un **backend** y un **frontend**, manejo de credenciales mediante
**Secrets**, configuración externa con **ConfigMaps**, y separación de
ambientes (`dev` y `prod`).

------------------------------------------------------------------------

## 🚀 Arquitectura de la Aplicación

-   **Frontend**: aplicación web (React/Angular/Vue) servida en `nginx`.
-   **Backend**: API en Spring Boot / Node.js (imagen personalizada).
-   **Base de Datos**: PostgreSQL desplegado con el chart oficial de
    Bitnami.
-   **Helm Charts**:
    -   Subchart `frontend/`: Deployment y Service.
    -   Subchart `backend/`: Deployment, Service y conexión a DB.
    -   Subchart `db/`: StatefulSet, Service, PVC, Secret y ConfigMap.
    -   Ingress para exponer la aplicación.
-   **ArgoCD**:
    -   Gestiona ambientes `dev` y `prod`.
    -   Sincroniza automáticamente el repo con el cluster.

------------------------------------------------------------------------

## ⚙️ Instalación con Helm

Clona el repositorio:

``` bash
git clone <URL-DEL-REPO>
cd pedido-app/charts/pedido-app
```

Instala o actualiza la release:

``` bash
helm dependency update
helm upgrade --install pedido-app . -n pedido-dev --create-namespace --wait
```

Verifica que los pods estén corriendo:

``` bash
kubectl get pods -n pedido-dev
```

Deberías ver algo como:

    pedido-app-dev-frontend-xxxxx    Running
    pedido-app-dev-backend-xxxxx     Running
    pedido-app-dev-postgresql-0      Running

------------------------------------------------------------------------

## 🗄️ Base de Datos -- PostgreSQL

La base de datos se despliega con el chart oficial de Bitnami.

### Recursos creados

-   **StatefulSet**: `pedido-app-dev-postgresql`
-   **PVC**: `data-pedido-app-dev-postgresql-0` (persistencia)
-   **Service**: `pedido-app-dev-postgresql` (5432/TCP)
-   **Secret**: `pedido-db-secret` (credenciales)
-   **ConfigMap**: `pedido-db-config` (configuración)

### Secret `pedido-db-secret`

``` yaml
username: pedido_user
password: pedido_pass123
database: pedidos_db
postgres-password: admin_pass_123
```

### ConfigMap `pedido-db-config`

``` yaml
DATABASE_HOST: pedido-app-dev-postgresql
DATABASE_PORT: "5432"
DATABASE_NAME: pedidos_db
```

### Validación de persistencia

1.  Conectarse con cliente temporal:

``` bash
kubectl run psql-client -n pedido-dev --image=bitnami/postgresql:16 -it --rm -- bash
```

2.  Dentro del pod cliente:

``` bash
export PGPASSWORD='pedido_pass123'
psql -h pedido-app-dev-postgresql -U pedido_user -d pedidos_db
```

3.  En el prompt de PostgreSQL:

``` sql
CREATE TABLE IF NOT EXISTS pedidos(
  id serial PRIMARY KEY,
  descripcion text,
  creado_en timestamptz DEFAULT now()
);

INSERT INTO pedidos(descripcion) VALUES ('prueba-persistencia-dev');
SELECT * FROM pedidos;
```

4.  Reiniciar pod y verificar:

``` bash
kubectl delete pod pedido-app-dev-postgresql-0 -n pedido-dev
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=postgresql -n pedido-dev --timeout=120s
psql -h pedido-app-dev-postgresql -U pedido_user -d pedidos_db -c "SELECT * FROM pedidos;"
```

✅ Los registros persisten tras el reinicio, confirmando la
persistencia.

------------------------------------------------------------------------

## ⚙️ Backend

-   **Imagen**: `juanda1809/pedido-backend:latest`\
-   **Service**: `pedido-app-dev-backend` (puerto 3000)\
-   **Configuración**: recibe variables de entorno desde
    `pedido-backend-db-secret` y `pedido-backend-db-config`.

Ejemplo de variables dentro del pod backend:

    DATABASE_HOST=pedido-app-dev-postgresql
    DATABASE_PORT=5432
    DATABASE_NAME=pedidos_db
    username=pedido_user
    password=pedido_pass123

Esto garantiza la conexión a la DB mediante Secrets y ConfigMaps.

------------------------------------------------------------------------

## 🌐 Frontend

-   Desplegado como un Deployment basado en `nginx`.\
-   **Service**: `pedido-app-dev-frontend` (puerto 80).\
-   Sirve la interfaz que consume la API expuesta por el backend.

------------------------------------------------------------------------

## 🌍 Separación de Ambientes (Dev/Prod)

Se definieron dos archivos de valores para diferenciar ambientes:

**values-dev.yaml**

``` yaml
postgresql:
  primary:
    persistence:
      size: 1Gi
  replicaCount: 1
```

**values-prod.yaml**

``` yaml
postgresql:
  primary:
    persistence:
      size: 8Gi
  replicaCount: 2
```

👉 Dev es más liviano, Prod más robusto.

------------------------------------------------------------------------

## 🤖 ArgoCD

La integración con ArgoCD permite gestionar la app en `dev` y `prod`:

    environments/
      dev/application.yaml
      prod/application.yaml

Ejemplo `application.yaml`:

``` yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pedido-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <URL-DEL-REPO>
    targetRevision: main
    path: charts/pedido-app
    helm:
      valueFiles:
        - values-dev.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: pedido-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Con esto, ArgoCD sincroniza automáticamente el estado del clúster con
Git (GitOps).

------------------------------------------------------------------------

## 📊 Validaciones realizadas

-   ✅ PostgreSQL instalado con Helm (Bitnami).
-   ✅ PVC configurado y funcionando (persistencia validada).
-   ✅ Secrets y ConfigMaps creados y usados por backend.
-   ✅ Backend desplegado y conectado a DB.
-   ✅ Frontend desplegado y expuesto.
-   ✅ Ingress configurado para `/` (frontend) y `/api/*` (backend).
-   ✅ Separación de ambientes con `values-dev.yaml` y
    `values-prod.yaml`.
-   ✅ Integración con ArgoCD para Dev y Prod.

------------------------------------------------------------------------

## 🏆 Conclusión

Este proyecto demuestra:

-   Uso de **Helm** para empaquetar aplicaciones.\
-   Gestión de credenciales con **Secrets** y configuración con
    **ConfigMaps**.\
-   Persistencia de datos con **PVC**.\
-   Integración de **frontend, backend y base de datos** en Kubernetes.\
-   Separación clara de ambientes (`dev` y `prod`).\
-   Despliegue y sincronización continua con **ArgoCD (GitOps)**.

------------------------------------------------------------------------

## 📐 Arquitectura (Mermaid)

``` mermaid
graph TD

  subgraph ArgoCD["🤖 ArgoCD GitOps"]
    A1[Repo GitHub pedido-app-helm]
    A2[Application.yaml dev-prod]
    A1 --> A2
  end

  subgraph K8s["☸️ Cluster Kubernetes"]
    subgraph Frontend["🌐 Frontend"]
      F1[Deployment React/Angular]
      F2[Service ClusterIP]
    end

    subgraph Backend["⚙️ Backend"]
      B1[Deployment Spring/Node.js]
      B2[Service ClusterIP]
    end

    subgraph DB["🗄️ PostgreSQL Bitnami Helm"]
      D1[StatefulSet]
      D2[Service ClusterIP:5432]
      D3[(PVC Persistencia)]
      D4[Secret Credenciales]
      D5[ConfigMap DB Config]
    end

    F1 --> F2 -->|"HTTP /"| B1
    B1 --> B2 -->|"SQL / 5432"| D2
    D1 --> D2
    D1 --> D3
    D1 --> D4
    D1 --> D5
  end

  A2 -->|Sincroniza| K8s

```
