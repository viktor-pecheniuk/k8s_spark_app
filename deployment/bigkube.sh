#!/bin/bash

function wait() {
    while [ $(kubectl get pods | awk '{print $3}' | tail -n +2 | grep -v Running | wc -l) != 0 ]; do
        sleep 1
    done
}

function serve_jar_directory () {
    docker rm nginx-jar-server -f
    local PARENT_DIR=$(cd ../ && pwd)
    docker run --name nginx-jar-server -v ${PARENT_DIR}/target/scala-2.11:/usr/share/nginx/html:ro -d -p 8080:80 nginx
}

function init_spark_operator() {
    kubectl create clusterrolebinding default --clusterrole=edit --serviceaccount=default:default --namespace=default
    helm init &&
    helm install incubator/sparkoperator --namespace spark-operator --set enableWebhook=true --set rbac.create=false
}

function drop_spark_operator() {
    helm delete $(helm list --namespace=spark-operator --short)
}

function create() {
    kubectl create -f ./mssql.yaml && wait
    kubectl create -f ./zookeeper.yaml && wait
    kubectl create -f ./hdfs.yaml && wait
    kubectl create -f ./kafka.yaml && wait
    kubectl create -f ./metastore.yaml && wait
    kubectl create -f ./presto.yaml && wait
}

function delete() {
    kubectl delete -f minipipe
}

cd "$(dirname "$0")"
while [ $# -gt 0 ]; do
    case "$1" in
        --serve-jar)
            serve_jar_directory
            ;;
        --spark-init)
            init_spark_operator
            ;;
        --spark-drop)
            drop_spark_operator
            ;;
        --create)
            create
            ;;
        --delete)
            delete
            ;;
        -*)
            # do not exit out, just note failure
            echo 1>&2 "unrecognized option: $1"
            ;;
        *)
            break;
            ;;
    esac
    shift
done
