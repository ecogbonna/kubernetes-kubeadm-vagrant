### CREATING A LOADBALANCER SERVICE
- Adding support for LoadBalancer services with MetalLB
	- Layer2 and BGP configurations. 


#### Step 1: Installation With Helm: Install MetalLB with Configured Values

```shell 
helm repo add metallb https://metallb.github.io/metallb
helm repo update

helm install metallb metallb/metallb --namespace metallb-system --create-namespace
```

#### Step 2: Layer 2 Configuration
- In order to assign an IP to the services, MetalLB must be instructed to do so via the IPAddressPool CR.
- In order to advertise the IP coming from an IPAddressPool, an L2Advertisement instance must be associated to the IPAddressPool.

```shell
cat <<EOF | sudo tee configuration.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.50.240-192.168.50.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF 


kubectl apply -f configuration.yaml

kubectl get ipaddresspool,l2advertisement -A
NAMESPACE        NAME                                  AGE
metallb-system   ipaddresspool.metallb.io/first-pool   66s

NAMESPACE        NAME                                 AGE
metallb-system   l2advertisement.metallb.io/example   66s
```


#### Step 3: Testing
```shell
cat <<EOF | kubectl apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lb-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80 
---
apiVersion: v1
kind: Service
metadata:
  name: lb-service
  annotations:
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer		
EOF

curl -s http://192.168.50.240

```

Links: 
* <https://metallb.universe.tf/>
* <https://metallb.universe.tf/configuration/>
* <https://platform9.com/blog/using-metallb-to-add-the-loadbalancer-service-to-kubernetes-environments/>



#### CONNECTING TO THE SERVICE THROUGH THE LOAD BALANCER
you don’t need to mess with firewalls the way you had to before with the NodePort service.

```shell 
k create -f ../04_replication_n_controllers/kubia-rc.yaml
k create -f kubia-svc-loadbalancer.yaml
```

##### Check loadbalancing:

```shell
for value in {1..20}; do curl http://192.168.50.241; done
```



#### INSTALLING THE NGINX INGRESS CONTROLLER
- Regardless of how you run your Kubernetes cluster, you should be able to install the Nginx ingress controller by following the instructions at https://kubernetes.github.io/ingress-nginx/deploy/.

```sh
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
 
Output:
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

