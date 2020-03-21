# Continuously Integrating and Continuously Delivering ML Model and Deploy it in a Kubernetes Cluster in AWS
In this project, we build a **continous integration and continous delivery (CI/CD)** pipeline for ML model, and then delpoy this ML model into a **Kubernetes cluster**. We leverage the CircleCI to continuously test and build the ML model application and deliver the successful application into **Docker Hub registry**. Then we will deploy the ML model image/container from Docker Hub into the Kubernetes cluster in AWS. Another version of building a CI/CD pipeline in AWS Virtual Private Cloud (VPC) for Machine Learning models can be referred to my repo [CICD_ML_AWS](https://github.com/cy235/CICD_ML_AWS)


## Continuously Integrating and Continuously Delivering ML Model into Docker Hub
In this part, we employ the CircleCI for continuously building/testing and continuously delivering the ML model application into Docker Hub registry because CircleCI is free and it runs fast due to its intrinsic caching mechanism. 

First, sign up your CircleCI with github account, then add your project in github to CircleCI, and enter your AWS access ID and secret access ID in `AWS permission`. In the root path of your github project, there should be a file named `config.yml` in a hidden folder named `.circleci`. whenever there is a commit in your project in github, `config.yml` is responsible for building, testing and pushing the successful built ML model into the Docker Hub. 

In the continuous integration part, some test modules such as python source code test as well as docker image test are added, you can refer more details in `config.yml`, where all the steps in the continuous integration are executed in terms of work flow. If the build is successful, move to the next stage to deliver the ML model into the Docker Hub, otherwise, a failure notification will be sent to your email box associated with your github account. You can also refer to more details about the continuous integration in the CircleCI dashboard.

## Deploy ML model into Kubernetes in AWS
In this part, we will deploy the ML model from Docker Hub registry into kubernetes in AWS. How to set Up a Kubernetes cluster in AWS with `kops` can be referred to my repo [](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS).

### Set Up a Kubernetes Cluster in AWS
#### Prerequisites
Before setting up the Kubernetes cluster, you’ll need an AWS account and an installation of the AWS Command Line Interface.

Make sure to configure the AWS CLI to use your access key ID and secret access key:
```
$ aws configure
AWS Access Key ID [None]: AWS_key_ID
AWS Secret Access Key [None]: AWS_secret_key
Default region name [None]: us-east-1
Default output format [None]: json
```
#### Install kops + kubectl
On Mac OS X, we’ll use brew to install.
```
$ brew update && brew install kops kubectl
```

#### Set Up the Kubernetes Cluster
The first thing we need to do is create an S3 bucket for kops to use to store the state of the Kubernetes cluster and its configuration. We’ll use the bucket name cy235-kops-state-store
```
$ aws s3api create-bucket --bucket cy235-kops-state-store --region us-east-1
```
Before creating the cluster, let’s set two environment variables: `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE`. For safe keeping you should add the following to your `~/.bash_profile` or `~/.bashrc` configs (or whatever the equivalent is if you don’t use bash).
```
$ export KOPS_CLUSTER_NAME=cy235.k8s.local
$ export KOPS_STATE_STORE=s3://cy235-kops-state-store
```
Now, to generate the cluster configuration:
```
$ kops create cluster --node-count=2 --node-size=t2.medium --zones=us-east-1a
```
you may encounter:
```
$ kops create cluster --node-count=2 --node-size=t2.medium --zones=us-east-1a
I0318 22:59:06.019860   23964 create_cluster.go:562] Inferred --cloud=aws from zone "us-east-1a"
I0318 22:59:06.162553   23964 subnets.go:184] Assigned CIDR 172.20.32.0/19 to subnet us-east-1a
Previewing changes that will be made:


SSH public key must be specified when running with AWS (create with `kops create secret --name cy235.k8s.local sshpublickey admin -i ~/.ssh/id_rsa.pub`)
```
In order solve above problem, I execute the following commands:
```
$ ssh-keygen -t rsa -f ./cluster.fayzlab.com
$ kops create secret sshpublickey admin -i ~/.ssh/cluster.cy235.com.pub  --state s3://cy235-kops-state-store
```
Note: this line doesn’t launch the AWS EC2 instances. It simply creates the configuration and writes to the `s3://cy235-kops-state-store` bucket we created above. In our example, we’re creating 2 t2.medium EC2 work nodes in addition to a c4.large master instance (default).
```
$ kops edit cluster
```
Now that we’ve generated a cluster configuration, we can edit its description before launching the instances. The config is loaded from `s3://cy235-kops-state-store`. You can change the editor used to edit the config by setting `$EDITOR` or `$KUBE_EDITOR`. For instance, in my `~/.bashrc`, I have export `KUBE_EDITOR=cy235`.

Time to build the cluster. This takes a few minutes to boot the EC2 instances and download the Kubernetes components.
```
$ kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
```
After waiting a bit (5~10 minutes), let’s validate the cluster to ensure the master + 2 nodes have launched.
```
$ kops validate cluster
Using cluster from kubectl context: cy235.k8s.local

Validating cluster cy235.k8s.local

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
master-us-east-1a	Master	m3.medium	1	1	us-east-1a
nodes			Node	t2.medium	2	2	us-east-1a

NODE STATUS
NAME				ROLE	READY
ip-172-20-33-220.ec2.internal	master	True
ip-172-20-49-54.ec2.internal	node	True
ip-172-20-56-3.ec2.internal	node	True

Your cluster cy235.k8s.local is ready
```
Note: The Cluster should be ready in a few minutes. If you validate too early, you’ll get an error. 
```
$ kops validate cluster
Validating cluster cy235.k8s.local


unexpected error during validation: error listing nodes: Get https://api-cy235-k8s-local-fl5vth-2032235046.us-east-1.elb.amazonaws.com/api/v1/nodes: EOF
```
Wait a little longer for the nodes to launch, and the validate step will return without error.

Finally, you can see your Kubernetes nodes with kubectl:
```
$ kubectl get nodes
NAME                            STATUS   ROLES    AGE   VERSION
ip-172-20-33-220.ec2.internal   Ready    master   32m   v1.16.7
ip-172-20-49-54.ec2.internal    Ready    node     31m   v1.16.7
ip-172-20-56-3.ec2.internal     Ready    node     31m   v1.16.7
```

When cluster is created, we can login the AWS to EC2s, Auto scaling groups and Load balancers in the following:

EC2s
![image](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS/blob/master/EC2.jpg)

Auto scaling groups
![image](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS/blob/master/auto_scaling_group.jpg)

Load balancers
![image](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS/blob/master/load_balancer.jpg)

#### Kubernetes Dashboard
Now, we have a working Kubernetes cluster deployed on AWS. At this point, we can deploy lots of applications, such as Dask and Jupyter. For demonstration, I will launch the [Kubernetes Dashboard](https://github.com/kubernetes/dashboard). Think UI instead of command line for managing Kubernetes clusters and applications.

To deploy Dashboard, execute following command:
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc6/aio/deploy/recommended.yaml
```
To access Dashboard from your local workstation you must create a secure channel to your Kubernetes cluster. Run the following command:
```
$ kubectl proxy
```
Now access Dashboard at:

<http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/>

At this point, you’ll be prompted for a username and password. The username is admin. To get the password at the CLI, type:
```
$ kops get secrets kube --type secret -oplaintext
```
After you log in, you’ll see another prompt. 
![image](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS/blob/master/k8s_dashboard_login.jpg)

Select Token. To get the Token, type:
```
$ kops get secrets admin --type secret -oplaintext
```
After typing in the token, you’ll see the Dashboard!
![image](https://github.com/cy235/Deploy_Dask_Jupyter_K8S_AWS/blob/master/k8s_dashboard.jpg)

#### Delete the Kubernetes Cluster
When you’re ready to tear down your Kubernetes cluster or if you messed up and need to start over, you can delete the cluster with a single command:
```
$ kops delete cluster --name ${KOPS_CLUSTER_NAME} --yes
```
The --yes argument is required to delete the cluster. Otherwise, Kubernetes will perform a dry run without deleting the cluster.

## Deploy ML Model to a Kubernetes Cluster

### Pull the Image from the Repository and Create a Container on the Cluster
The `run_kubernetes.sh` is used to pull the ML model image/container from Docker Hub registry and deploy it into the Kubernetes cluster. You should change your `dockerpath`in `run_kubernetes.sh`, for example my `dockerpath` is 
`index.docker.io/cy235/cy235-prediction:v1`
where `index.docker.io` is the Docker Hub registry server. `cy235-prediction:v1` is the image.

Now we execute
```
sh run_kubernetes.sh
```
then open another terminal, execute 
```
sh run_docker.sh
```
and finally, open another terminal, put a request by executing
```
sh make_prediction.sh
```
you can get the prediction result.

### Use Kubernetes Rolling Updates
Say you’ve updated this application. Do we have to go through this again to update it on the Cluster? Nope.
I’m going to make a few changes and push a new image with a new v2 tag to `index.docker.io/cy235/cy235-prediction:v2`
We can now get K8s to update our application with just one command line
```
 kubectl set image deployment/cy235-prediction  cy235-prediction=index.docker.io/cy235/cy235-prediction:v2
```

### Clean Up Services and Deployments
```
$ kubectl delete svc cy235-prediction 
```
We can find that when you delete a service, another copy of service will be generated automatically, which means the number of pods keep unchanged, this is because of the Kubernetes' mechanism. You can only delete the pod by deleting the deployment as follow
```
$ kubectl delete deployment cy235-prediction
```
Now, the pod `cy235-prediction` and its corresponding service is deleted.
