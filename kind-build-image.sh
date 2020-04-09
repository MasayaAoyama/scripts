#!/bin/bash

cd $(dirname $0)

if [ ! -f /usr/local/bin/kind ]; then
  KIND_VERSION=v0.7.0
  curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-$(uname)-amd64"
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
fi

if [ ! -d ./kubernetes ]; then
  git clone https://github.com/kubernetes/kubernetes.git
fi

if [ ! -f ./old-list ]; then touch ./old-list; fi

cd kubernetes
git add .
git reset --hard
git checkout master
git pull
git tag | sed '/-/!{s/$/_/}' | sort -V | sed 's/_$//' | tail -50 > ../latest-list

for TAG in `cat ../latest-list`; do
  if grep $TAG ../old-list; then
    continue
  fi

  git checkout ${TAG}
  echo building ${TAG} images
  kind build node-image --kube-root ./ --image amsy810/kind-node:${TAG} 2>&1 > /dev/null
  docker image push amsy810/kind-node:${TAG}
  docker rmi amsy810/kind-node:${TAG}
  git add .
  git reset --hard
done

cd -
cp latest-list old-list
