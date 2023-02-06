% ./install-wordpress.sh 
namespace/corp-blog created
NAME: corp-blog
LAST DEPLOYED: Thu Jun 30 08:03:26 2022
NAMESPACE: corp-blog
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: wordpress
CHART VERSION: 14.0.6
APP VERSION: 5.9.3

** Please be patient while the chart is being deployed **

Your WordPress site can be accessed through the following DNS name from within your cluster:

    corp-blog-wordpress.corp-blog.svc.cluster.local (port 80)

To access your WordPress site from outside the cluster follow the steps below:

1. Get the WordPress URL by running these commands:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace corp-blog -w corp-blog-wordpress'

   export SERVICE_IP=$(kubectl get svc --namespace corp-blog corp-blog-wordpress --include "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
   echo "WordPress URL: http://$SERVICE_IP/"
   echo "WordPress Admin URL: http://$SERVICE_IP/admin"

2. Open a browser and access WordPress using the obtained URL.

3. Login with the following credentials below to see your blog:

  echo Username: user
  echo Password: $(kubectl get secret --namespace corp-blog corp-blog-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
To re-display this info: $ helm status corp-blog -n corp-blog



Wordpress: http://10.220.41.72/
Username: user
Password: klH4M04GQz
