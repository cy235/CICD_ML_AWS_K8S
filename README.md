# Continuously integrating and continuously delivering ML model and deploy it in a Kubernetes cluster in AWS
In this project, we build a **continous integration and continous delivery (CI/CD)** pipeline for ML model, and then delpoy this ML model into a **Kubernetes cluster**. We leverage the CircleCI to continuously test and build the ML model application and deliver the successful application into **Docker Hub registry**. Then we will deploy the ML model image/container from Docker Hub into the Kubernetes cluster in AWS. Another version of building a CI/CD pipeline in AWS Virtual Private Cloud (VPC) for Machine Learning models can be referred to my repo [CICD_ML_AWS](https://github.com/cy235/CICD_ML_AWS/).


## Continuously integrating and continuously delivering ML model into Docker Hub
In this part, we employ the CircleCI for continuously building/testing and continuously delivering the ML model application into Docker Hub registry because CircleCI is free and it runs fast due to its intrinsic caching mechanism. 

First, sign up your CircleCI with github account, then add your project in github to CircleCI, and enter your AWS access ID and secret access ID in `AWS permission`. In the root path of your github project, there should be a file named `config.yml` in a hidden folder named `.circleci`. whenever there is a commit in your project in github, `config.yml` is responsible for building, testing and pushing the successful built ML model into the Docker Hub. 

In the continuous integration part, some test modules such as python source code test as well as docker image test are added, you can refer more details in `config.yml`, where all the steps in the continuous integration are executed in terms of work flow. If the build is successful, move to the next stage to deliver the ML model into the Docker Hub, otherwise, a failure notification will be sent to your email box associated with your github account. You can also refer to more details about the continuous integration in the CircleCI dashboard.

## Deploy ML model into Kubernetes in AWS
In this part, we will deploy the ML model from Docker Hub registry into kubernetes in AWS. How to 
